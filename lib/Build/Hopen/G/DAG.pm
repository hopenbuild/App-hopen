# Build::Hopen::G::DAG - hopen build graph
package Build::Hopen::G::DAG;
use Build::Hopen::Base;
use Build::Hopen;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny {
    goals   => sub { [] },
    default_goal => undef,

    # Private attributes with simple defaults
    _node_by_name => sub { +{} },   # map from node names to nodes in either
                                    # _init_graph or _graph

    # Private attributes - initialized by BUILD()
    _graph  => undef,   # L<Graph> instance
    _final   => undef,  # The graph root - all goals have edges to this

    #Initialization operations
    _init_graph => undef,   # L<Graph> for initializations
    _init_first => undef,   # Graph node for initialization - the first
                            # init operation to be performed.

    # TODO? also support fini to run operations after _graph runs?
};

use Build::Hopen::G::Goal;
use Build::Hopen::G::Link;
use Build::Hopen::G::Node;
use Build::Hopen::G::PassthroughOp;
use Graph;
use Storable ();

# Class data {{{1

use constant {
    LINKS => 'link_list',    # Graph edge attr: array of BHG::Link instances
};

# A counter used for making unique DAG-node names
my $_dag_node_id = 0;

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

=head2 default_goal

The default goal for this DAG.

=head2 _graph

The actual L<Graph>.  If you find that you have to use it, please open an
issue so we can see about providing a documented API for your use case!

=head2 _final

The node to which all goals are connected.

=head2 _init_graph

A separate L<Graph> of operations that will run before all the operations
in L</_graph>.  This is because I don't want to add an edge to every
single node just to force the topological sort to work out.

=head2 _init_first

The first node to be run in _init_graph.

=head1 FUNCTIONS

=cut

# }}}1

=head2 run

