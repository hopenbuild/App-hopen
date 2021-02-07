# App::hopen::Phase - interface for phase-specific actions
package App::hopen::Phase;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use Class::Tiny;

# Docs {{{1

=head1 NAME

App::hopen::Phase - interface for phase-specific actions

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 METHODS

=head2 name

Return the name of this phase.

=cut

sub name { ... }

=head2 make_myh

Generate the text for a MY.hopen.pl file.  Returns a string.  Usage:

    my $text = $phase->make_myh(\%build_graph_output)

=cut

sub make_myh { ... }

1;
__END__
# vi: set fdm=marker: #
