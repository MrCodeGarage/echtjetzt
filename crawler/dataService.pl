#!/usr/bin/env perl
use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin/lib"
};

use Mojolicious::Lite;
use Mojo::Base -signatures;
use DataService::Clean::Base;
use Mojo::JSON qw'encode_json decode_json';
use MongoDB;
use Mojo::CSV;
use Mojo::Util 'trim';
use Data::Dump qw/dump/;


our $VERSION = 0.01;

# Register cleanup subroutines
our %cleaner = (
  meta  => \&DataService::Clean::Base::get_meta,
  main  => \&DataService::Clean::Base::get_main,
  links => \&DataService::Clean::Base::get_links
);

# Default cleanup cascade
our $default = ['meta', 'main', 'links'];

plugin 'Config';

hook before_server_start => sub ($server, $app) {
  app->init_config;
};

helper init_config => sub ($c) {
  my $app = $c->app;
  # Create in-memory map of credible sources
  # based on the pages to crawl

  $app->config(pageFile => $app->home->child('Data', 'Linkliste_KIvsVirus.csv')->to_string);

  my $pages = $app->config('pages') // [];

  # In addition to the config file (maybe instead)
  # crawl the CSV file with pages to crawl
  if (my $page_file = $app->config('pageFile')) {
    my $data = Mojo::CSV->new->slurp_body($page_file);

    # Add each page to the config
    $data->each(
      sub {
        push @$pages, {
          url => trim($_->[0]),
          title => trim($_->[1]),
          cred => $_->[2],
          crawl => $_->[3],
          freq => ''
        };
      }
    );
  };

  my $credible = $app->config('credible') // {};
  my $recursively = $app->config('recursively') // {};
  foreach (@$pages) {
    my $source = Mojo::URL->new($_->{url})->host;
    # Always take the lowest credibility value,
    # if already set - otherwise set
    if (!exists($credible->{$source})
          || $credible->{$source} > $_->{cred}) {
      $credible->{$source} = $_->{cred};
    }
    $recursively->{$source} = $_->{crawl};
  };

  # Reset list of sources to crawl recursively
  $app->config(recursively => $recursively);


  # Reset list of credible sources
  $app->config(credible => $credible);

  # Add cleaner references
  $app->config(cleaner => \%cleaner);
};


# Create database helper
helper db_client => sub ($c) {
  return undef unless $c->config('db');
  state $db = MongoDB->connect($c->config('db'));
};


# Register crawl command
push @{app->commands->namespaces}, 'DataService';


# Get the credibility score of a source
helper 'get_credibility' => sub ($c, $url) {
  my $source = Mojo::URL->new($url)->host;
  return $c->config('credible')->{$source} // 0.0;
};


# Fetch resource blocking (temporarily)
helper 'fetch' => sub ($c, $url) {

  # Fetch the resource blocking (why not?)
  my $tx = $c->ua->get($url);
  my $res = $tx->result;

  $c->result_to_json($url, $res);
};


# Reformat the result as JSON
helper result_to_json => sub ($c, $url, $res) {
  if ($res->is_success) {
    return {
      header => $res->headers->to_hash,
      body => $res->body,
      url => $url
    };
  }

  # An error occurred
  elsif ($res->is_error) {
    return {
      error => $res->message,
      url => $url
    }
  };

  return {
    error => 'Unknown error',
    url => $url
  };
};

use Encode::Guess qw/ ascii cp1252 iso-8859-1 utf-8 utf-16/;

# Clean resource with several cleaners
helper 'clean' => sub ($c, $cascade, $res) {

  # Initialize cleaned data
  my $enc = guess_encoding($res->{body}); # may return "or"-separated list
  my $body = $res->{body};
  if ($enc =~ /utf-\S+/i) {  # outsmart guess_encoding
    my $new_body = Encode::decode($&, $body);
    if (defined $new_body) {
      $body = $new_body;
    }
  }

  my $data = {
    url => $res->{url},
    base_url => "",
    header => $res->{header},
    html => Mojo::DOM->new($body),
    metadata => {},
    external_links => [],
    internal_links => []
  };

  # Iterate over all cleaners
  foreach (@$cascade) {
    $data = $cleaner{$_}->($data)
  };

  # Strip unimportant data
  $data = DataService::Clean::Base::finish($data);

  # This is a workaround to remove all blessed references
  # to ensure all data can be serialized by BSON
  return decode_json(encode_json($data));
};


# Return the credibility score of a source
get '/credibility' => sub ($c) {
  # TODO:
  #   Validate input
  my $url = $c->param('url');
  $c->render(json => {
    url => $url,
    score => $c->get_credibility($url)
  });
};


# Return the clean data of a url
get '/clean' => sub ($c) {
  # TODO:
  #   Validate input
  # TODO:
  #   Ensure this is an absolute URL
  my $url = $c->param('url');

  # Fetch the data
  my $res = $c->fetch($url);

  # An error occurred
  if ($res->{error}) {
    return $c->render(json => $res)
  };

  return $c->render(
    # TODO:
    #   use base cleaner cascade
    json => $c->clean($default, $res)
  );
};


# Store the clean data of a url
post '/clean/:id' => sub ($c) {
  # TODO:
  #   Validate input
  # TODO:
  #   Ensure this is an absolue URL
  my $url = $c->param('url');

  # Fetch the data
  my $res = $c->fetch($url);

  # An error occurred
  if ($res->{error}) {
    return $c->render(
      status => 400,
      json => $res
    );
  };

  # Clean the data
  my $clean_data = $c->clean($default, $res);

  # Update the job
  my $db = $c->db_client->get_database('ki');
  my $coll = $db->get_collection("jobs");
  my $id = $c->stash('id');
  $res = $coll->update_one({
    _id => $id
  },{
    '$set' => {
      text => $clean_data->{text},
      crawler => $clean_data,
      status => 3
    }
  });

  # Check for update
  if ($res->matched_count == 0) {
    return $c->render(
      status => 400,
      json => {
        error => 'Unable to find job ' . $id
      }
    );
  };

  # return the result
  return $c->render(
    json => $clean_data
  );
};


# Add a new base doc to the list
post '/add' => sub ($c) {

  # TODO:
  #   Validate input
  my $baseurl = $c->param('baseurl');
  my $cred = $c->param('cred');
  my $freq = $c->param('freq');

  # Yada yada
  ...
};

app->start;


__END__

=pod

=head1 NAME

dataService - Data aggregation server

=head1 ENDPOINTS

=over 2

=item B<GET /credibility>

Accepted parameters:

=over 4

=item B<url>

The URL of the resource.

=back

Returns the curated credibility of a resource.

=back

=item B<GET /clean>

Accepted parameters:

=over 4

=item B<url>

The URL of the resource.

=back

Returns the a cleaned object of the resource.

=back

=item B<POST /clean/:id>

Accepted path values:

=over 4

=item B<id>

The identificator of the request.

=back

Accepted parameters:

=over 4

=item B<url>

The URL of the resource.

=back

Returns the a cleaned object of the resource
and stores it in the database.

=back

=head1 COMMANDS

  perl dataService crawl

Crawl all data for the fake news identification.

=cut
