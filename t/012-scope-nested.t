#!perl
# t/012-scope-nested.t: test nested Build::Hopen::Scope instances
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Build::Hopen::Scope';
    use_ok 'Build::Hopen::ScopeENV';
}

my $innermost = Build::Hopen::Scope->new();
isa_ok($innermost, 'Build::Hopen::Scope');
my $middle = Build::Hopen::Scope->new();
isa_ok($middle, 'Build::Hopen::Scope');
my $scope_env = Build::Hopen::ScopeENV->new();
isa_ok($scope_env, 'Build::Hopen::ScopeENV');

$middle->outer($scope_env);
$innermost->outer($middle);

use constant CRAZY_NAME => "==|>  something wacky  \x{00a2} <|==";
    # equals signs and lowercase => not a valid Windows env var name
    # pipe/gt/lt => not a POSIX env var name you would create without
    #   serious effort
    # U+00A2: not in the POSIX Portable Character Set (references at
    #   https://stackoverflow.com/a/2821183/2877364)

$innermost->add(CRAZY_NAME, 42);
cmp_ok($innermost->find(CRAZY_NAME), '==', 42, 'Retrieving from hash works');

$middle->add(bar => 1337);
cmp_ok($middle->find('bar'), '==', 1337, 'Retrieving from hash works');
cmp_ok($innermost->find('bar'), '==', 1337, 'Retrieving from hash through outer works');
ok(!defined($middle->find(CRAZY_NAME)), "Inner doesn't leak into outer");

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($innermost->find($varname), $ENV{$varname}, "Finds env var $varname through double chain")
        if exists $ENV{$varname};
    is($middle->find($varname), $ENV{$varname}, "Finds env var $varname through single chain")
        if exists $ENV{$varname};
    is($scope_env->find($varname), $ENV{$varname}, "Finds env var $varname directly")
        if exists $ENV{$varname};
}

done_testing();
# vi: set fenc=utf8:
