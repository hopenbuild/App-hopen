# Build::Hopen::G::CollectOp - pull values from scope(s)
package Build::Hopen::G::CollectOp;
use Build::Hopen qw(:default UNSPECIFIED);
use Build::Hopen::Base;

our $VERSION = '0.000007'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny {
    levels => 'local',
};

use Build::Hopen::Util::Data qw(clone forward_opts);
use Build::Hopen::Arrrgs;
use Storable ();

# Docs {{{1

=head1 NAME

Build::Hopen::G::CollectOp - a no-op

=head1 SYNOPSIS

An C<CollectOp> is a concrete L<Build::Hopen::G::Op> that passes its inputs, or
other values drawn from its scope, to its outputs unchanged.  For example,
C<CollectOp> instances are used by L<Build::Hopen::G::DAG> to represent goals.

=head1 ATTRIBUTES

=head2 levels

Which levels of L<Build::Hopen::Scope> to pull from, as defined by
L<Build::Hopen::Scope/$levels>.  Default is C<'local'>, i.e., to and including
the first Scope encountered that has L<local|Build::Hopen::Scope/local> set.

=cut

# }}}1

=head1 FUNCTIONS

=head2 _run

Copy the inputs to the outputs.  Usage:

    my $hrOutputs = $op->run([-context=>$scope])

The output is C<{}> if no inputs are provided.
See L<Build::Hopen::G::Runnable/passthrough> for more details.

=cut

sub _run {
    my ($self, %args) = parameters('self', [qw(*)], @_);
    hlog { Running => __PACKAGE__ , $self->name };
    return $self->passthrough(-nocontext => 1, -levels => $self->levels);
        # -nocontext because Runnable::run() already hooked in the context
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
