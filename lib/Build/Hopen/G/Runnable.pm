# Build::Hopen::G::Runnable - parent class for anything runnable in a hopen graph
package Build::Hopen::G::Runnable;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use Build::Hopen::Scope;
use Build::Hopen::Util::NameSet;

# Docs {{{1

=head1 NAME

Build::Hopen::G::Runnable - parent class for runnable things in a hopen graph

=head1 SYNOPSIS

Anything with L</run> inherits from this.  TODO should this be a role?

=head1 ATTRIBUTES

=head2 need

Inputs this Runnable requires.
A L<Build::Hopen::Util::NameSet>, with the restriction that C<need> may not
contain regexes.  ("Sorry, I can't run unless you give me every variable
in the world that starts with Q."  I don't think so!)

=head2 scope

If defined, a L<Build::Hopen::Scope> that will have the final say on the
data used by L</run>.  This is the basis of the fine-grained override
mechanism in hopen.

=head2 want

Inputs this Runnable accepts but does not require.
A L<Build::Hopen::Util::NameSet>, which may include regexes.

=cut

# }}}1

use parent 'Build::Hopen::G::Entity';
use Class::Tiny {
    # NOTE: want and need are not currently used.
    want => sub { Build::Hopen::Util::NameSet->new },
    need => sub { Build::Hopen::Util::NameSet->new },

    scope => sub { Build::Hopen::Scope->new },
};

=head1 FUNCTIONS

=head2 run

Run the operation, whatever that means.  Usage:

    my $hrOutputs = $op->run([$outer_scope])

C<$hrOutputs> is guaranteed to be a new hash, not the same hash as C<$hrInputs>.

The C<$outer_scope> should include the inputs the caller wants to pass to the
Runnable.  The Runnable itself should use its own L</scope>, usually by setting
C<< $self->scope->outer($outer_scope) >> for the duration of the C<run()> call.

=cut

sub run {
    my $self = shift or croak 'Need an instance';
    my $outer_scope = shift // Build::Hopen::Scope->new;
    ...
} #run()

1;
__END__
# vi: set fdm=marker: #
