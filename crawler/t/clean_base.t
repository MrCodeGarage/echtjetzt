use strict;
use warnings;
use Test::More;
use Mojo::DOM;
use_ok('DataService::Clean::Base');

my $dom = Mojo::DOM->new(<<HTML);
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv='last-modified' content='Sat, 21 Mar 2020 11:55:00 CET'>
    <title>Example</title>
  </head>
  <body>
    <main>
      <p>Ich bin <strong>Inhalt</strong>!</p>
      <p>Dies führt <a href="/weiter/2">intern</a> und dies führt <a href="http://external.example.com">extern</a> weiter.</p>
      <nav>
        <ul>
          <li>a</li>
          <li>b</li>
        </ul>
      </nav>
    </main>
  </body>
</html>
HTML

# Get meta
my $obj = DataService::Clean::Base::get_meta({
  url => 'http://example.com',
  base_url => "",
  date => "",
  html => $dom,
  external_links => [],
  internal_links => [],
  metadata => {},
  header => {},
});

is_deeply([], $obj->{internal_links});
is_deeply([], $obj->{external_links});
is_deeply({
    date => 'Sat, 21 Mar 2020 11:55:00 CET',
    title => 'Example'
  },
  $obj->{metadata});
is_deeply({}, $obj->{header});
is_deeply('http://example.com', $obj->{url});
ok(!$obj->{text});
like($obj->{html}->to_string, qr'^<!DOCTYPE html>');


# Get main
$obj = DataService::Clean::Base::get_main($obj);
is_deeply([], $obj->{internal_links});
is_deeply([], $obj->{external_links});
is_deeply({
    date => 'Sat, 21 Mar 2020 11:55:00 CET',
    title => 'Example'
  },
  $obj->{metadata});
is_deeply({}, $obj->{header});
ok(!$obj->{text});
is_deeply('http://example.com', $obj->{url});
like($obj->{html}->to_string, qr!^<main>!);
unlike($obj->{html}->to_string, qr!<nav>!);


# Get links
$obj = DataService::Clean::Base::get_links($obj);
is_deeply(['http://example.com/weiter/2'], $obj->{internal_links});
is_deeply(['http://external.example.com'], $obj->{external_links});
is_deeply({
    date => 'Sat, 21 Mar 2020 11:55:00 CET',
    title => 'Example'
  },
  $obj->{metadata});
is_deeply({}, $obj->{header});
ok(!$obj->{text});
is_deeply('http://example.com', $obj->{url});
like($obj->{html}->to_string, qr!^<main>!);
unlike($obj->{html}->to_string, qr!<nav>!);


# Finish
$obj = DataService::Clean::Base::finish($obj);
is_deeply(['http://example.com/weiter/2'], $obj->{internal_links});
is_deeply(['http://external.example.com'], $obj->{external_links});
is_deeply({
    date => 'Sat, 21 Mar 2020 11:55:00 CET',
    title => 'Example'
  },
  $obj->{metadata});
is_deeply({}, $obj->{header});
is($obj->{text}, 'Ich bin Inhalt! Dies führt intern und dies führt extern weiter.');
is_deeply('http://example.com', $obj->{url});
like($obj->{html}, qr!^<main>!);
unlike($obj->{html}, qr!<nav>!);
is_deeply($obj->{sources}, ['external.example.com']);

done_testing;
__END__
