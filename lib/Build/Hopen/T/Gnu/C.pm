# Build::Hopen::T::Gnu::C - support GNU toolset, C language
package Build::Hopen::T::Gnu::C;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

# TODO if a class
use parent 'Build::Hopen::Tool';
use Class::Tiny qw(op);

# Docs {{{1

=head1 NAME

Build::Hopen::T::Gnu::C - support for the GNU toolset, C language

=head1 SYNOPSIS

In a hopen file:

    use language 'C';
    my $op = C->new(op=>'compile', ...);
    $Build->C::compile(...);

=head1 ATTRIBUTES

=head2 op

What this node is going to do: C<compile> or C<link>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 compile

Create a new with L</op> set to C<compile>.

=cut

sub compile {
    my $dag = shift or croak 'Need a DAG';  # TODO write the fluent interface
    my $node = __PACKAGE__->new(op=>'compile');
    $dag->_graph->add_vertex($node);    # TODO FIXME encapsulation violation!!!
    return $node;
} #todo()

=head2 run

Not yet implemented, but doesn't die!

=cut

sub run {
    # TODO
} #run()

=head2 BUILD

Find the C compiler?  Or should that be when the DAG runs?
Maybe toolsets should get the chance to add a node to the beginning of
the graph, before anything else runs.  TODO figure this out.

=cut

sub BUILD {
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
