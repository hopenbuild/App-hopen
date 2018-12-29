# Build::Hopen::G::DAG - hopen build graph
package Build::Hopen::G::DAG;
use Build::Hopen;
use Build::Hopen::Base;

use Graph;

our $VERSION = '0.000001';

use parent 'Build::Hopen::G::Op';

use Class::Tiny {
    goals => sub { [] },
    arg => sub { +{} },
    graph => sub { Graph->new() },
};

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

=head2 graph

The actual graph.  Provided so you can use it if you want.  However, if you
find that you do have to use it, please open an issue so we can see about
providing a documented API for your use case!

=head1 FUNCTIONS

=head2 run

Traverses the L</graph>.  The DAG is similar to a subroutine in this respect.
Inputs are copied into L</arg>.  The outputs from all the goals
of the DAG are aggregated and provided as the outputs of the DAG.
The output is a hash keyed by the name of each goal, with each goal's outputs
as the values under that name.

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    ...
} #run()

#1;
__END__

=head1 IMPLEMENTATION

Each DAG has a hidden "root" node.  All outputs have edges from the root node.
The traversal order is reverse topological from the root node,
but is not constrained
beyond that.  Generators can ask for the nodes in root-first or root-last
order.

The DAG is built backwards from the outputs toward the inputs,
although calls to C<output> and C<connect> can appear in any order in the C<hopen>
file as long as everything is hooked in by the end of the file.

 - C<DAG>: A class representing a DAG.  An instance called C<main> represents
   what will be generated.

   - C<DAG.arg> holds any parameters passed from outside the DAG.
   - C<DAG:goal(<name>)>: creates a goal of the DAG.  Goals are names
     for sequences of operations, akin to top-level Makefile targets.
     A C<hopen> file with no C<main:goal()> calls will result in nothing
     happening when C<hopen> is run.
     Returns an instance that can be used as if it were an operation.
     Any inputs passed into that instance are provided as outputs of the DAG.
   - C<DAG:set_default(<goal>)>: make C<< goal >> the default goal of this DAG
     (default target).
   - C<DAG:connect(<op1>, <out-edge>, <in-edge>, <op2>)>:
     connects output C<< out-edge >> of operation C<< op1 >> as input C<< in-edge >> of
     operation C<< op2 >>.  No processing is done between output and input.
     - C<< out-edge >> and C<< in-edge >> can be anything usable as a table index,
       provided that table index appears in the corresponding operation's
       descriptor.
     - returns the name of the edge?  Maybe a fluent interface?
   - C<DAG:connect(<op1>, <op2>)>: creates a dependency edge from C<< op1 >> to
     C<< op2 >>, indicating that C<< op1 >> must be run before C<< op2 >>.
     Does not transfer any data from C<< op1 >> to C<< op2 >>.
   - C<DAG:inject(<op1>,<op2>[, after/before'])>: Returns an operation that
     lives on the edge between C<op1> and C<op2>.  If the third parameter is
     false, C<'before'>, or omitted, the new operation will be the first
     operation on that edge.  If the third parameter is true or C<'after'>,
     the new operation will be the last operation on that edge.  Any number
     of operations can be injected on any edge.

=cut

# vi: set fdm=marker: #
