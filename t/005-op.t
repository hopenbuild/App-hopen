#!perl
# 005-op.t: test Build::Hopen::G::Op
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::G::Op';
}

my $e = Build::Hopen::G::Op->new(name=>'foo');
isa_ok($e, 'Build::Hopen::G::Op');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

done_testing();
