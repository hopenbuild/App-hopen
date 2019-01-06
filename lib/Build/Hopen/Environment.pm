# Build::Hopen::Environment - a hopen environment
package Build::Hopen::Environment;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use Build::Hopen::G::Runnable;

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

Find a named data item in the environment and return it.  Returns undef on failure.

=cut

sub find {
    my $self = shift or croak 'Need an instance';
    my $name = shift or croak 'Need a name';        # Therefore, '0' is not a valid name

    return $self->{$name} if exists $self->{$name};

    return $ENV{$name} if exists $ENV{$name};   # fall back to the shell environment

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
    my $hrInputs = shift // {};
    croak "$runnable is not a runnable"
        unless $runnable and $runnable->DOES('Build::Hopen::G::Runnable');

    my %ins;   # actual node inputs we will use

    # Make sure we have the required inputs
    my $needs = 1;      # We are working on the needs

    # Copy needs and wants into %ins.  The `undef` is a marker between
    # the needs and the wants.
    foreach my $name (@{$runnable->need}, undef, @{$runnable->want}) {
        if(!defined $name) {
            $needs = 0;     # moving on to the wants
            next;
        }

        # Check express inputs first...
        if(exists $hrInputs->{$name}) {
            $ins{$name} = $hrInputs->{$name};
            next;
        }

        # ...then this environment.
        my $x = $self->find($name);
        if(defined $x) {
            $ins{$name} = $x;
            next;
        }

        die "Missing required input $name to @{[$runnable->name]}" if $needs;
    } #foreach name

    return $runnable->run(\%ins);
} #execute()

1;
__END__
# vi: set fdm=marker: #
