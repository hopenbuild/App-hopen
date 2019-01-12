#!perl
# t/021-dag-single-goal.t: basic tests of Build::Hopen::G::DAG with one goal
use rlib 'lib';
use HopenTest;
use Test::Deep;

use Build::Hopen;
use Build::Hopen::Scope;
use Build::Hopen::ScopeENV;
use Build::Hopen::G::Link;

$Build::Hopen::VERBOSE = true;

sub run {
    my $outermost_scope = Build::Hopen::Scope->new()->add(foo => 42);

    my $dag = hnew DAG => 'dag';

    # Add a goal
    my $goal = $dag->goal('all');
    is($goal->name, 'all', 'DAG::goal() sets goal name');
    ok($dag->_graph->has_edge($goal, $dag->_final), 'DAG::goal() adds goal->final edge');

    # Add an op
    my $link = hnew Link => 'link1', greedy => 1;
    my $op = hnew PassthroughOp => 'op1';
    isa_ok($op,'Build::Hopen::G::PassthroughOp');
    $dag->connect($op, $link, $goal);
    ok($dag->_graph->has_edge($op, $goal), 'DAG::connect() adds edge');

    # Run it
    #print Dumper($outermost_scope);
    my $dag_out = $dag->run($outermost_scope);
    #print Dumper($dag_out);
    #print Dumper($op->outputs);

    cmp_deeply($dag_out, {all => { foo=>42 } }, "DAG passes everything through, tagged with the goal's name");
}

run();

done_testing();
