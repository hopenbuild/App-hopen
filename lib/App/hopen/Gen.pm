# Build::Hopen::Gen - base class for hopen generators
package Build::Hopen::Gen;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000009'; # TRIAL

use Class::Tiny qw(proj_dir dest_dir), {
    architecture => '',
};

use Path::Class ();

# Docs {{{1

=head1 NAME

Build::Hopen::Gen - Base class for hopen generators

=head1 SYNOPSIS

The code that generates blueprints for specific build systems
lives under C<Build::Hopen::Gen>.  L<Build::Hopen::Phase::Gen> calls modules
under C<Build::Hopen::Gen> to create the blueprints.  Those modules must
implement the interface defined here.

=head1 ATTRIBUTES

=head2 proj_dir

(Required) A L<Path::Class::Dir> instance specifying the root directory of
the project.

=head2 dest_dir

(Required) A L<Path::Class::Dir> instance specifying where the generated output
(e.g., blueprint or other files) should be written.

=head1 FUNCTIONS

A generator (C<Build::Hopen::Gen> subclass) is a Visitor.

B<Note>:
The generator does not have access to L<Build::Hopen::G::Link> instances.
That lack of access is the primary distinction between Ops and Links.

=cut

# }}}1

=head2 visit_goal

Do whatever the generator wants to do with a L<Build::Hopen::G::Goal>.
For example, the generator may change the goal's C<outputs>.
By default, no-op.  Usage:

    $generator->visit_goal($goal);

=cut

sub visit_goal { }

=head2 visit_node

Do whatever the generator wants to do with a L<Build::Hopen::G::Node> that
is not a Goal (see L</visit_goal>).  By default, no-op.  Usage:

    $generator->visit_node($node)

=cut

sub visit_node { }

=head2 finalize

Do whatever the generator wants to do to finish up.  By default, no-op.
Is provided the L<Build::Hopen::G::DAG> instance as a parameter.  Usage:

    $generator->finalize(-phase=>$Phase, -graph=>$dag)

=cut

sub finalize { }

=head2 default_toolset

Returns the package stem of the default toolset for this generator.
Must be implemented by subclasses.

When a hopen file invokes C<use language "Foo">, hopen will load
C<< Build::Hopen::T::<stem>::Foo >>, where C<< <stem> >> is the return
value of this function.

As a sanity check, hopen will first try to load C<< Build::Hopen::T::<stem> >>,
so make sure that is a valid package.

=cut

sub default_toolset { ... }

=head2 also_require

Returns the names of the packages, if any, that should be loaded along with
this generator.

=cut

sub also_require { }

=head2 run_build

Runs the build tool for which this generator has created blueprint files.

=cut

sub run_build {
    warn "This generator is not configured to run a build tool.  Sorry!";
}

=head2 BUILD

Enforces the required arguments.

=cut

sub BUILD {
    my ($self, $args) = @_;
    croak "Need a project directory (Path::Class::Dir)"
        unless eval { $self->proj_dir->DOES('Path::Class::Dir') };
    croak "Need a destination directory (Path::Class::Dir)"
        unless eval { $self->dest_dir->DOES('Path::Class::Dir') };
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
