use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION_FROM => 'dataService',
  ABSTRACT => 'Data aggregation server',
  PREREQ_PM => {
    'Mojolicious' => '8.34',
    'HTTP::Tiny' => '0.076',
    'HTML::Restrict' => '3.0.0',
    'Mojo::CSV' => '1.001004'
  },
  MIN_PERL_VERSION => 5.020000,
  test      => {TESTS => 't/*.t'}
);
