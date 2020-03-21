#!/usr/bin/env perl
use Mojolicious::Lite;

# This is a fake server

get '/test1' => sub {
  return shift->render('test1');
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
