# Build::Hopen::Tool - base class for a hopen tool.
package Build::Hopen::Tool;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000008'; # TRIAL

use parent 'Build::Hopen::G::Op';
use Class::Tiny;

# Docs {{{1

=head1 NAME

Build::Hopen::Tool - Base class for packages that know how to process files

=head1 SYNOPSIS

A tool knows how to generate a command or other text that will cause
a build system to perform a particular action on a file belonging to a
particular language.

A tool is a L<Build::Hopen::G::Op>, so may interact with the current
generator (L<Build::Hopen/$Generator>).  Moreover, the generator will
get a chance to visit the op after it is processed.

Maybe TODO:
    - Each Generator must specify a list of Content-Types (media types)
        it can consume.  Each Tool must specify a specific content-type
        it produces.  Mismatches are an error unless overriden on the
        hopen command line.

=cut

# }}}1

1;
__END__
# vi: set fdm=marker: #
