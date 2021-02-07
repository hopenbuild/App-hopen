# App::hopen::Phase::Build - Actions specific to the Build phase
package App::hopen::Phase::Build;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::Phase';
use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

App::hopen::Phase::Build - Actions specific to the Build phase

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 FUNCTIONS

=head2 todo

=cut

sub name { 'Build' }

sub make_myh {
    my $self = shift or croak 'Need an instance';

    # TODO carry forward the configuration info
    return 'undef';
} ## end sub make_myh

1;
__END__
# vi: set fdm=marker: #
