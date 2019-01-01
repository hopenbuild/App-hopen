#!perl
# 003-node.t: test Build::Hopen::G::Node
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::G::Node';
}

my $e = Build::Hopen::G::Node->new(name=>'foo');
isa_ok($e, 'Build::Hopen::G::Node');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

done_testing();
