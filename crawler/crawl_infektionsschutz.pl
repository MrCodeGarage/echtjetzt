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
#  Last Change: 2020-03-21, 22:23:12 (CET)
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

# process a document
sub get_document($url_string, $recursive) {
  my $url = URI->new($url_string);
  my $response = $ua->get($url);
  if ($response->{success}) {
      my $tree = Mojo::DOM -> new($response->{content});
      my $doc = get_main(get_meta({
              url => $url,
              html => $tree,
              recursive => $recursive,
              external_links => [],
              internal_links => [],
              metadata => {},
              header => $response->{headers},
          }));
      $doc = get_links($doc);
  }
}

sub get_meta($params) {
    $params->{metadata}->{title} = $params->{html}->at("title")->all_text();
    return $params;
}

sub get_base($url) {
    return $url->scheme() . "://" . $url->host();
}

sub is_local_link($url_string, $domain, ) {
    my $base = get_base($domain);
    my $rel_url = URI->new($url_string)->rel($base);
    my $url = URI->new($url_string)->abs($base);
    if ($url =~ m/$base/) {
        return $url->as_string;
    }
}

# get links
sub get_links($params) {
    $params->{external_links} = $params->{html}
        ->find("a")->map(attr => "href")->grep(sub{!is_local_link($_, $params->{url})})->compact()->to_array();
    $params->{internal_links} = $params->{html}
        ->find("a")->map(attr => "href")->map(sub{is_local_link($_, $params->{url})})->compact()->to_array();
    return $params;
}

sub normalize_space($text) {
    $text =~ s/\s+/ /gm;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}

# get plain text and simple HTML
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


# heuristically get a main part and remove navigation panels
sub get_main($params) {

    # try to get typical main content:
    my $main = $params->{html}->at('main') //
    $params->{html}->at('div[class=main]') //
    $params->{html}->at('div[class=content]');
    $params->{html} = $main;

    # no navigation, please:
    $main->find("nav")->map(sub{$_->remove});
    $main->find("*[class=nav]")->map(sub{$_->remove});
    $main->find("*[class=navigation]")->map(sub{$_->remove});
    return $params;
}

dump get_document("https://www.infektionsschutz.de/coronavirus/", 0);
