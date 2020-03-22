use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw!path curfile!;

my $script = curfile->dirname->sibling('dataService');

my $mount_point = '';

# Mount fake server
my $mock = path(Mojo::File->new(__FILE__)->dirname, 'mock')->child('server.pl');

my $t = Test::Mojo->new($script);

my $mock_mount = $t->app->plugin(
  Mount => {
    '/testserver/' => $mock
  }
);

# Configure fake backend
# my $mock_backend_app = $mock_mount->pattern->defaults->{app};

my $c = $t->app->build_controller;

my $res = $c->fetch('/testserver/test/1');

like($res->{header}->{'Content-Type'}, qr!text\/html!);
is($res->{url}, '/testserver/test/1');

like($res->{body}, qr'<title>Hallo!</title>');


$t->get_ok('/clean?url=/testserver/test/1')
  ->status_is(200)
  ->json_is('/external_links/0', undef)
  ->json_like('/header/Content-Type', qr!^text\/html!)
  ->json_is('/text', 'Hallo! Dies ist der erste Paragraph! '.
              'Dies ist der zweite Paragraph!')
  ->json_is('/metadata/title', 'Hallo!')
  ->json_is('/sources/0', undef)
  ;


done_testing;
