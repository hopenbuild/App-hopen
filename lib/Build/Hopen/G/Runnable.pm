# Build::Hopen::G::Runnable - parent class for anything runnable in a hopen graph
package Build::Hopen::G::Runnable;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use Build::Hopen::Util::NameSet;

# Docs {{{1

=head1 NAME

Build::Hopen::G::Runnable - parent class for runnable things in a hopen graph

=head1 SYNOPSIS

Anything with L</run> inherits from this.  TODO should this be a role?

=head1 ATTRIBUTES

=head2 want

Inputs this Runnable accepts but does not require.

=cut

#A L<Build::Hopen::Util::NameSet> ?

=head2 need

Inputs this Runnable requires.

=cut

# }}}1

use parent 'Build::Hopen::G::Entity';
use Class::Tiny {
    want => sub { Build::Hopen::Util::NameSet->new },
    need => sub { Build::Hopen::Util::NameSet->new },
};

=head1 FUNCTIONS

=head2 run

Run the operation, whatever that means.  Usage:

    my $hrOutputs = $op->run([$hrInputs])

C<$hrOutputs> is guaranteed to be a new hash, not the same hash as C<$hrInputs>.

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    my $hrInputs = shift || {};
    ...
} #run()

1;
__END__
# vi: set fdm=marker: #
