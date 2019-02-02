# Build::Hopen::T::Gnu::C - support GNU toolset, C language
package Build::Hopen::T::Gnu::C;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::Tool';
use Class::Tiny qw(op deps);

use Build::Hopen::G::GraphBuilder;
use Build::Hopen::Util::Data qw(forward_opts);
use Getargs::Mixed;

# Docs {{{1

=head1 NAME

Build::Hopen::T::Gnu::C - support for the GNU toolset, C language

=head1 SYNOPSIS

In a hopen file:

    use language 'C';
    my $op = C->new(op=>'compile', deps=>{hello=>['hello']});
        # Create instances manually

    # Or use via Build::Hopen::G::GraphBuilder:
    $Build->C::compile(...)->default_goal;

=head1 ATTRIBUTES

=head2 op

What this node is going to do: C<compile> or C<link>.

=head2 deps

Hashref of which files this node will process.  Keys are destination filenames,
without platform-specific suffixes.  Values are strings or arrayrefs of strings
of source file names.  C<.c> is added to any filename not including a period.

=cut

# }}}1

=head1 STATIC FUNCTIONS

Arguments to the static functions are parsed using L<Getargs::Mixed>.
Therefore, named arguments start with a hyphen (e.g., C<< -name=>'foo' >>,
not C<< name=>'foo' >>).

=head2 compile

Create a new with L</op> set to C<compile>.  Pass the names of the
source files.  Each source file will be compiled to a respective object
file (TODO make this more flexible).  Usage:

    use language 'C';
    $builder_or_dag->C::compile('file1'[, 'file2'...][, -name=>'node name');

=cut

sub compile {
    my ($builder, %args) = parameters('self', [qw(first; name *)], @_);
    my $node = __PACKAGE__->new(op=>'compile', deps=>{});
    $node->name($args{name}) if $args{name};

    croak "I need at least one filename to compile" unless $args{first};
    $node->deps->{$_} = [$_] foreach ($args{first} // (), $args{'*'} // ());
        # TODO permit more complicated arrangements

    hlog { __PACKAGE__, 'Built compile node',Dumper($node) } 2;
    return $node;   # The builder will automatically add it
} #compile()

make_GraphBuilder 'compile';

=head2 link

Create a new with L</op> set to C<link>.  Pass the name of the
executable.  Usage:

    use language 'C';
    $builder_or_dag->C::link('file1'[, 'file2'...][, -name=>'node name');

=cut

sub link {
    my ($builder, %args) = parameters('self', [qw(exe; name)], @_);
    croak 'Need the name of the executable' unless $args{exe};
    my $node = __PACKAGE__->new(op=>'link', deps=>{$args{exe}=>[]});
    $node->name($args{name}) if $args{name};
    hlog { __PACKAGE__, 'Built link node',Dumper($node) } 2;
    return $node;
} #link()

make_GraphBuilder 'link';

=head1 MEMBER FUNCTIONS

=head2 run

Not yet implemented, but doesn't die!

=cut

sub run {
    my ($self, %args) = parameters('self', [qw(phase scope; generator *)], @_);
    hlog { 'Running', __PACKAGE__, 'node', $self->name };

    # Currently we only do things at gen time.
    return $self->passthrough(-scope=>$args{scope}) if $args{phase} ne 'Gen';

    +{} # Required
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
