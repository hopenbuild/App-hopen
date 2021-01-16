# App::hopen::Util::PhaseManager - Manage string sets representing phases
package App::hopen::Util::PhaseManager;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

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

Stores and supports queries on an ordered list of case-insensitive strings.
Part of L<App::hopen>.

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

=head2 next

    $manager->next('first')     # -> second
    $manager->next('last')      # -> ''

Returns C<''> if there is no next phase.
Dies if the given phase isn't recognized.

=head2 is_last

    $manager->is_last('first')  # -> falsy
    $manager->is_last('last')   # -> truthy

Dies if the given phase isn't recognized.

=cut

# }}}1

# Perl 5.16 has 'fc' feature; older Perls can just use 'lc'.
# This block by Toby Inkster.
use if $] >= 5.016, feature => 'fc';
BEGIN { $] < 5.016 and eval 'sub fc ($) { lc $_[0] }' };

sub new {
    my ($class, @phases) = @_;
    die "Need phase names" unless @phases;
    die "All phase names must be truthy" if grep { !$_ } @phases;
        # Not using List::Util::any so we can work with L::U in core w/5.14
    my %phaseHash = map {fc($phases[$_]) => fc($phases[$_ + 1] || '')}
        0 .. $#phases;

    # falsy key is available, since that can't be a phase name
    $phaseHash{0} = [fc $phases[0], fc $phases[$#phases]];

    return bless \%phaseHash, $class;
}

sub first { shift->{0}->[0] }

sub last { shift->{0}->[1] }

sub check {
    my ($self, $phase) = @_;
    $phase = fc $phase;
    return exists $self->{$phase} ? $phase : '';
}

sub next {
    my ($self, $phase) = @_;
    $phase = fc $phase;

    die "Unknown phase '$phase'" if !exists $self->{$phase};
    return $self->{$phase};
}

sub is_last {
    my ($self, $phase) = @_;
    $phase = fc $phase;

    die "Unknown phase '$phase'" if !exists $self->{$phase};
    return !($self->{$phase});
}

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
