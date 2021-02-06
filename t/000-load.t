#!perl
use 5.014;
use strict;
use warnings;

use Test::More;
use Test::UseAllModules 0.12 under => qw(lib t/lib);

plan tests => Test::UseAllModules::_get_module_list() + 2;

# Tell App::hopen::HopenFileKitit's OK to load
no warnings 'once';
$Test::UseAllModules::IsHopenFile =
  1;    # hard-coded HOPEN_FILE_FLAG --- see below

all_uses_ok();

require App::hopen::AppUtil;
is App::hopen::AppUtil::HOPEN_FILE_FLAG(), 'IsHopenFile',
  'correct HOPEN_FILE_FLAG';

# if this fails, change "IsHopenFile" throughout to match HOPEN_FILE_FLAG.

require App::hopen;
ok($App::hopen::VERSION, 'has a VERSION');
diag("Testing App::Hopen $App::hopen::VERSION, Perl $], $^X");
diag 'App::hopen from ' . $INC{'App/hopen.pm'};
diag 'Data::Hopen from ' . $INC{'Data/Hopen.pm'};

done_testing();
