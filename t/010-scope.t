#!perl
# t/010-scope.t: test Build::Hopen::Scope
use rlib 'lib';
use HopenTest;
#use Test::Deep;

sub makeset {
    my $set = Set::Scalar->new;
    $set->insert(@_);
    return $set;
}

BEGIN {
    use_ok 'Build::Hopen::Scope';
}

my $s = Build::Hopen::Scope->new();
isa_ok($s, 'Build::Hopen::Scope');

$s->add(foo => 42);
cmp_ok($s->find('foo'), '==', 42, 'Retrieving from hash works');

ok($s->names->is_equal(makeset('foo')), 'names works with a non-nested scope');

my $t = Build::Hopen::Scope->new()->add(bar => 1337);
$t->outer($s);
ok($t->names->is_equal(makeset(qw(foo bar))), 'names works with a nested scope');

my $u = Build::Hopen::Scope->new()->add(quux => 128);
$u->outer($t);
ok($u->names->is_equal(makeset(qw(foo bar quux))), 'names works with a doubly-nested scope');



# TODO test setE, including various ways of leaving the scope (normal, die,
# div by zero, ...).

done_testing();
# vi: set fenc=utf8:
