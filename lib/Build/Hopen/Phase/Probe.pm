# Build::Hopen::Phase::Probe - probe-phase operations
package Build::Hopen::Phase::Probe;
use Build::Hopen;
use Build::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000005'; # TRIAL

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw(find_hopen_files);
    @EXPORT_OK = qw();
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

#use Class::Tiny qw(TODO);

use File::Spec;
use Cwd qw(getcwd abs_path);

# Docs {{{1

=head1 NAME

Build::Hopen::Phase::Probe - Check the build system

=head1 SYNOPSIS

Probe runs first.  Probe reads a foundations file and outputs a capability
file and an options file.  The user can then edit the options file to
customize the build.

Probe also locates context files.  For example, when processing C<~/foo/.hopen>,
Probe will also find C<~/foo.hopen> if it exists.

=cut

# }}}1

=head1 FUNCTIONS

=head2 find_hopen_files

Finds the hopen files from the given directory, or the current directory
if none is specified.  Usage:

    my $files_array = find_hopen_files

=cut

sub find_hopen_files {
    my $dir = shift // abs_path(getcwd);
    hlog { 'Looking for hopen files in', $dir };
    ...
} #find_hopen_files()

#sub import {    # {{{1
#} #import()     # }}}1

#1;
__END__
# vi: set fdm=marker: #
