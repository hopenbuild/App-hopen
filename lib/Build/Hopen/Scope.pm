# Build::Hopen::Environment - a hopen environment
package Build::Hopen::Environment;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use Build::Hopen::G::Runnable;
#use Build::Hopen::Util::NameSet;
use Set::Scalar;

# Docs {{{1

=head1 NAME

Build::Hopen::Environment - a hopen environment

=head1 SYNOPSIS

An Environment represents a set of data available to operations.

=cut

# }}}1

=head1 FUNCTIONS

=head2 new

Usage: C<< Build::Hopen::Environment->new() >>.  Returns a blessed hashref.

=cut

sub new {
    my $class = shift or croak 'Need a class';
    return bless {}, $class;
} #new()

=head2 find

Find a named data item in the environment and return it.  Returns undef on
failure.  Usage:

    $instance->find($name[, optional hashref that takes priority])

Tries the hashref if provided, then its own stored hash elements, then the
system environment (C<%ENV>).  Uses the first one it finds.

Dies if given a falsy name, notably, C<'0'>.

=cut

sub find {
    my $self = shift or croak 'Need an instance';
    my $name = shift or croak 'Need a name';
        # Therefore, '0' is not a valid name

    return $_[0]->{$name} if @_ && exists $_[0]->{$name};
    return $self->{$name} if exists $self->{$name};
    return $ENV{$name} if exists $ENV{$name};

    return undef;   # report failure
} #find()

=head2 execute

Run a L<Build::Hopen::G::Runnable> given a set of inputs.  Fills in the inputs
from the environment if possible.  Usage:

    $env->execute($runnable[, {inputs...})

=cut

sub execute {
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

1;
__END__
# vi: set fdm=marker: #
