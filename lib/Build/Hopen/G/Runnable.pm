# Build::Hopen::G::Runnable - parent class for anything runnable in a hopen graph
package Build::Hopen::G::Runnable;
use Build::Hopen::Base;
use Build::Hopen;

our $VERSION = '0.000008'; # TRIAL

use Build::Hopen::Scope::Hash;
use Build::Hopen::Util::Data qw(forward_opts);
use Build::Hopen::Util::NameSet;
use Build::Hopen::Arrrgs;
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

    scope => sub { Build::Hopen::Scope::Hash->new },
};

=head1 FUNCTIONS

=head2 run

Run the operation, whatever that means.  Returns a new hashref.
Usage:

    my $hrOutputs = $op->run([options])

Options are:

=over

=item -context

A L<Build::Hopen::Scope> or subclass including the inputs the caller wants to
pass to the Runnable.  The L</scope> of the Runnable itself may override
values in the C<context>.

=item -phase

If given, the phase that is currently under way in a build-system run.

=item -generator

If given, the L<Build::Hopen::Gen> instance in use for the current
build-system run.

=item -nocontext

If C<< -nocontext=>1 >> is specified, don't link a context scope into
this one.  May not be specified together with C<-context>.

=back

See the source for this function, which contains as an example of setting the
scope.

=cut

sub run {
    my ($self, %args) = parameters('self', [qw(; context phase generator nocontext)], @_);
    my $context_scope = $args{context};     # which may be undef - that's OK
    croak "Can't combine -context and -nocontext" if $args{context} && $args{nocontext};

    # Link the outer scope to our scope
    my $saver = $args{nocontext} ? undef : $self->scope->outerize($context_scope);

    hlog { ref($self), $self->name, 'input', Dumper($self->scope->as_hashref) } 3;

    my $retval = $self->_run(forward_opts(\%args, {'-'=>1}, qw[phase generator]));

    hlog { ref $self, $self->name, 'output', Dumper($retval) } 3;

    return $retval;
} #run()

=head2 _run

The internal method that implements L</run>.  Must be implemented by
subclasses.  When C<_run> is called, C<< $self->scope >> has been hooked
to the context scope, if any.

Parameters are C<-phase> and C<-generator>.  C<_run> is always called in scalar
context, and must return a new hashref.

=cut

sub _run {
    my ($self, %args) = parameters('self', [qw(; phase generator)], @_);
    ...
}

=head2 passthrough

Returns a new hashref of this Runnable's local values, as defined
by L<Build::Hopen::Scope/local>.  Usage:

    my $hashref = $runnable->passthrough([-context => $outer_scope]);
        # To use $outer_scope as the context
    my $hashref = $runnable->passthrough(-nocontext => 1);
        # To leave the context untouched

Other valid options include L<-levels|Build::Hopen::Scope/$levels>.

=cut

sub passthrough {
    my ($self, %args) = parameters('self', ['*'], @_);
    my $outer_scope = $args{context};     # which may be undef - that's OK
    croak "Can't combine -context and -nocontext" if $args{context} && $args{nocontext};

    # Link the outer scope to our scope
    my $saver = $args{nocontext} ? undef : $self->scope->outerize($outer_scope);

    # Copy the names
    my $levels = $args{levels} // 'local';
    my @names = @{$self->scope->names(-levels=>$levels)};
    my $retval = {};
    $retval->{$_} = $self->scope->find($_, -levels=>$levels) foreach @names;

    return $retval;
} #passthrough()

1;
__END__
# vi: set fdm=marker: #
