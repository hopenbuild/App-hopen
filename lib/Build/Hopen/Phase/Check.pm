# Build::Hopen::Phase::Check - checking-phase operations
package Build::Hopen::Phase::Check;
use Build::Hopen;
use Build::Hopen::Base;
use parent 'Exporter';

$Build::Hopen::VERBOSE=1;   # DEBUG

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

#use Build::Hopen::PathCapsule;
use Cwd qw(getcwd abs_path);
use File::Glob ':bsd_glob';
#use File::Globstar qw(globstar);
use File::Spec;
use Path::Class;

# Docs {{{1

=head1 NAME

Build::Hopen::Phase::Check - Check the build system

=head1 SYNOPSIS

Check runs first.  Check reads a foundations file and outputs a capability
file and an options file.  The user can then edit the options file to
customize the build.

Check also locates context files.  For example, when processing C<~/foo/.hopen>,
Check will also find C<~/foo.hopen> if it exists.

=cut

# }}}1

=head1 FUNCTIONS

=head2 find_hopen_files

Finds the hopen files from the given directory, or the current directory
if none is specified.  Usage:

    my $files_array = find_hopen_files([$dir])

If no C<$dir> is given, cwd is used.

=cut

sub find_hopen_files {
    my $here = @_ ? dir($_[0]) : dir;
    local *d = sub { $here->file(shift) };
        # Need slash as the separator for File::Globstar.

    hlog { 'Looking for hopen files in', $here->absolute };

    # Look for files that are included with the project
    my @candidates = sort(
        bsd_glob(d('*.hopen'), GLOB_NOSORT),
        bsd_glob(d('.hopen'), GLOB_NOSORT),
    );
    hlog { "Candidates", @candidates };

    # TODO Look in the parent dir for context files
    my $parent_dir = $here->parent;

    # TODO decide what order to return the dirs in
    return @candidates;
} #find_hopen_files()

#sub import {    # {{{1
#} #import()     # }}}1

#1;
__END__
# vi: set fdm=marker: #
