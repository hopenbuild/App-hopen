# Build::Hopen::AppUtil - utility routines used by Build::Hopen::App
package Build::Hopen::AppUtil;
use Build::Hopen;
use Build::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000005'; # TRIAL

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw(find_hopen_files);
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

use Cwd qw(getcwd abs_path);
use File::Glob ':bsd_glob';
use Path::Class;

# Docs {{{1

=head1 NAME

Build::Hopen::AppUtil - utility routines used by Build::Hopen::App

=head1 FUNCTIONS

# }}}1

=head2 find_hopen_files

Find the hopen files applicable to the given build directory.
Returns a list of hopen files, if any, to process for the given directory.
Hopen files match C<*.hopen.pl> or C<.hopen.pl>.  Usage:
Also locates context files.  For example, when processing C<~/foo/.hopen>,
Check will also find C<~/foo.hopen> if it exists.

    my $files_array = find_hopen_files([$proj_dir[, $dest_dir]])

If no C<$proj_dir> is given, the current directory is used.

The returned files should be processed in left-to-right order.

The return array will include a context file if any is present.
For C<$dir eq '/foo/bar'>, for example, C</foo/bar.hopen.pl> is the
name of the context file.

=cut

sub find_hopen_files {
    my $proj_dir = @_ ? dir($_[0]) : dir;
    my $dest_dir = $_[1] if @_>1;

    local *d = sub { $proj_dir->file(shift) };

    hlog { 'Looking for hopen files in', $proj_dir->absolute };

    # Look for files that are included with the project
    my @candidates = sort(
        grep { ($_ !~ /MY\.hopen\.pl$/) && (-r $_) } (
            bsd_glob(d('*.hopen.pl'), GLOB_NOSORT),
            bsd_glob(d('.hopen.pl'), GLOB_NOSORT),
        )
    );
    hlog { 'Candidates:', @candidates ? @candidates : 'none' };
    @candidates = $candidates[$#candidates] if @candidates;
        # Only use the last one

    # Add a $dest_dir/MY.hopen.pl file first, if there is one.
    if($dest_dir) {
        my $MY = $dest_dir->file('MY.hopen.pl');
        unshift @candidates, $MY if -r $MY;
    }

    # Look in the parent dir for context files.
    # The context file comes after the earlier candidate.
    my $parent = $proj_dir->parent;
    if($parent ne $proj_dir) {          # E.g., not root dir
        my $me = $proj_dir->absolute->basename;
            # Absolute because dir might be `.`.
        my $context_file = $parent->file("$me.hopen.pl");
        if(-r $context_file) {
            push @candidates, $context_file;
            hlog { 'Context file', $context_file };
        }
    }

    hlog { @candidates ? ('Using hopen files', @candidates) :
                            'No hopen files found on disk' };
    return [@candidates];
} #find_hopen_files()

1;
__END__
# vi: set fdm=marker: #
