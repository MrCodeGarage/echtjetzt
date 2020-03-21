#!/usr/bin/env perl
use Test::More;
use Mojo::File 'curfile';
use Test::Mojo;

my $script = curfile->dirname->sibling('dataService');

my $app = Test::Mojo->new($script => {
  pages => [
    {
      url => 'https://www.bundesregierung.de/breg-de/themen/coronavirus',
      cred => 0.9,
      freq => ''
    },
    {
      url => 'https://www.bundesregierung.de/privates/cool',
      cred => 0.4,
      freq => ''
    }
  ]
});

$app->get_ok('/credibility?url=http://test.com')
  ->json_is('/score', 0)
  ;

$app->get_ok('/credibility?url=https://www.bundesregierung.de/blog/new')
  ->json_is('/score', 0.4)
  ;

done_testing;
__END__
