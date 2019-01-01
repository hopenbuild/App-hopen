#!perl
# 001-entity.t: test Entity
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::G::Entity';
}

my $e = Build::Hopen::G::Entity->new(name=>'foo');
isa_ok($e, 'Build::Hopen::G::Entity');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

done_testing();
