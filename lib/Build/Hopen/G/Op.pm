# Build::Hopen::G::Op - An individual operation
package Build::Hopen::G::Op;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use parent 'Build::Hopen::G::Node';
use Class::Tiny {
    want => sub { [] },     # Desired inputs
    need => sub { [] },     # Required inputs
};

# Docs {{{1

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

# }}}1

=head1 FUNCTIONS

=head2 run

Run the operation, whatever that means.  Usage:

    my $hrOutputs = $op->run([$hrInputs])

C<$hrOutputs> is guaranteed
to be a new hash, not the same hash as C<$hrInputs>.

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    my $hrInputs = shift || {};
    ...
} #run()

=head2 describe

Return a hashref of C<< {in => (the inputs), out => (the outputs) >>.
Should be implemented in subclasses.  The implementation here returns
C<true> for the inputs, signifying that this op will accept anything.
It returns C<false> for the outputs, signifying that this op has no outputs.

=cut

sub describe {
    my $self = shift or croak 'Need an instance';
    return { in => true, out => false };
        # By default, any inputs; no outputs.
} #describe()

1;
__END__
# vi: set fdm=marker: #
