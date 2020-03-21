use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {'Mojolicious' => '8.34',
                "HTML::Restricted", '3.0.0'},
  test      => {TESTS => 't/*.t'}
);
