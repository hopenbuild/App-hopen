#!perl
# t/011-scope-env.t: test Build::Hopen::ScopeENV
use rlib 'lib';
use HopenTest;
use Build::Hopen::Scope;

BEGIN {
    use_ok 'Build::Hopen::ScopeENV';
}

my $s = Build::Hopen::ScopeENV->new();
isa_ok($s, 'Build::Hopen::ScopeENV');
ok($s->DOES('Build::Hopen::Scope'), 'ScopeENV DOES Scope');

$s->add(foo_hopen => 42);
cmp_ok($ENV{foo_hopen}, '==', 42, 'add() updates %ENV');
cmp_ok($s->find('foo_hopen'), '==', 42, 'Retrieving previously-set variable works');

foreach my $varname (qw(SHELL COMSPEC PATH)) {
    is($s->find($varname), $ENV{$varname}, "Finds existing env var $varname")
        if exists $ENV{$varname};
}

# Some constants for variable names
our ($varname_inner, $varname_outer, $varname_env);
local *varname_inner = \'+;!@#$%^&*() Some crazy variable name that is not a valid env var name';
local *varname_outer = \'+;!@#$%^&*() Another crazy variable name that is not a valid env var name';
local *varname_env = \'__env_var_for_testing_hopen_';

my $inner = Build::Hopen::Scope->new()->add($varname_inner => 42);
my $outer = Build::Hopen::Scope->new()->add($varname_outer => 1337);

$inner->outer($s);
$s->outer($outer);

cmp_ok($inner->find($varname_outer), '==', 1337, 'find() through intervening ScopeENV works');
cmp_ok($s->find($varname_outer), '==', 1337, 'find() from ScopeENV to outer works');

$ENV{$varname_env} = 'C=128';

ok($s->names->has($varname_env), '$ENV{}-set var is in scope');
ok($inner->names->has($varname_env), '$ENV{}-set var is in scope starting from inner');
ok(!$outer->names->has($varname_env), '$ENV{}-set var is not in scope in outer');
is($inner->find($varname_env), 'C=128', 'find() from inner up to ScopeENV works');

done_testing();
# vi: set fenc=utf8:
