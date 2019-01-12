# Build::Hopen::Scope - a nested key-value store
package Build::Hopen::Scope;
use Build::Hopen qw(clone);
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use Set::Scalar;

use Class::Tiny {
    outer => undef,
    _content => sub { +{} },
    name => 'anonymous scope',
};

# Docs {{{1

=head1 NAME

Build::Hopen::Scope - a hierarchical name table

=head1 SYNOPSIS

A Scope represents a set of data available to operations.  It is a
key-value store that falls back to an outer C<Scope> if a requested key
isn't found.

This particular Scope is a concrete implementation using a hash under the
hood.  However, the public API is limited to L</outer>, L</add>, and L</find>
(plus C<new> from L<Class::Tiny>).  Subclasses may use different
representations.

=head1 ATTRIBUTES

=head2 outer

The fallback C<Scope> for looking up names not found in this C<Scope>.
If non is provided, it is C<undef>, and no fallback will happen.

=head2 name

Not used, but provided so you can use L<Build::Hopen/hnew> to make Scopes.

=head1 METHODS

See also L</add>, below, which is part of the public API.

=cut

# }}}1

=head2 find

Find a named data item in the scope and return it.  Looks up the scope chain
to the outermost scope if necessary.  Returns undef on
failure.  Usage: C<< $scope->find($name) >>.
Dies if given a falsy name, notably, C<'0'>.

=cut

sub find {
    my $self = shift or croak 'Need an instance';
    my $name = shift or croak 'Need a name';
        # Therefore, '0' is not a valid name

    my $here = $self->_find_here($name);
    return $here if defined $here;

    return $self->outer->find($name) if $self->outer;

    return undef;   # report failure
} #find()

=head2 names

Returns a L<Set::Scalar> of the names of the items available through this
Scope, optionally including all its parent Scopes (if any).  Usage
and example:

    my $set = $scope->names([$levels]);
    say "Name $_ is available" foreach @$set;   # Set::Scalar supports @$set

If C<$levels> is provided and nonzero, go up that many more levels
(i.e., C<$levels==0> means only return this scope's local names).
If C<$levels> is not provided, go all the way to the outermost Scope.

=cut

sub names {
    my ($self, $levels) = @_;
    my $retval = Set::Scalar->new;
    $self->_fill_names($retval, $levels);
    return $retval;
} #names()

# Implementation of names()
sub _fill_names {
    my ($self, $retval, $levels) = @_;

    $self->_names_here($retval);    # Insert this scope's names

    if($self->outer &&              # Insert the outer scopes' names
        (!defined($levels) || ($levels>0))
    ) {
        my $newlevels = defined($levels) ? ($levels-1) : undef;
        $self->outer->_fill_names($retval, $newlevels);
    }
} #_fill_names()

=head2 as_hashref

Returns a hash of the items available through this Scope, optionally
including all its parent Scopes (if any).  Usage:

    my $hashref = $scope->as_hashref([levels => $levels][, deep => $deep])

If C<$levels> is provided and nonzero, go up that many more levels
(i.e., C<$levels==0> means only return this scope's local names).
If C<$levels> is not provided, go all the way to the outermost Scope.

If C<$deep> is provided and truthy, make a deep copy of each value (using
L<Build::Hopen/clone>.  Otherwise, just copy.

=cut

sub as_hashref {
    my $self = shift;
    my %opts = @_;
    my $hrRetval = {};
    $self->_fill_hashref($hrRetval, $opts{deep}, $opts{levels});
    return $hrRetval;
} #as_hashref()

# Implementation of as_hashref.  Mutates the provided $hrRetval.
sub _fill_hashref {
    my ($self, $hrRetval, $deep, $levels) = @_;

    # Innermost wins, so copy ours first.
    foreach my $k (keys %{$self->_content}) {
        unless(exists($hrRetval->{$k})) {   # An inner scope might have set it
            $hrRetval->{$k} =
                ($deep ? clone($self->_content->{$k}) : $self->_content->{$k});
        }
    }

    # Then move out in scope
    if($self->outer &&
        (!defined($levels) || ($levels>0))
    ) {
        my $newlevels = defined($levels) ? ($levels-1) : undef;
        $self->outer->_fill_hashref($hrRetval, $deep, $newlevels);
    }
} #_fill_hashref()

=head2 TODO_execute

Run a L<Build::Hopen::G::Runnable> given a set of inputs.  Fills in the inputs
from the scope if possible.  Usage:

    $scope->TODO_execute($runnable[, {inputs...})

=cut

# TODO Move out of this module
sub TODO_execute {
    my $self = shift;
    my $runnable = shift;
    my $provided_inputs = shift // {};
    croak "$runnable is not a runnable"
        unless $runnable and $runnable->DOES('Build::Hopen::G::Runnable');

    croak "I don't know how to handle regexps in $runnable\->need"
        if $runnable->need->complex;

    my %runnable_inputs;    # actual node inputs we will use

    # Requirements, which are a straight list of strings
    foreach my $need (@{$runnable->need->strings}) {
        $runnable_inputs{$need} = $self->find($need, $provided_inputs);
        die "Missing required input $need to @{[$runnable->name]}"
            unless defined $runnable_inputs{$need};
    }

    # Desires can be more complex.
    my $done = Set::Scalar->new;    # Names we've already checked

    # First, grab any we know we want.
    foreach my $want (@{$runnable->want->strings}) {
        $runnable_inputs{$want} = $self->find($want, $provided_inputs);
        $done->insert($want);
    }

    # Next, the wants can grab any available data
    if($runnable->want->complex) {
        foreach my $name (keys %$provided_inputs, keys %$self, keys %ENV) {
            next if $done->has($name);
            if($name ~~ $runnable->want) {
                $runnable_inputs{$name} = $self->find($name, $provided_inputs);
                $done->insert($name);
            }
        }
    } #endif want->complex

    return $runnable->run(\%runnable_inputs);
} #execute()

=head1 FUNCTIONS TO BE OVERRIDDEN IN SUBCLASSES

To implement a Scope with a different data-storage model than the hash
this class uses, subclass Scope and override these functions.  Only L</add>
is part of the public API.

=head2 add

Add key-value pairs to this scope.  Returns the scope so you can
chain.  Example usage:

    my $scope = Build::Hopen::Scope->new()->add(foo => 1);

C<add> is responsible for handling any conflicts that may occur.  In this
particular implementation, the last-added value for a particular key wins.

=cut

sub add {
    my $self = shift;
    my $hrContent = $self->_content;
    while(@_) {
        my $k = shift;
        $hrContent->{$k} = shift;
    }
    croak "Got an odd number of parameters" if @_;
    return $self;
} #add()

=head2 _names_here

Populates a L<Set::Scalar> with the names of the items stored in this Scope,
but B<not> any outer Scope.  Called as:

    $scope->_names_here($set_scalar_instance);

No return value.

=cut

sub _names_here {
    my ($self, $retval) = @_;
    $retval->insert(keys %{$self->_content});
} #_names_here()

=head2 _find_here

Looks for a given item in this scope, but B<not> any outer scope.  Called as:

    $scope->_find_here($name)

Returns the value, or C<undef> if not found.

=cut

sub _find_here {
    $_[0]->_content->{$_[1]};
} #_find_here()

1;
__END__
# vi: set fdm=marker: #
