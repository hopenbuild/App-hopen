#!perl
# t/011-scope-env.t: test Build::Hopen::ScopeENV
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::ScopeENV';
}

my $s = Build::Hopen::ScopeENV->new();
isa_ok($s, 'Build::Hopen::ScopeENV');

$s->add(foo => 42);
cmp_ok($s->find('foo'), '==', 42, 'Retrieving from hash works');

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($s->find($varname), $ENV{$varname}, "Finds env var $varname")
        if exists $ENV{$varname};
}

# TODO test setE, including various ways of leaving the scope (normal, die,
# div by zero, ...).

done_testing();
# vi: set fenc=utf8:
