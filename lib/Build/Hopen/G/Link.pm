# Build::Hopen::G::Link - base class for hopen edges
package Build::Hopen::G::Link;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use parent 'Build::Hopen::G::Entity';
use Class::Tiny {
    ops => sub { [] },
    in => sub { [] },
    out => sub { [] },
};

=head1 NAME

Build::Hopen::G::Link - The base class for all hopen links between ops.

=head1 VARIABLES

=head2 ops

An arrayref of the operations to be performed while data traverses that
edge.  Operations are performed in order of increasing array index.

=head2 in

An arrayref of inputs to this edge.  (??)

=head2 out

An arrayref of outputs from this edge.  (??)

=head1 FUNCTIONS

=head2 run

Do something!  Usage:

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

1;
__END__
# vi: set fdm=marker: #
