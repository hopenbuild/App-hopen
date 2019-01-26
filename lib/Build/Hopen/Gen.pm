# Build::Hopen::Gen - base class for hopen generators
package Build::Hopen::Gen;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use Class::Tiny qw(proj_dir dest_dir), {
    architecture => '',
};

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

A L<Path::Class::Dir> instance specifying the root directory of the project

=head2 dest_dir

A L<Path::Class::Dir> instance specifying where the generated output
should be written.

=head1 FUNCTIONS

A generator (C<Build::Hopen::Gen> subclass) is a Visitor.

B<Note>:
The generator does not have access to L<Build::Hopen::G::Link> instances.
That lack of access is the primary distinction between Ops and Links.

=cut

# }}}1

=head2 visit_goal

Do whatever the generator wants to do with a L<Build::Hopen::G::Goal>.
By default, no-op.

=cut

sub visit_goal { }

=head2 visit_op

Do whatever the generator wants to do with a L<Build::Hopen::G::Op> that
is not a Goal (see L</visit_goal>).  By default, no-op.

=cut

sub visit_op { }

=head2 finalize

Do whatever the generator wants to do to finish up.

=cut

sub finalize { }

=head2 default_toolchain

Returns the package name of the default toolchain for this generator.
Must be implemented by subclasses.

=cut

sub default_toolchain { ... }

=head2 run_build

Runs the build tool for which this generator has created blueprint files.

=cut

sub run_build {
    warn "This generator is not configured to run a build tool.  Sorry!";
}

1;
__END__
# vi: set fdm=marker: #
