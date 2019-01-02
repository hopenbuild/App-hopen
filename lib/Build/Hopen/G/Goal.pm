# Build::Hopen::G::Goal - A named build goal
package Build::Hopen::G::Goal;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000002'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny {
    _passthrough => sub { hnew PassthroughOp => ($_[0]->name . '_inner') },
};

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

# TODO?  Override the setter so that name 'all' throws?

=head2 describe

Wraps a L<Build::Hopen::G::PassthroughOp>'s describe function.

=cut

sub describe {
    my $self = shift or croak 'Need an instance';
    return $self->_passthrough->describe(@_);
}

1;
__END__
# vi: set fdm=marker: #
