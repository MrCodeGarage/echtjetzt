#!/usr/bin/env perl
use Mojolicious::Lite;

# This is a fake server

get '/test/:nr' => sub {
  my $c = shift;
  return $c->render('test' . $c->stash('nr'));
};

app->start;

__DATA__

@@ test1.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Hallo!</title>
  </head>
  <body>
    <p>Dies ist der erste Paragraph!</p>
    <p>Dies ist der zweite Paragraph!</p>
  </body>
</html>

@@ test2.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Hallo!</title>
  </head>
  <body>
    <main>
      <p>Dies ist der erste Paragraph!</p>
      <p>Dies ist der zweite Paragraph!</p>
    </main>
  </body>
</html>
