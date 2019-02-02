# Build::Hopen::T::Gnu::C - support GNU toolset, C language
package Build::Hopen::T::Gnu::C;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::Tool';
use Class::Tiny qw(op deps);

use Build::Hopen::G::GraphBuilder;

# Docs {{{1

=head1 NAME

Build::Hopen::T::Gnu::C - support for the GNU toolset, C language

=head1 SYNOPSIS

In a hopen file:

    use language 'C';
    my $op = C->new(op=>'compile', deps=>{hello=>['hello']});
    $Build->C::compile(...)->default_goal;
        # Using a Build::Hopen::G::GraphBuilder

=head1 ATTRIBUTES

=head2 op

What this node is going to do: C<compile> or C<link>.

=head2 deps

Hashref of which files this node will process.  Keys are destination filenames,
without platform-specific suffixes.  Values are strings or arrayrefs of strings
of source file names.  C<.c> is added to any filename not including a period.

=head1 STATIC FUNCTIONS

=cut

# }}}1

=head2 compile

Create a new with L</op> set to C<compile>.  Pass the names of the
source files.  Each source file will be compiled to a respective object
file (TODO make this more flexible).

=cut

sub compile {
    my $builder = shift;
    my $node = __PACKAGE__->new(op=>'compile', deps=>{});
    $node->deps->{$_} = [$_] foreach @_;    # TODO permit more complicated arrangements
    return $builder->add($node);
} #compile()

make_GraphBuilder 'compile';

=head2 link

Create a new with L</op> set to C<link>.  Pass the name of the
executable (TODO make this more flexible).

=cut

sub link {
    my $builder = shift;
    my $exe_name = shift or croak 'Need the name of the executable';
    my $node = __PACKAGE__->new(op=>'link', deps=>{$exe_name=>[]});
    return $builder->add($node);
} #link()

make_GraphBuilder 'link';

=head1 MEMBER FUNCTIONS

=head2 run

Not yet implemented, but doesn't die!

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    hlog { 'Running', __PACKAGE__, 'node', $self->name };
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
