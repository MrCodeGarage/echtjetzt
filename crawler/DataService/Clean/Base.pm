package DataService::Clean::Base;

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
use v5.24;
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

# my %DISPATCH = (
#     "www.infektionsschutz.de" => [
#         \&clean_infektionsschutz,
#         \&get_main,
#         \&finish]
# );

# process a document
sub get_document($url_string, $recursive) {
  my $url = URI->new($url_string);
  my $response = $ua->get($url);
  if ($response->{success}) {
      my $tree = Mojo::DOM -> new($response->{content});
      my $doc = get_main(get_meta({
              url => $url,
              html => $tree,
              base_url => "",
              external_links => [],
              internal_links => [],
              metadata => {},
              header => $response->{headers},
          }));
      $doc = get_links($doc);
      $doc = finish($doc);
  }
}

sub get_meta($params) {
    $params->{metadata}->{title} = $params->{html}->at("title")->all_text();

    # if set in HTML file, get //base/@href
    my $base_el = $params->{html}->at("base");
    if (defined $base_el) {
        $params->{base_url} = $base_el->attr("href");
    }
    # if <base> is messy or unset, play with URL
    if ($params->{base_url} eq "") {
        $params->{base_url} = simple_base($params->{url});
    }
    my $base = $params->{base_url};
    say STDERR "BASE_URL: $base";


    return $params;
}

# use to determine base path of URL, independently of <base>
sub simple_base($url) {
    say STDERR "URL: $url";
    $url =~ m{http://.*/};
    return $& // $url;
}

sub get_base_url($params) {
    say STDERR "HERE";
    say STDERR "URL: " . $params->{url};
    return $params;
}

# local link is anything sharing the same base URL
sub is_local_link($url_string, $base) {
    my $rel_url = URI->new($url_string)->rel($base);
    my $url = URI->new($url_string)->abs($base);
    if ($url =~ m/$base/) {
        return $url->as_string;
    }
}

sub is_www_link($url) {
    return ($url =~ m{^https?:}) || ($url !~ m{^[^:]+:})
}

# get links
sub get_links($params) {
    my $link_candidates = $params->{html}->find("a")->map(attr => "href")->compact()->grep(\&is_www_link);
    my $external = $link_candidates->grep(sub{!is_local_link($_, $params->{base_url})})->compact();
    $params->{external_links} = $external->to_array();
    dump $params->{external_links};
    $params->{sources} = $external->map(sub {URI->new($_)->host()});
    $params->{internal_links} = $link_candidates->map(sub{is_local_link($_, $params->{base_url})})->compact()->to_array();
    return $params;
}

sub normalize_space($text) {
    $text =~ s/\s+/ /gm;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}

# get plain text and simple HTML
sub finish($params) {
    my $plain = HTML::Restrict->new();
    my $moderate = HTML::Restrict->new(rules => {
            strong => [],
            em => [],
            main => [],
        }
    );
    $params->{html}->find("script,stylesheet")->each(sub { $_->remove()});

    # normalize <i>/<b>
    $params->{html}->find("i")->each(sub {$_->tag("em")});
    $params->{html}->find("b")->each(sub {$_->tag("strong")});

    # remove empty elements
    $params->{html}->find("*")->each(sub {if ($_->all_text() =~ m/\A\s*\Z/m){ $_->remove()}});

    $params->{text} = normalize_space(
        $plain->process($params->{html}->to_string()));

    my $html_string =  $moderate->process($params->{html}->to_string);
    # $params->{html};
    my $dom = Mojo::DOM->new;
    my $html_dom = $dom->parse("<main></main>");
    $html_dom->content($html_string);
    $params->{html} = $html_dom->to_string();

    return $params;
}


# heuristically get a main part and remove navigation panels
sub get_main($params) {

    # try to get typical main content:
    my $main = $params->{html}->at('main') //
    $params->{html}->at('div[class=main]') //
    $params->{html}->at('div[class=content]') //
    $params->{html};
    $params->{html} = $main;

    # no navigation, please:
    $main->find("nav")->map(sub{$_->remove});
    $main->find("*[class=nav]")->map(sub{$_->remove});
    $main->find("*[class=navigation]")->map(sub{$_->remove});
    return $params;
}

# dump get_document("https://www.infektionsschutz.de/coronavirus/", 0);

1;
