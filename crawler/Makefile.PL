use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM => 'dataService',
  NAME => 'dataService',
  ABSTRACT => 'Data aggregation server',
  PREREQ_PM => {
    'Mojolicious' => '8.34',
    'HTTP::Tiny' => '0.076',
    'HTML::Restrict' => '3.0.0',
    'Mojo::CSV' => '1.001004',
    'WWW::Crawler::Mojo' => '0.25',
    'utf8::all' => '0.024',
    'MongoDB' => '2.2.1'
  },
  MIN_PERL_VERSION => 5.024000,
  test      => {TESTS => 't/*.t'}
);