Traverses the graph.  The DAG is similar to a subroutine in this respect.
The outputs from all the goals
of the DAG are aggregated and provided as the outputs of the DAG.
The output is a hash keyed by the name of each goal, with each goal's outputs
as the values under that name.  Usage:

    my $hrOutputs = $dag->run($scope)

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    my $outer_scope = shift;    # From the caller
    my $retval = {};

    # The scope attached to the DAG takes precedence over the provided Scope.
    # This is realized by making $outer_scope the outer of our scope for
    # the duration of this call.
    my $dag_scope_saver = $self->scope->outerize($outer_scope);

    # --- Get the initialization ops ---

    my @init_order = eval { $self->_init_graph->toposort };
    die "Initializations contain a cycle!" if $@;

    # --- Get the runtime ops ---

    my @order = eval { $self->_graph->toposort };
        # TODO someday support multi-core-friendly topo-sort, so nodes can run
        # in parallel until they block each other.
    die "Graph contains a cycle!" if $@;

    # Remove _final from the order for now - I don't yet know what it means
    # to traverse _final.
    die "Last item in order isn't _final!"
        unless $order[$#order] == $self->_final;
    pop @order;

    hlog { 'Traversing DAG ' . $self->name };
    my $graph = $self->_init_graph;
    foreach my $node (@init_order, undef, @order) {
        if(!defined($node)) {   # undef is the marker between init and run
            $graph = $self->_graph;
            next;
        }

        # Inputs to this node.  TODO should the provided inputs be given
        # to each node?  Any node with no predecessors?  Currently each
        # node has the option.
        my $node_scope = Build::Hopen::Scope->new;
        $node_scope->outer($self->scope);
            # Data specifically being provided to the current node, e.g.,
            # on input edges, beats the scope of the DAG as a whole.

        # Iterate over each node's edges and process any Links
        foreach my $pred ($graph->predecessors($node)) {
            hlog { ('From', $pred->name, 'to', $node->name) };

            # Goals do not feed outputs to other Goals.  This is so you can
            # add edges between Goals to set their order while keeping the
            # data for each Goal separate.
            # TODO add tests for this
            next if $pred->DOES('Build::Hopen::G::Goal');

            my $links = $graph->get_edge_attribute($pred, $node, LINKS);

            unless($links) {    # Simple case: predecessor's outputs become our inputs
                $node_scope->add(%{$pred->outputs});
                next;
            }

            # More complex case: Process all the links
            my $link_scope = Build::Hopen::Scope->new->add(%{$pred->outputs});
                # All links get the same outer scope --- they are parallel,
                # not in series.
            $link_scope->outer($self->scope);
                # The links run at the same scope level as the node.

            foreach my $link (@$links) {
                hlog { ('From', $pred->name, 'via', $link->name, 'to', $node->name) };
                my $link_outputs = $link->run($link_scope);
                $node_scope->add(%$link_outputs);
                #say 'Link ', $link->name, ' outputs: ', Dumper($link_outputs);   # DEBUG
            } #foreach incoming link
        } #foreach predecessor node

        my $step_output = $node->run($node_scope);
        $node->outputs($step_output);

        #say 'Node ', $node->name, ' outputs: ', Dumper($step_output);   # DEBUG

        # While hacking, please make sure Goal nodes can appear
        # anywhere in the graph.
        $retval->{$node->name} = $step_output
            if $node->DOES('Build::Hopen::G::Goal');
    } #foreach node

    return $retval;
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

The first call to C<goal()> also sets L</default_goal>.

=cut

sub goal {
    my $self = shift or croak 'Need an instance';
    my $name = shift or croak 'Need a goal name';
    my $goal = Build::Hopen::G::Goal->new(name => $name);
    $self->_graph->add_vertex($goal);
    $self->_node_by_name->{$name} = $goal;
    $self->_graph->add_edge($goal, $self->_final);
    $self->default_goal($goal) unless $self->default_goal;
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
   - C<DAG:connect(<op1>, <Link>, <op2>)>: Connects C<< op1 >> to
     C<< op2 >> via L<Build::Hopen::G::Link> C<< Link >>.

Returns the name of the edge?  The edge instance itself?  Maybe a
fluent interface to the DAG for chaining C<connect> calls?

=cut

sub connect {
    my $self = shift or croak 'Need an instance';
    my ($op1, $out_edge, $in_edge, $op2) = @_;

    my $link;
    if(!defined($in_edge)) {    # dependency edge
        $op2 = $out_edge;
        $out_edge = false;      # No outputs
        $in_edge = false;       # No inputs
    } elsif(!defined($op2)) {
        $op2 = $in_edge;
        $link = $out_edge;
        $out_edge = false;      # No outputs TODO
        $in_edge = false;       # No inputs TODO
    }

    # Create the link
    unless($link) {
        $link = Build::Hopen::G::Link->new(
            name => 'link_' . $op1->name . '_' . $op2->name,
            in => [$out_edge],      # Output of op1
            out => [$in_edge],      # Input to op2
        );
    }

    hlog { 'DAG::connect(): Edge from', $op1->name, 'via', $link->name,
            'to', $op2->name };
    # Add it to the graph (idempotent)
    $self->_graph->add_edge($op1, $op2);
    $self->_node_by_name->{$_->name} = $_ foreach ($op1, $op2);

    # Save the BHG::Link as an edge attribute (not idempotent!)
    my $attrs = $self->_graph->get_edge_attribute($op1, $op2, LINKS) || [];
    push @$attrs, $link;
    $self->_graph->set_edge_attribute($op1, $op2, LINKS, $attrs);

    return $link;
} #connect()

=head2 empty

Returns truthy if the only nodes in the graph are internal nodes.
Intended for use by hopen files.

=cut

sub empty {
    my $self = shift or croak 'Need an instance';
    return ($self->_graph->vertices > 1);
        # _final is the node in an empty() graph.
        # We don't check the _init_graph since empty() is intended
        # for use by hopen files, not toolsets.
} #empty()

=head2 init

Add an initialization operation to the graph.  Initialization operations
run before all other operations.  An attempt to add the same initialization
operation twice (based on the node name) will be ignored.  Usage:

    my $op = Build::Hopen::G::Op->new(name=>"whatever");
    $dag->init($op[, $first]);

If C<$first> is truthy, the op will be run before anything already in the
graph.  However, later calls to C<init()> with C<$first> set will push
operations even before C<$op>.

Returns the node, for the sake of chaining.

=cut

sub init {
    my $self = shift or croak 'Need an instance';
    my $op = shift or croak 'Need an op';
    my $first = shift;
    return if $self->_node_by_name->{$op->name};

    $self->_init_graph->add_vertex($op);
    $self->_node_by_name->{$op->name} = $op;

    if($first) {    # $op becomes the new _init_first node
        $self->_init_graph->add_edge($op, $self->_init_first);
        $self->_init_first($op);
    } else {    # Not first, so can happen anytime.  Add it after the
                # current first node.
        $self->_init_graph->add_edge($self->_init_first, $op);
    }

    return $op;
} #init()

=head2 BUILD

Initialize the instance.

=cut

sub BUILD {
    #use Data::Dumper;
    #say Dumper(\@_);
    my $self = shift or croak 'Need an instance';
    # my $hrArgs = shift;

    # Graph of normal operations
    my $graph = Graph->new( directed => true,
                            refvertexed => true);
    my $final = Build::Hopen::G::Node->new(
                                    name => '__R_DAG_ROOT' . $_dag_node_id++);
    $graph->add_vertex($final);
    $self->_graph($graph);
    $self->_final($final);

    # Graph of initialization operations
    my $init_graph = Graph->new( directed => true,
                            refvertexed => true);
    my $init = Build::Hopen::G::PassthroughOp->new(
                                    name => '__R_DAG_INIT' . $_dag_node_id++);
    $init_graph->add_vertex($init);

    $self->_init_graph($init_graph);
    $self->_init_first($init);
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

The following is in flux:

 - C<DAG>: A class representing a DAG.  An instance called C<main> represents
   what will be generated.

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
