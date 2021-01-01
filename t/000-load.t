#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::UseAllModules 0.12 under => qw(lib t/lib);

plan tests => Test::UseAllModules::_get_module_list() + 1;

all_uses_ok();

ok($App::hopen::VERSION, 'has a VERSION');
diag( "Testing App::Hopen $App::Hopen::VERSION, Perl $], $^X" );
diag 'App::hopen from ' . $INC{'App/hopen.pm'};
diag 'Data::Hopen from ' . $INC{'Data/Hopen.pm'};

done_testing();
