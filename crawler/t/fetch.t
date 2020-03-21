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

my $res = $c->fetch('/testserver/test1');

like($res->{headers}->{'Content-Type'}, qr!text\/html!);
is($res->{url}, '/testserver/test1');

like($res->{body}, qr'<title>Hallo!</title>');

done_testing;
