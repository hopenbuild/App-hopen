#!perl
# 006-passthrough-op.t: test Build::Hopen::G::PassthroughOp
use rlib 'lib';
use HopenTest;
use Scalar::Util qw(refaddr);

use Build::Hopen::Scope;

BEGIN {
    use_ok 'Build::Hopen::G::PassthroughOp';
}

my $e = Build::Hopen::G::PassthroughOp->new(name=>'foo');
isa_ok($e, 'Build::Hopen::G::PassthroughOp');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

is_deeply($e->run(-scope => Build::Hopen::Scope->new), {}, 'run() returns {} when inputs are empty');
eval { $e->run(); };
ok($@, "Empty input is prohibited");

my $hr = Build::Hopen::Scope->new;
$hr->inputs([{foo=>1, bar=>2, baz=>{quux=>1337}, quuux=>[1,2,3,[42,43,44]]}]);
my $newhr = $e->run(-scope => $hr);
    # TODO RESUME HERE - figure this one out.  I think DAG::run() may need to
    # import its inputs from the outer scope.
diag Dumper $newhr;
is_deeply($newhr, $hr->inputs->[0], 'run() clones its inputs');
cmp_ok(refaddr($hr), '!=', refaddr($newhr), 'run() returns a clone, not its input');

done_testing();
