#!perl
# t/012-scope-nested.t: test nested Build::Hopen::Scope instances
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::Scope';
    use_ok 'Build::Hopen::ScopeENV';
}

my $s = Build::Hopen::Scope->new();
isa_ok($s, 'Build::Hopen::Scope');
my $t = Build::Hopen::Scope->new();
isa_ok($t, 'Build::Hopen::Scope');
my $scope_env = Build::Hopen::ScopeENV->new();
isa_ok($scope_env, 'Build::Hopen::ScopeENV');

$t->outer($scope_env);
$s->outer($t);

$s->add(foo => 42);
cmp_ok($s->find('foo'), '==', 42, 'Retrieving from hash works');

$t->add(bar => 1337);
cmp_ok($t->find('bar'), '==', 1337, 'Retrieving from hash works');
cmp_ok($s->find('bar'), '==', 1337, 'Retrieving from hash through outer works');
ok(!defined($t->find('foo')), "Inner doesn't leak into outer");

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($s->find($varname), $ENV{$varname}, "Finds env var $varname through double chain")
        if exists $ENV{$varname};
    is($t->find($varname), $ENV{$varname}, "Finds env var $varname through single chain")
        if exists $ENV{$varname};
    is($scope_env->find($varname), $ENV{$varname}, "Finds env var $varname directly")
        if exists $ENV{$varname};
}

done_testing();
# vi: set fenc=utf8:
