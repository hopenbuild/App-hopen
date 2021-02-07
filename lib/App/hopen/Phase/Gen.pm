# App::hopen::Phase::Gen - Actions specific to the Gen phase
package App::hopen::Phase::Gen;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::Phase';
use Class::Tiny;

use App::hopen::AppUtil qw(PHASES);

# Docs {{{1

=head1 NAME

App::hopen::Phase::Gen - Actions specific to the Gen phase

=head1 SYNOPSIS

TODO

=cut

# }}}1

sub name { 'Gen' }

sub make_myh {
    my $self = shift or croak 'Need an instance';

    # TODO RESUME HERE carry forward the configuration info (and likewise
    # in Phase::Build)
    return 'undef';
} ## end sub make_myh

1;
__END__
# vi: set fdm=marker: #
