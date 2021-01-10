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

=head2 check

Regularize a phase name.

    $manager->check('first')    # -> first
    $manager->check('FIRst')    # -> first
    $manager->check('oops')     # -> falsy

=head2 next

    $manager->next('first')     # -> second
    $manager->next('last')      # -> ''

=head2 is_last

    $manager->is_last('first')  # -> falsy
    $manager->is_last('last')   # -> truthy

=cut

# }}}1

# Regularize a string
sub _reg {
    goto &lc;
}

sub new {
    my ($class, @phases) = @_;
    die "All phase names must be truthy" if grep { !$_ } @phases;
        # TODO use any{}?
    my %phaseHash = map {_reg($phases[$_]) => _reg($phases[$_ + 1] || '')}
        0 .. $#phases;

    return bless \%phaseHash, $class;
}

sub check {
    my ($self, $phase) = @_;
    $phase = _reg $phase;
    return exists $self->{$phase} ? $phase : '';
}
sub next {
    my ($self, $phase) = @_;

    die "Unknown phase '$phase'" if !exists $self->{_reg $phase};
    return $self->{_reg $phase};
}

sub is_last {
    my ($self, $phase) = @_;

    die "Unknown phase '$phase'" if !exists $self->{_reg $phase};
    return !!($self->{_reg $phase});
}


1;
__END__

# Rest of the documentation {{{1

=head1 AUTHOR

GrandFather, L<https://www.perlmonks.org/?node_id=461912>.

Some code by Christopher White, C<cxwembedded@gmail.com>.

Originally from L<https://www.perlmonks.org/?node_id=11125768>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2020 GrandFather and contributors.  All rights reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

# }}}1
# vi: set fdm=marker: #
