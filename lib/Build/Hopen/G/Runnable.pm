# Build::Hopen::G::Runnable - parent class for anything runnable in a hopen graph
package Build::Hopen::G::Runnable;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use Build::Hopen::Scope;
use Build::Hopen::Util::NameSet;
use Getargs::Mixed;
use Hash::Merge;

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

Run the operation, whatever that means.  B<Must> return a new hashref.
Must be implemented by subclasses.  Usage:

    my $hrOutputs = $op->run([options])

Options are:

=over

=item -scope

A L<Build::Hopen::Scope> or subclass including the inputs the caller wants to
pass to the Runnable.  The Runnable itself should use its own L</scope>,
usually by setting C<< $self->scope->outer($outer_scope) >> within its
C<run()> call.

=item -phase

If given, the phase that is currently under way in a build-system run.

=item -generator

If given, the L<Build::Hopen::Gen> instance in use for the current
build-system run.

=back

See the source for this function, which contains as an example of setting the
scope.

=cut

sub run {
    my ($self, %args) = parameters('self', [qw(; scope phase generator)], @_);
    my $outer_scope = $args{scope};     # which may be undef - that's OK

    # Link the outer scope to our scope
    my $saver = $self->scope->outerize($outer_scope);
    ...     # Subclasses have to do the work.  TODO provide _run_inner for
            # use by subclasses?
} #run()

=head2 passthrough

Returns a new hashref of this Runnable's L<inputs|Build::Hopen::Scope/inputs>.
Usage:

    my $hashref = $runnable->passthrough([-scope => $outer_scope])

=cut

# TODO RESUME HERE - update this to handle $scope->inputs() correctly.
# Maybe just pass the inputs(), not anything else?
sub passthrough {
    my ($self, %args) = parameters('self', [qw(; scope)], @_);
    my $outer_scope = $args{scope};     # which may be undef - that's OK

    # Link the outer scope to our scope
    my $saver = $self->scope->outerize($outer_scope);

    my $merger = Hash::Merge->new('RETAINMENT_PRECEDENT');

    my $retval = {};
    foreach my $input (@{$self->scope->inputs}) {
        $retval = $merger->merge($retval, $input);
    }
    return $retval;
} #passthrough()

1;
__END__
# vi: set fdm=marker: #
