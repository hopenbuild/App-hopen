# App::hopen::Lang::C - LSP for C
package App::hopen::Lang::C;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use parent 'App::hopen::Lang';
use Class::Tiny;

# Docs {{{1

=head1 NAME

App::hopen::Lang::C - LSP for C

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 FUNCTIONS

=head2 find_deps

Find C dependencies.  The return hashref has keys C<ipath> (like -I),
C<lpath> (-L), and C<lname> (-l).  Each key has an arrayref as its value.

=cut

sub find_deps {
    my ($self, %args) = getparameters('self', [qw(deps ; choices)], @_);
    # TODO RESUME HERE ---
    # 1. Create the infrastructure for choices and add that infrastructure
    #    to MY.hopen.pl.
    # 2. Run pkg-config here for libraries and parse the results
    return { ipath => [], lpath => [], lname => [] };   # TODO
} #find_deps()

1;
__END__
# vi: set fdm=marker: #
