package DataService::crawl;
use Mojo::Base 'Mojolicious::Command';
use WWW::Crawler::Mojo;

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => 'Crawl sources for fake news identification';
has usage       => sub { shift->extract_usage };

sub run {
  my $self = shift;

  # Get the application
  my $app = $self->app;
  my $log = $app->log;

  $app->init_config;

  my $credible_hash = $app->config('credible');

  my $spider = WWW::Crawler::Mojo->new;

  # Initialize crawler
  $spider->on(
    start => sub {
      shift->say_start;
    }
  );

  # Temporary!
  use HTML::Restrict;
  my $plain = HTML::Restrict->new;

  # On receiving a page
  $spider->on(
    res => sub {
      my ($spider, $scrape, $job, $res) = @_;

      say sprintf('fetching %s resulted status %s', $job->url, $res->code);

      my $data = $app->clean([
        sub {
          my $d = shift;
          $d->{plain} = $plain->process($d->{body});
          return $d;
        }], $app->result_to_json($job->url, $res));

      use Data::Dumper;
      print Dumper $data;
      exit;

      foreach my $job ($scrape->()) {

        # Check if the job is a known host
        my $credible = $job->url->host;
        if (exists $credible_hash->{$credible}) {
          $spider->enqueue($job);
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

  $spider->enqueue('https://www.infektionsschutz.de/coronavirus/');
  $spider->crawl;
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
