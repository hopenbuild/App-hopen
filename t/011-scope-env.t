#!perl
# t/011-scope-env.t: test Build::Hopen::ScopeENV
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::ScopeENV';
}

my $s = Build::Hopen::ScopeENV->new();
isa_ok($s, 'Build::Hopen::ScopeENV');
ok($s->DOES('Build::Hopen::Scope'), 'ScopeENV DOES Scope');

$s->add(foo => 42);
cmp_ok($ENV{foo}, '==', 42, 'add() updates %ENV');
cmp_ok($s->find('foo'), '==', 42, 'Retrieving previously-set variable works');

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($s->find($varname), $ENV{$varname}, "Finds existing env var $varname")
        if exists $ENV{$varname};
}

# TODO add tests of ScopeENV as an outer, ScopeENV with an outer, and both.

done_testing();
# vi: set fenc=utf8:
