# Build::Hopen::G::Goal - A named build goal
package Build::Hopen::G::Goal;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny qw(_passthrough);

# Docs {{{1

=head1 NAME

Build::Hopen::G::Goal - a named goal in a hopen build

=head1 SYNOPSIS

A C<Goal> is a named build target, e.g., C<doc> or C<dist>.  The name C<all>
is reserved for the root goal.

=head1 FUNCTIONS

=head2 run

Wraps a L<Build::Hopen::G::PassthroughOp>'s run function.

=cut

# }}}1

sub run {
    my $self = shift or croak 'Need an instance';
    return $self->_passthrough->run(@_);
}

=head2 BUILD

=cut

sub BUILD {
    my ($self, $args) = @_;
    croak 'Goals must have names' unless $args->{name};
    # TODO refactor out the common code between Goal and PassthroughOp
    # rather than wrapping.
    my $p = hnew(PassthroughOp => ($args->{name} . '_inner'));
    $self->_passthrough($p);
    $self->want($p->want);
    $self->need($p->need);
} #BUILD()


1;
__END__
# vi: set fdm=marker: #
