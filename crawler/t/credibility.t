use Mojo::Base -strict;
use Mojo::File 'curfile';
use Test::More;
use Test::Mojo;

my $script = curfile->dirname->sibling('dataService.pl');

my $t = Test::Mojo->new($script => {
  pages => [
    {
      url => 'https://www.bundesregierung2.de/breg-de/themen/coronavirus',
      cred => 0.9,
      freq => ''
    },
    {
      url => 'https://www.bundesregierung2.de/privates/cool',
      cred => 0.4,
      freq => ''
    }
  ]
});

$t->get_ok('/credibility?url=http://test.com')
  ->json_is('/score', 0)
  ;

$t->get_ok('/credibility?url=https://www.bundesregierung2.de/blog/new')
  ->json_is('/score', 0.4)
  ;

done_testing;
__END__
