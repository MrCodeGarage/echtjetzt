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
#  Last Change: 2020-03-21, 17:50:37 (CET)
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
use HTTP::Tiny;
use HTML::Restrict;
my $ua = HTTP::Tiny->new();


my %DISPATCH = (
    "www.infektionsschutz.de" => [
        \&clean_infektionsschutz,
        \&get_main,
        \&strip]
);


sub get_text($url) {
  my $response = $ua->get($url);
  if ($response->{success}) {
      my $tree = Mojo::DOM -> new($response->{content});
      clean_infektionsschutz({
              html => $tree,
              recursive => 1,
              links => [],
              metadata => [],
              header => $response->{headers},
          });
  }
}

sub strip($params) {
    my $plain = HTML::Restrict->new();
    my $moderate = HTML::Restrict-> new([
            rules => [
                strong => [],
                em => [],
            ]
        ]);
    $params->html->find("i")->each(sub{ $_->tag("em")});
    $params->{plain} = $plain->process($params->{html});
    $params->{html} = $moderate->process($params->{html});
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

sub clean_infektionsschutz($params) {

    
}

__END__



