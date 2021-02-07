# App::hopen::Phase - interface for phase-specific actions
package App::hopen::Phase;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use Class::Tiny;

use App::hopen::AppUtil qw(PHASES);

# Docs {{{1

=head1 NAME

App::hopen::Phase - interface for phase-specific actions

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 METHODS

=head2 Informational

=head3 is

Returns truthy if the parameter is the name of the given phase
in L<App::hopen::AppUtil/PHASES>.

=cut

sub is { PHASES->is($_[1], $_[0]->name) }

=head3 name

Return the name of this phase.

=cut

sub name { ... }

=head3 next

Return the name of the next phase, or the name of this phase if this is the last phase

=cut

sub next { PHASES->next($_[0]->name) || $_[0]->name }

=head2 Operational

=head3 make_myh

Generate the text for a MY.hopen.pl file.  Returns a string.  Usage:

    my $text = $phase->make_myh(\%build_graph_output)

=cut

sub make_myh { ... }

1;
__END__
# vi: set fdm=marker: #
