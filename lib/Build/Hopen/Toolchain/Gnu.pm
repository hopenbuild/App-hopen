# Build::Hopen::Toolchain::Gnu - GNU toolchain
package Build::Hopen::Toolchain::Gnu;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::Toolchain';
#use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

Build::Hopen::Toolchain::Gnu - GNU toolchain for hopen

=head1 SYNOPSIS

This toolchain supports any compiler that will accept gcc(1) options, and any
linker that will accept GNU ld(1) options.

=head1 FUNCTIONS

=cut

# }}}1

1;
__END__
# vi: set fdm=marker: #
