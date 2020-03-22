package DataService::crawl;
use Mojo::ByteStream 'b';
use Mojo::Base 'Mojolicious::Command';
use Mojo::JSON 'encode_json';

use Data::Dump qw/dump/;

use WWW::Crawler::Mojo;

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => 'Crawl sources for fake news identification';
has usage       => sub { shift->extract_usage };


# TEMP
sub store {
  my ($self, $fh, $data) = @_;
  my $json = encode_json($data);
  $json =~ s/\n+/ /g;
  say $fh $json;
};


# Run the crawler
sub run {
  my $self = shift;

  # Get the application
  my $app = $self->app;
  my $log = $app->log;

  # Initialize the configuration,
  # which normally happens on server start
  $app->init_config;

  my $cleaner = $app->config('cleaner');
  my $credible_hash = $app->config('credible');
  my $recursively = $app->config('recursively');
  my $spider = WWW::Crawler::Mojo->new;

  # Store as http://jsonlines.org/
  my $file = $self->app->home->child('Data', 'testcrawl.jsonl');
  my $fh = $file->open('>');
  $fh->binmode(":utf-8");

  # Initialize crawler
  $spider->on(
    start => sub {
      shift->say_start;
    }
  );

  # On receiving a page
  $spider->on(
    res => sub {
      my ($spider, $scrape, $job, $res) = @_;

      say sprintf('fetching %s resulted status %s', $job->url, $res->code);

      # Get json representation of the resource
      my $json = $app->result_to_json($job->url->to_string, $res);

      # Clean the data
      my $data = $app->clean(['meta','main', 'links'], $json);
      my $credible = Mojo::URL->new($job->url)->host;
      $data->{cred} = $credible_hash->{$credible} // 0;

      # Store the data
      $self->store($fh, $data);

      # Parse internal and external links
      foreach my $link (@{$data->{internal_links}}, @{$data->{external_links}}) {
        # Check if the job is a known host
        my $credible = Mojo::URL->new($link)->host;

        # TODO:
        #   Credible may decide between www. and not
        if (exists $credible_hash->{$credible}
          && $recursively->{$credible} // 0) {

          $spider->enqueue($link);
        };
      };
    }
  );

  $spider->on(
    error => sub {
      my ($msg, $job) = @_;
      say $msg;
      say "Re-scheduled";
      $spider->requeue($job);
    }
  );

  # Get all pages and crawl
  my $pages = $app->config('pages') // [];
  foreach (@$pages) {
    $spider->enqueue($_->{url})
  };

  # Start crawling
  $spider->crawl;

  $fh->close;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

DataService::Command::crawl - Crawl sources for fake news identification


=head1 SYNOPSIS

  usage: perl dataService crawl

=cut
