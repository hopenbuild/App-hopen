# App::hopen::Util::PhaseManager - Manage string sets representing phases
package App::hopen::Util::PhaseManager;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

# Docs {{{1

=head1 NAME

App::hopen::Util::PhaseManager - Manage string sets representing phases

=head1 SYNOPSIS

    my $manager = PhaseManager->new (qw'first second last');
    my @testPhases = qw'first Second LAST FUBAR';

    for my $currPhase (@testPhases) {
        my $nextPhase = $manager->next($currPhase) || '<No next phase>';

        print "Phase '$currPhase' goes to '$nextPhase'\n";
    }

=head1 DESCRIPTION

Stores a list of strings and supports case-insenstive queries on those strings.
Part of L<App::hopen>.

Phase names returned by functions are in the original case provided to L</new>.
However, you may give a function a name in any case.

=head1 METHODS

=head2 new

    my $manager = PhaseManager->new (qw'first second last');

Phase strings cannot be empty (C<''>), and cannot be falsy (C<'0'>).

=head2 first

Return the name of the first phase.  Usage: C<< $manager->first >>.

=head2 last

Return the name of the last phase.  Usage: C<< $manager->last >>.

=head2 check

Regularize a phase name.

    $manager->check('first')    # -> first
    $manager->check('FIRst')    # -> first
    $manager->check('oops')     # -> falsy

Returns falsy if the given phase isn't recognized.

=head2 enforce

Exactly like L</check>, but dies if the given phase isn't recognized.

    $manager->enforce('FIRst')    # -> first
    $manager->enforce('oops')     # -> dies

=head2 is

Check whether a given string indicates a given phase.

    $manager->is('first', 'first')          # true
    $manager->is('FirST', 'first')          # true
    $manager->is('second', 'first')         # false
    $manager->is('nonexistent', 'first')    # false

Returns falsy if the given phase isn't recognized.

=head2 next

    $manager->next('first')     # -> second
    $manager->next('last')      # -> ''

Returns C<''> if there is no next phase.
Dies if the given phase isn't recognized.

=head2 is_last

    $manager->is_last('first')  # -> falsy
    $manager->is_last('last')   # -> truthy

Dies if the given phase isn't recognized.

=head2 all

Returns the list of all the phases, in order.

=head1 VARIABLES

=head2 $USE_LC

If set truthy before this module is C<use>d, use L<perlfunc/lc> instead of
L<perlfunc/fc>, even on Perls that have C<fc>.

=cut

# }}}1

our $USE_LC;

# Perl 5.16 has 'fc' feature; older Perls can just use 'lc'.
# This block by Toby Inkster, modified by Chris White
use vars::i '$_USE_LC' => ($] lt '5.016') || $USE_LC;
use if !$_USE_LC, feature => 'fc';
BEGIN { $_USE_LC and eval 'sub fc (_) { lc $_[0] }' }

sub new {
    my ($class, @phases) = @_;
    die "Need phase names" unless @phases;
    die "All phase names must be truthy" if grep { !$_ } @phases;

    # Not using List::Util::any so we can work with L::U in core w/5.14

    my %phaseHash =
      map { fc($phases[$_]) => ($phases[ $_ + 1 ] || '') } 0 .. $#phases;

    my $self = {
        seq  => \%phaseHash,    # one to the next
        pos  => { map { ; fc $phases[$_] => $_ } 0 .. $#phases },
        orig => [@phases],      # exactly from the user
    };
    return bless $self, $class;
} ## end sub new

sub first { shift->{orig}->[0] }

sub last {
    my $phases = shift->{orig};
    return $phases->[$#$phases];
}

sub check {
    my ($self, $phase) = @_;
    $phase = fc($phase // '');
    return
      exists $self->{pos}->{$phase}
      ? $self->{orig}->[ $self->{pos}->{$phase} ]
      : '';
} ## end sub check

sub enforce {
    my $p = $_[0]->check($_[1]);
    croak "Unknown phase $_[1] (valid phases are @{$_[0]->{orig}})" unless $p;
    return $p;
}

sub is {
    my ($self, $got, $expected) = @_;

    my $g = $self->check($got);
    my $e = $self->check($expected);
    return false unless $g && $e;
    return $g eq $e;
} ## end sub is

sub next {
    my ($self, $phase) = @_;
    $phase = fc $phase;

    croak "Unknown phase '$phase'" if !exists $self->{seq}->{$phase};
    return $self->{seq}->{$phase};
} ## end sub next

sub is_last {
    my ($self, $phase) = @_;
    $phase = fc $phase;

    croak "Unknown phase '$phase'" if !exists $self->{seq}->{$phase};
    return !($self->{seq}->{$phase});
} ## end sub is_last

sub all { @{ $_[0]->{orig} } }

1;
__END__

# Rest of the documentation {{{1

=head1 AUTHOR

=over

=item *

GrandFather, L<https://www.perlmonks.org/?node_id=461912>.

=item *

Some code by Toby Inkster, L<https://toby.ink/>.

=item *

Some code by Christopher White, C<cxwembedded@gmail.com>.

=back

Originally from L<https://www.perlmonks.org/?node_id=11125768>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2020 GrandFather, Toby Inkster, and Christopher White.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# }}}1
# vi: set fdm=marker: #
