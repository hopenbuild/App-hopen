#!perl
# 004-goal.t: test Build::Hopen::G::Goal
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::G::Goal';
}

my $e = Build::Hopen::G::Goal->new(name=>'foo');
isa_ok($e, 'Build::Hopen::G::Goal');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

done_testing();
