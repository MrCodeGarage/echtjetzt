#!/usr/bin/env perl
#===============================================================================
#
#         FILE: crawl_infektionsschutz.pl
#
#        USAGE: ./crawl_infektionsschutz.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Bernhard Fisseni (bfi), fisseni@ids-mannheim.de
# ORGANIZATION: Leibniz-Institut für Deutsche Sprache
#      VERSION: 1.0
#      CREATED: 2020-03-21, 17:03:33 (CET)
#     REVISION: ---
#  Last Change: 2020-03-21, 20:20:50 (CET)
#===============================================================================

use strict;
use warnings;
use utf8;
use utf8::all;
# use open qw( :encoding(UTF-8) :std );

# binmode(STDIN,":utf8");
# binmode(STDERR,":utf8");
# binmode(STDOUT,":utf8");
# only if DATA is used:
# binmode(DATA, ":encoding(UTF-8)");

# use charnames qw( :full :short );
use v5.20;
use feature qw(say state switch unicode_strings signatures);
no warnings qw(experimental::signatures);
use re "/u";
use autodie;
use URI;
use HTTP::Tiny;
use HTML::Restrict;
use Mojo::DOM;
my $ua = HTTP::Tiny->new();

use Data::Dump qw/dump/;

my %DISPATCH = (
    "www.infektionsschutz.de" => [
        \&clean_infektionsschutz,
        \&get_main,
        \&strip]
);


sub get_document($url_string, $recursive) {
  my $url = URI->new($url_string);
  my $response = $ua->get($url);
  if ($response->{success}) {
      my $tree = Mojo::DOM -> new($response->{content});
      my $doc = get_main({
              url => $url,
              html => $tree,
              recursive => $recursive,
              links => [],
              metadata => [],
              header => $response->{headers},
          });
      $doc = get_links($doc);
      dump($doc->{links});
  }
}
sub is_local_link($url_string, $domain) {
    my $base = $domain->scheme() . "://" . $domain->host();
    my $rel_url = URI->new($url_string)->rel($base);
    my $url = URI->new($url_string)->abs($base);
    return ($url =~ m/$base/) && ($rel_url !~ m{^/+$});
}

sub get_links($params) {
    $params->{links} = $params->{html}
        ->find("a")->map(attr => "href")->grep(sub{is_local_link($_, $params->{url})})->compact()->to_array();
    return $params;
}

sub strip($params) {
    my $plain = HTML::Restrict->new();
    my $moderate = HTML::Restrict-> new([
            rules => [
                strong => [],
                em => [],
            ]
        ]);
    $params->html->find("i")->each(sub{ $_->tag("em")});
    $params->{html} = $plain->process($params->{html}->to_string());
    $params->{html} = $moderate->process($params->{html}->to_string());
    return $params;
}


# heuristically get a main part
sub get_main($params) {
    my $main = $params->{html}->at('main') //
    $params->{html}->at('div[class=main]') //
    $params->{html}->at('div[class=content]');
    $params->{html} = $main;
    return $params;
}

get_document("https://www.infektionsschutz.de/coronavirus/", 0);
