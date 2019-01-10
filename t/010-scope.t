#!perl
# t/010-scope.t: test Build::Hopen::Scope
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::Scope';
}

my $s = Build::Hopen::Scope->new();
isa_ok($s, 'Build::Hopen::Scope');

$s->add(foo => 42);
cmp_ok($s->find('foo'), '==', 42, 'Retrieving from hash works');

# TODO test setE, including various ways of leaving the scope (normal, die,
# div by zero, ...).

done_testing();
# vi: set fenc=utf8:
