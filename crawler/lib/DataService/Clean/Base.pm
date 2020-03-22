package DataService::Clean::Base;

use strict;
use warnings;
use utf8;
use utf8::all;
use open qw( :encoding(UTF-8) :std );

use List::MoreUtils qw(uniq);

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

use Data::Dump qw/dump/;

# process a document
sub get_document($url_string, $recursive) {
  my $ua = HTTP::Tiny->new();
  my $url = URI->new($url_string);
  my $response = $ua->get($url);
  if ($response->{success}) {
    my $tree = Mojo::DOM ->new($response->{content});
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
sub find_meta_tag($params, $value) {
  $value = "\Q$value";
  $params->{html}->find("meta")->first(sub {
    if (defined $_->attr("http-equiv")) {
      return $_->attr("http-equiv") =~ m/$value/i
    } elsif (defined $_->attr("name")) {
      return $_->attr("name") =~ m/$value/i;
    }
  });
}

sub get_plain_links($text) {
  my @links;
  while ($text =~ m{https?://\S+[^;:,.!?](?=>$|\s)}g) {
    push @links, $&;
  }
  return \@links;
}

sub get_meta($params) {
  my $date = "";
  # determine date
  $date = $params->{header}->{"Last-Modified"};
  if (!defined $date || !$date) {
    my $date_el =
      find_meta_tag($params, "last-modified") //
      find_meta_tag($params, "date");
    if (defined $date_el) {
      $date = $date_el->attr("content");
    }
  }
  $params->{metadata}->{date} = $date // "";

  # dermine title
  my $title_el = $params->{html}->at("title") //
    $params->{html}->at("h1.title,h1.titel,div.title,div.titel");
  my $title = "";
  if (defined $title_el) {
    $title = $title_el->all_text();
  }
  $params->{metadata}->{title} = $title;

  # if set in HTML file, get //base/@href
  my $base_el = $params->{html}->at("base");
  if (defined $base_el) {
    $params->{base_url} = $base_el->attr("href");
  }
  # if <base> is messy or unset, play with URL
  if ($params->{base_url} eq "") {
    $params->{base_url} = simple_base($params->{url});
  }
  return $params;
}

# use to determine base path of URL, independently of <base>
sub simple_base($url) {
  if ($url =~ m{https?://.*/}) {
  return $&
  } else {
    return $url;
  }
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
  return ($url =~ m{^https?:}) || ($url !~ m{^[a-z]++:})
}

# try to exclude non-HTML content.
# TODO: use heuristic on header->{Content-Type} after first get
sub is_licit_link($url) {
  $url =~ s/\?.*$//g;
  $url =~ s{^https?://}{};
  $url =~ s{^[^/]*?(?:/|$)}{};
  my $ret = ($url eq "") || ($url =~ m{(?:^|/)[^.]*$|(?:html?|php|cgi|pl)$});
  # say STDERR "CHECK: $url => $ret";
  return $ret
}

# get links
sub get_links($params) {
  my $link_candidates = $params->{html}
  ->find("a")->map(attr => "href")->compact()
  ->grep(\&is_www_link)
  ->map(sub{s/\#.*$//g; return $_})
  ->grep(\&is_licit_link)
  ->map(sub {
    return URI->new($_)->abs($params->{base_url})->as_string();
    });
  my $external = $link_candidates
    ->grep(sub{!is_local_link($_, $params->{base_url})})->compact();
  $params->{external_links} = $external->to_array();
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

my $moderate_rules = {
      strong => [],
      em => [],
      h1 => [],
      h2 => [],
      h3 => [],
      h4 => [],
    };
my $plain = HTML::Restrict->new();
my $moderate = HTML::Restrict->new(rules => $moderate_rules);

# get plain text and simple HTML
sub finish($params) {
  $params->{sources} = [ uniq @{$params->{sources}} ];
  $params->{internal_links} = [ uniq @{$params->{internal_links}} ];
  $params->{external_links} = [ uniq @{$params->{external_links}} ];
  $params->{html}->find("script,stylesheet")->each(sub { $_->remove()});

  # normalize <i>/<b>
  $params->{html}->find("i")->each(sub {$_->tag("em")});
  $params->{html}->find("b")->each(sub {$_->tag("strong")});
  $params->{html}->find("b")->each(sub {$_->tag("strong")});
  # make sure word boundaries are respected
  $params->{html}->find("li,p,div,td,th,h1,h2,h3,h4,h5,h6,br,hr")->each(
    sub {
      $_->append_content(" ")
    });
  # remove empty elements
  $params->{html}->find("*")->each(sub {
      my $me = $_;
      if ($me->all_text() =~ m/\A\s*\Z/m){
        $me->remove()
      }});
  $params->{text} = normalize_space(
    $plain->process($params->{html}->to_string()));

  my $html_string =  $moderate->process($params->{html}->to_string);
  # $params->{html};
  my $dom = Mojo::DOM->new;
  my $html_dom = $dom->parse("<main></main>");
  $html_dom->at("main")->content($html_string);
  $params->{html} = normalize_space($html_dom->to_string());

  return $params;
}

sub remove_if_has($parent, $child_selector) {
  my $child = $parent->at($child_selector);
  if (defined $child) {
    $child->remove();
  }
}

# heuristically get a main part and remove navigation panels
sub get_main($params) {

  # try to get typical main content:
  my $main =
  $params->{html}->at('*[class=~"content-area"]') //
  $params->{html}->at('*[class=~"o-content--main"]') //
  # rapefugees
  $params->{html}->at('#content') //
  $params->{html}->at('#entry-content') //
  $params->{html}->at('article') //
  $params->{html}->at('main') //
  $params->{html}->at('div[class=~main]') //
  $params->{html}->at('div[class=~entry-content]') //
  $params->{html};
  $params->{html} = $main;

  my $to_remove = Mojo::Collection->new(
    # tagesschau.de
    "div.metablockwrapper",
    # blauerbote.com
    "#comments",
    # smopo.ch
    "#comment-form-wrap",
    ".adsense_single",
    # http://www.rapefugees.net/
    "addtoany_content", " addtoany_content_bottom",
    # blog.halle-leaks.net
    ".shariff",

    );

  $to_remove->each(sub{remove_if_has($main, $_);});

  # no navigation, please:
  $main->find("nav,footer,*[class=nav],*[class=navigation]")
  ->map(sub{$_->remove});
  return $params;
}

# dump get_document("https://www.infektionsschutz.de/coronavirus/", 0);

# vim: sw=2

1;
