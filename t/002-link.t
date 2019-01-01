#!perl
# 002-link.t: test Build::Hopen::G::Link
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::G::Link';
}

my $e = Build::Hopen::G::Link->new(name=>'foo');
isa_ok($e, 'Build::Hopen::G::Link');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

is_deeply($e->ops, [], 'Ops start out empty');
is_deeply($e->in, [], 'Inputs start out empty');
is_deeply($e->ops, [], 'Outputs start out empty');

done_testing();
