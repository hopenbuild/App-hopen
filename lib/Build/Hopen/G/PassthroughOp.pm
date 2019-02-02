# Build::Hopen::G::PassthroughOp - A no-op operation
package Build::Hopen::G::PassthroughOp;
use Build::Hopen qw(:default UNSPECIFIED);
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::G::Op';
#use Class::Tiny;

use Build::Hopen::Util::Data qw(clone);
use Getargs::Mixed;
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

    my $hrOutputs = $op->run(-scope=>$scope)

The output is C<{}> if no inputs are provided.

=cut

sub run {
    my ($self, %args) = parameters('self', [qw(scope; phase generator)], @_);
    hlog { Running => __PACKAGE__ , $self->name };
    return $self->passthrough(-scope => $args{scope});
} #run()

=head2 BUILD

Constructor

=cut

sub BUILD {
    my $self = shift;
    $self->want(UNSPECIFIED);   # we'll take anything
}

1;
__END__
# vi: set fdm=marker: #
