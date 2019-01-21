# Build::Hopen::Toolchain - base class for hopen toolchains
package Build::Hopen::Toolchain;
use Build::Hopen;
use Build::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000005'; # TRIAL

use Class::Tiny qw(proj_dir dest_dir), {
    architecture => '',
};

# Docs {{{1

=head1 NAME

Build::Hopen::Toolchain - Base class for hopen toolchains

=head1 SYNOPSIS

The code that generates command lines to invoke specific toolchains lives under
C<Build::Hopen::Toolchain>.  Those modules must implement the interface defined
here.

=head1 ATTRIBUTES

=head2 proj_dir

A L<Path::Class::Dir> instance specifying the root directory of the project

=head2 dest_dir

A L<Path::Class::Dir> instance specifying where the generated output
should be written.

=head1 FUNCTIONS

A toolchain (C<Build::Hopen::Toolchain> subclass) is a Visitor.

TODO Figure out if the toolchain has access to L<Build::Hopen::G::Link>
instances.

=cut

# }}}1

=head2 visit_goal

Do whatever the toolchain wants to do with a L<Build::Hopen::G::Goal>.
By default, no-op.

=cut

sub visit_goal { }

=head2 visit_op

Do whatever the toolchain wants to do with a L<Build::Hopen::G::Op> that
is not a Goal (see L</visit_goal>).  By default, no-op.

=cut

sub visit_op { }

=head2 finalize

Do whatever the toolchain wants to do to finish up.

=cut

sub finalize { }

1;
__END__
# vi: set fdm=marker: #
