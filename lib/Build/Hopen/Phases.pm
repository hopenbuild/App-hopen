# Build::Hopen::Phases - definitions of phases
package Build::Hopen::Phases;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw(@PHASES);
    @EXPORT_OK = qw(is_phase phase_idx next_phase);
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

use List::MoreUtils qw(first_index);

# Docs {{{1

=head1 NAME

Build::Hopen::Phases - Definitions and routines for hopen phases

=head1 SYNOPSIS

Definition of hopen phases.  Phase names are case-insensitive.  The canonical
form has only the first letter capitalized.

Phase names may only contain ASCII letters, digits, or underscore.  The first
character of a phase may not be a digit.  This is so they can be used as
identifiers if necessary.

=head1 VARIABLES

=head2 @PHASES

The phases we know about, in order.

=head1 FUNCTIONS

=cut

# }}}1

# Phases are case-insensitive.
our @PHASES; BEGIN { @PHASES = ('Check', 'Gen'); }
    # *** This is where the default phase ($PHASES[0]) is set ***
    # TODO? be more sophisticated about this :)

=head2 is_phase

Return truthy if the given argument is the name of a phase we know about.

=cut

sub is_phase {
    my $test_phase = lc(shift) or croak 'Need a phase name';
    my $curr_idx = first_index { lc($_) eq $test_phase } @PHASES;
    return $curr_idx+1;     # -1 => falsy; all others => truthy
} #is_phase()

=head2 phase_idx

Get the index of the current phase, or the phase given as a parameter.
Returns undef if none.  Phases are case-insensitive.

=cut

sub phase_idx {
    my $test_phase = lc(@_ ? $_[0] : $Phase);
    my $curr_idx = first_index { lc($_) eq $test_phase } @PHASES;
    return $curr_idx<0 ? undef : $curr_idx;
} #phase_idx()

=head2 next_phase

Get the next phase, or undef if none.  Phases are case-insensitive.

=cut

sub next_phase {
    croak 'I only process $Phase, but I got an argument' if @_;
    my $curr_idx = phase_idx;
    die "This shouldn't happen!" unless defined($curr_idx);
    return undef if $curr_idx == $#PHASES;  # Last one

    return $PHASES[$curr_idx+1];
} #next_phase()

1;
__END__
# vi: set fdm=marker: #
