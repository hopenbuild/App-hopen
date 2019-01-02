# Build::Hopen::G::PassthroughOp - A no-op operation
package Build::Hopen::G::PassthroughOp;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000002'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny;
use Storable ();

# Docs {{{1

=head1 NAME

Build::Hopen::G::PassthroughOp - a no-op

=head1 SYNOPSIS

An C<PassthroughOp> is a concrete L<Build::Hopen::G::Op> that passes its inputs
to its outputs unchanged.  C<PassthroughOp> instances are currently used by
L<Build::Hopen::G::DAG> to represent goals.

=cut

# }}}1

=head1 FUNCTIONS

=head2 run

Do nothing!  Usage:

    my $hrOutputs = $op->run([$hrInputs])

The output is C<{}> if no inputs are provided.

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    hlog { Running => __PACKAGE__ , $self->name };
    my $hrRetval = {};
    $hrRetval = Storable::dclone($_[0]) if @_ && ref $_[0];
    return $hrRetval;
} #run()

=head2 describe

Return a hashref of C<< {in => (the inputs), out => (the outputs) >>.  The
implementation here returns C<true> for the inputs, signifying that this op
will accept anything.  It returns C<true> for the outputs, signifying that this
op may output anything.

=cut

sub describe {
    my $self = shift or croak 'Need an instance';
    return { in => true, out => true };
        # By default, any inputs; any outputs.
} #describe()

1;
__END__
# vi: set fdm=marker: #
