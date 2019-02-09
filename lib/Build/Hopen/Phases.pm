# Build::Hopen::Phases - definitions of phases
package Build::Hopen::Phases;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000008'; # TRIAL

use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    my @normal_export_ok = qw(is_phase is_last_phase phase_idx next_phase);
    my @hopenfile_export = qw(on);

    @EXPORT = qw(@PHASES);
    @EXPORT_OK = (@normal_export_ok, @hopenfile_export);
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @normal_export_ok],
        hopenfile => [@hopenfile_export],
    );
}

use Build::Hopen::BuildSystemGlobals;
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

This package also defines a special export tag, C<:hopenfile>, for use when
running hopen files.  The wrapper code in L<Build::Hopen::App> uses this
tag.  Hopen files themselves do not need to use this tag.

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

=head2 is_last_phase

Return truthy if the argument is the name of the last phase.

=cut

sub is_last_phase { lc(shift) eq lc($PHASES[$#PHASES]) }

=head2 phase_idx

Get the index of the phase given as a parameter.
Returns undef if none.  Phases are case-insensitive.

=cut

sub phase_idx {
    my $test_phase = lc(shift) or croak "Need a phase";
    my $curr_idx = first_index { lc($_) eq $test_phase } @PHASES;
    return $curr_idx<0 ? undef : $curr_idx;
} #phase_idx()

=head2 next_phase

Get the phase after the given on.  Returns undef if the argument
is the last phase.  Dies if the argument is not a phase.

=cut

sub next_phase {
    my $test_phase = lc(shift) or croak "Need a phase";
    my $curr_idx = phase_idx $test_phase;
    die "$test_phase is not a phase I know about" unless defined($curr_idx);
    return undef if $curr_idx == $#PHASES;  # Last one

    return $PHASES[$curr_idx+1];
} #next_phase()

=head1 ROUTINES FOR USE IN HOPEN FILES

=head2 on

Take a given action only in a specified phase.  Usage examples:

    on check => { foo => 42 };  # Just return the given hashref
    on gen => 1337;             # Returns { Gen => 1337 }
    on check => sub { return { foo => 1337 } };
        # Call the given sub and return its return value.

This is designed for use within a hopen file.
See L<Build::Hopen::App/_run_phase> for the execution environment C<on()> is
designed to run in.

When run as part of a hopen file, C<on()> will skip the rest of the file if it
runs.  For example:

    say "Hello, world!";                # This always runs
    on check => { answer => $answer };  # This runs during the Check phase
    on gen => { done => true };         # This runs during the Gen phase
    say "Phase was neither Check nor Gen";  # Doesn't run in Check or Gen

=cut

sub on {
    my $caller = caller;

    my $which_phase = shift or croak "I need to know which phase this applies to";
    croak "I need a single value or subroutine" unless @_ == 1;
    my $val = shift;

    my $which_idx = phase_idx($which_phase);
    return if $which_idx != phase_idx;

    # We are in the correct phase.  Take appropriate action and stash the
    # result for the caller.  However, don't change our own return value.
    my $result = (ref($val) ne 'CODE') ? $val : &$val;
    $result = { $PHASES[$which_idx] => $result } unless ref $result eq 'HASH';
    {
        no strict 'refs';
        ${ $caller . "::__R_on_result" } = $result;
    }

    # Done --- skip the rest of the hopen file if we're in one.
    eval {
        no warnings 'exiting';
        last __R_DO;
    };
} #on()

1;
__END__
# vi: set fdm=marker: #
