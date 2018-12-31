# Build::Hopen::G::DAG - hopen build graph
package Build::Hopen::G::DAG;
use Build::Hopen;
use Build::Hopen::Base;

use Build::Hopen::G::Node;
use Build::Hopen::G::PassthroughOp;

use Graph;

use constant {
    ATTR => 'edge_list',    # Graph edge attribute: list of \BHG::Edge
};

our $VERSION = '0.000001';

use parent 'Build::Hopen::G::Op';

use Class::Tiny {
    goals   => sub { [] },
    default_goal => undef,
    arg     => sub { +{} },

    # Private attributes - initialized by BUILD()
    _graph  => undef,
    _root   => undef
};

# Class data {{{1

# A counter used for making unique DAG root-node names
my $_dag_root_id = 0;

# }}}1
# Docs {{{1

=head1 NAME

Build::Hopen::G::DAG - A hopen build graph

=head1 SYNOPSIS

This class encapsulates the DAG for a particular set of one or more goals.
It is itself a L<Build::Hopen::G::Op> so that it can be composed into
other DAGs.

=head1 VARIABLES

=head2 goals

Arrayref of the goals for this DAG.

=head2 arg

Hashref of the arguments into this DAG.

=head2 _graph

The actual graph.  Provided so you can use it if you want.  However, if you
find that you do have to use it, please open an issue so we can see about
providing a documented API for your use case!

=head1 FUNCTIONS

=cut

# }}}1

=head2 run

Traverses the graph.  The DAG is similar to a subroutine in this respect.
Inputs are copied into L</arg>.  The outputs from all the goals
of the DAG are aggregated and provided as the outputs of the DAG.
The output is a hash keyed by the name of each goal, with each goal's outputs
as the values under that name.  Usage:

    my $hrOutputs = $dag->run($hrInputs)

=cut

sub run ($;$) {
    my $self = shift or croak 'Need an instance';
    my $hrInputs = shift // {};

    my @order = eval { $self->_graph->toposort };
    die "Graph contains a cycle!" if $@;

    say "Traversing DAG $self->name";
    say foreach @order;
} #run()

=head2 goal

Creates a goal of the DAG.  Goals are names for sequences of operations,
akin to top-level Makefile targets.  Usage:

    my $goalOp = $dag->goal('name')

Returns a passthrough operation representing the goal.  Any inputs passed into
that operation are provided as outputs of the DAG under the corresponding name.

     TODO integrate
     A C<hopen> file with no C<main:goal()> calls will result in nothing
     happening when C<hopen> is run.

=cut

sub goal ($$) {
    my $self = shift or croak 'Need an instance';
    my $name = shift or croak 'Need a goal name';
    my $goal = Build::Hopen::G::PassthroughOp->new(name => $name);
    $self->_graph->add_vertex($goal);
    $self->_graph->add_edge($self->_root, $goal);
    return $goal;
} #goal()

=head2 connect

   - C<DAG:connect(<op1>, <out-edge>, <in-edge>, <op2>)>:
     connects output C<< out-edge >> of operation C<< op1 >> as input C<< in-edge >> of
     operation C<< op2 >>.  No processing is done between output and input.
     - C<< out-edge >> and C<< in-edge >> can be anything usable as a table index,
       provided that table index appears in the corresponding operation's
       descriptor.
   - C<DAG:connect(<op1>, <op2>)>: creates a dependency edge from C<< op1 >> to
     C<< op2 >>, indicating that C<< op1 >> must be run before C<< op2 >>.
     Does not transfer any data from C<< op1 >> to C<< op2 >>.


Returns the name of the edge?  The edge instance itself?  Maybe a
fluent interface to the DAG for chaining C<connect> calls?

=cut

sub connect {
    my $self = shift or croak 'Need an instance';
    my ($op1, $out_edge, $in_edge, $op2) = @_;

    if(!defined($in_edge)) {    # dependency edge
        $op2 = $out_edge;
        $out_edge = false;      # No outputs
        $in_edge = false;       # No inputs
    }

    # Create the edge
    my $edge = Build::Hopen::G::Edge->new(
        name => '',             # TODO name it
        in => [$out_edge],      # Output of op1
        out => [$in_edge],      # Input to op2
    );

    # Add it to the graph (idempotent)
    $self->_graph->add_edge($op1, $op2);

    # Save the BHG::Edge as an edge attribute (not idempotent!)
    my $attrs = $self->_graph->get_edge_attribute($op1, $op2, ATTR) || [];
    push @$attrs, $edge;
    $self->_graph->set_edge_attribute($op1, $op2, $attrs);

    return $edge;
} #connect()

=head2 BUILD

Initialize the instance.

=cut

sub BUILD {
    my $self = shift or croak 'Need an instance';

    my $graph = Graph->new( directed => true,
                            refvertexed => true,
                            multiedged => true);
    my $root = Build::Hopen::G::Node->new('_DAG_ROOT' . $_dag_root_id++);
    $graph->add_vertex($root);

    $self->_graph($graph);
    $self->_root($root);

} #BUILD()

1;
# Rest of the docs {{{1
__END__

=head1 IMPLEMENTATION

Each DAG has a hidden "root" node.  All outputs have edges from the root node.
The traversal order is reverse topological from the root node, but is not
constrained beyond that.  Generators can ask for the nodes in root-first or
root-last order.

The DAG is built backwards from the outputs toward the inputs, although calls
to L</output> and L</connect> can appear in any order in the C<hopen> file as
long as everything is hooked in by the end of the file.

 - C<DAG>: A class representing a DAG.  An instance called C<main> represents
   what will be generated.

   - C<DAG.arg> holds any parameters passed from outside the DAG.
   - C<DAG:set_default(<goal>)>: make C<< goal >> the default goal of this DAG
     (default target).
   - C<DAG:inject(<op1>,<op2>[, after/before'])>: Returns an operation that
     lives on the edge between C<op1> and C<op2>.  If the third parameter is
     false, C<'before'>, or omitted, the new operation will be the first
     operation on that edge.  If the third parameter is true or C<'after'>,
     the new operation will be the last operation on that edge.  Any number
     of operations can be injected on any edge.

=cut

# }}}1
# vi: set fdm=marker: #
