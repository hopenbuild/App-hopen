# Build::Hopen::Tool - base class for a hopen tool.
package Build::Hopen::Tool;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

## TODO if using exporter
#use parent 'Exporter';
#our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
#BEGIN {
#    @EXPORT = qw();
#    @EXPORT_OK = qw(find_hopen_files);
#    %EXPORT_TAGS = (
#        default => [@EXPORT],
#        all => [@EXPORT, @EXPORT_OK]
#    );
#}

use parent 'Build::Hopen::G::Op';
#use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

Build::Hopen::Tool - Base class for packages that know how to process files

=head1 SYNOPSIS

A tool knows how to generate a command or other text that will cause
a build system to perform a particular action on a file belonging to a
particular language.

A tool is a L<Build::Hopen::G::Op>, so may interact with the current
generator (L<Build::Hopen/$Generator>).

=cut

# }}}1

1;
__END__
# vi: set fdm=marker: #
