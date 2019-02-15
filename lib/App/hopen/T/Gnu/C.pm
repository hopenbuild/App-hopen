# App::hopen::T::Gnu::C - support GNU toolset, C language
# TODO RESUME HERE - put .o files in the dest dir
package App::hopen::T::Gnu::C;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000009'; # TRIAL

use parent 'App::hopen::Tool';
use Class::Tiny qw(op files _cc);

use App::hopen::BuildSystemGlobals;   # For $DestDir.
    # TODO make the dirs available to nodes through the context.
use Config;
use Data::Hopen qw(getparameters);
use Data::Hopen::G::GraphBuilder;
use Data::Hopen::Util::Data qw(forward_opts);
use Data::Hopen::Util::Filename;
use Deep::Hash::Utils qw(deepvalue);
use File::Which ();
use Path::Class;

my $FN = Data::Hopen::Util::Filename->new;     # for brevity
our $_CC;   # Cached compiler name

# Docs {{{1

=head1 NAME

Data::Hopen::T::Gnu::C - support for the GNU toolset, C language

=head1 SYNOPSIS

In a hopen file:

    use language 'C';
    my $op = C->new(op=>'compile');
        # Create instances manually

    # Or use via Data::Hopen::G::GraphBuilder:
    $Build->H::files(...)->C::compile->default_goal;

The inputs come from earlier in the build graph.
TODO support specifying compiler arguments.

=head1 ATTRIBUTES

=head2 op

What this node is going to do: C<compile> or C<link>.

=head2 files

Arrayref of which files this node will process.  Values are
destination file names.  Extensions may be added.

=cut

# }}}1

=head1 STATIC FUNCTIONS

Arguments to the static functions are parsed using L<Getargs::Mixed>
(via L<Data::Hopen/getparameters>).
Therefore, named arguments start with a hyphen (e.g., C<< -name=>'foo' >>,
not C<< name=>'foo' >>).

=head2 compile

Create a new with L</op> set to C<compile>.  Inputs come from the build graph,
so parameters other than C<-name> are disregarded (TODO permit specifying
compilation options or object-file names).  Usage:

    use language 'C';
    $builder_or_dag->H::files('file1.c')->C::compile([-name=>'node name']);

=cut

sub compile {
    my ($builder, %args) = getparameters('self', [qw(; name)], @_);
    my $node = __PACKAGE__->new(op=>'compile',
        forward_opts(\%args, 'name')
    );

    hlog { __PACKAGE__, 'Built compile node', Dumper($node) } 2;
    return $node;   # The builder will automatically add it
} #compile()

make_GraphBuilder 'compile';

=head2 link

Create a new with L</op> set to C<link>.  Pass the name of the
executable.  Usage:

    use language 'C';
    $builder_or_dag->C::link('file1'[, -name=>'node name');

=cut

sub link {
    my ($builder, %args) = getparameters('self', [qw(exe; name)], @_);
    croak 'Need the name of the executable' unless $args{exe};

    my $node = __PACKAGE__->new(
        op=>'link', files => [$DestDir->file($FN->exe($args{exe}))->absolute],
        forward_opts(\%args, 'name')
    );
    hlog { __PACKAGE__, 'Built link node', Dumper($node) } 2;
    return $node;
} #link()

make_GraphBuilder 'link';

=head1 MEMBER FUNCTIONS

=head2 _run

Create the compile or link command lines.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(phase ; generator *)], @_);

    # Currently we only do things at gen time.
    return $self->passthrough(-nocontext=>1) if $args{phase} ne 'Gen';

    # Find the work up to this point
    my $hrOldWork =
        $self->scope->find(-name => 'work', -set => '*', -levels => 'local') // {};

    if($self->op eq 'compile' && scalar keys %$hrOldWork != 1) {
        die "C::compile nodes can only take one input at present";
        # TODO relax this requirement
    }
    my $lrOldWork = %$hrOldWork{(keys %$hrOldWork)[0]};  # list of hashrefs

    hlog { 'found old work', Dumper($lrOldWork) } 2;
    my ($lrFrom, @work);

    $lrFrom = deepvalue($lrOldWork, qw(0 to)) // [];     # don't autovivify
    if($self->op eq 'compile' && $#$lrFrom != 0) {
        die "C::compile nodes can only take one input filename at present";
        # TODO relax this requirement
    }

    # Add the new work
    foreach my $file (@{$lrFrom}) {
        my $hr = { from => [ $file ] };
        $hr->{to} = [ $self->op eq 'compile' ?
            $FN->obj($file) :
            $self->files->[0] ];
        $hr->{how} = $self->op eq 'compile' ?
            $self->_cc . " -c #first -o #out" :
            $self->_cc . " #first -o #out";
        push @work, $hr;
        $lrFrom = [$file];
    }

    # Add the existing work at the end
    push @work, @$lrOldWork if @$lrOldWork;

    return { work => \@work };
} #run()

=head2 BUILD

Find the C compiler.

TODO should this happen when the DAG runs?
Maybe toolsets should get the chance to add a node to the beginning of
the graph, before anything else runs.  TODO figure this out.

=cut

sub BUILD {
    my ($self, $args) = @_;

    if($_CC) {      # Use the cached one if we already found it
        $self->_cc($_CC);
        return;
    }

    # Look for the compiler
    foreach my $candidate ($Config{cc}, qw[cc gcc clang]) {      # TODO also c89 or xlc?
        my $path = File::Which::which($candidate);
        next unless defined $path;

        hlog { __PACKAGE__, 'using C compiler', $path };    # Got it
        $self->_cc($path);
        $_CC = $path;
        last;
    }
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
