# Build::Hopen::G::PassthroughOp - A no-op operation
package Build::Hopen::G::PassthroughOp;
use Build::Hopen qw(:default clone);
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::G::Op';
#use Class::Tiny;
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

    my $hrOutputs = $op->run($scope)

The output is C<{}> if no inputs are provided.

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    my $outer_scope = shift or croak 'Need a scope';
    hlog { Running => __PACKAGE__ , $self->name };

    my $saver = $self->scope->outerize($outer_scope);
    return $self->scope->as_hashref(deep => true);
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
