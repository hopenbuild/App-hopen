#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Build::Hopen' ) || print "Bail out!\n";
}

diag( "Testing Build::Hopen $Build::Hopen::VERSION, Perl $], $^X" );
