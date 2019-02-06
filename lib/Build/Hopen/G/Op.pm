# Build::Hopen::G::Op - An individual operation
package Build::Hopen::G::Op;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000006'; # TRIAL

use parent 'Build::Hopen::G::Node';
use Class::Tiny;

=head1 NAME

Build::Hopen::G::Op - a hopen operation

=head1 SYNOPSIS

An C<Op> represents one step in the build process.  C<Op>s exist to provide
a place for edges (L<Build::Hopen::G::Edge>) to connect to.

=head1 MEMBERS

=head2 need

An arrayref of inputs that must be present for L</run> to succeed.

=head2 want

An arrayref of inputs that L</run> would like to have, but does not require.

=cut

1;
__END__
# vi: set fdm=marker: #
