# App::hopen::AppUtil - utility routines used by App::hopen::App
package App::hopen::AppUtil;
use Data::Hopen;
use App::hopen::Util qw(isMYH MYH);
use strict;
use warnings;
use Data::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000013';    # TRIAL

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS, @_export_constants);

BEGIN {
    @EXPORT            = qw();
    @_export_constants = qw(KEY_PHASE KEY_GENERATOR_CLASS KEY_TOOLSET_CLASS
      KEY_LANGOPTS PHASES);
    @EXPORT_OK   = (qw(find_hopen_files find_myhopen), @_export_constants);
    %EXPORT_TAGS = (
        default   => [@EXPORT],
        all       => [ @EXPORT, @EXPORT_OK ],
        constants => [@_export_constants],
    );
} ## end BEGIN

use Cwd qw(getcwd abs_path);
use File::Glob $] lt '5.016' ? ':glob' : ':bsd_glob';

# Thanks to haukex, https://www.perlmonks.org/?node_id=1207115 -
# 5.14 doesn't support the ':bsd_glob' tag.
use Path::Class;

# Define the phase sequence
use App::hopen::Util::PhaseManager;
use vars::i '$_phases' =>
  App::hopen::Util::PhaseManager->new(qw(Check Gen Build));

=head1 NAME

App::hopen::AppUtil - utility routines used by App::hopen

=head1 CONSTANTS

=head2 HOPEN_FILE_FLAG

The name of a variable that must exist in a hopen file when it is interpreted.
See L<App::hopen::HopenFileKit/import>.

=cut

use constant HOPEN_FILE_FLAG => 'IsHopenFile';

=head2 KEY_PHASE, KEY_GENERATOR_CLASS, KEY_TOOLSET_CLASS

The names of the keys used in scopes for phase, generator class, and
toolset class, respectively.

=head2 KEY_LANGOPTS

The name of the key under which language-specific information
(from an L<App::hopen::Lang> subclass) is stored.  This is a hashref
indexed by language name.

=cut

use constant {
    KEY_PHASE           => '=Phase',
    KEY_GENERATOR_CLASS => '=GeneratorClass',
    KEY_TOOLSET_CLASS   => '=ToolsetClass',
    KEY_LANGOPTS        => '=Lang',
};

=head2 PHASES

A L<App::hopen::Util::PhaseManager> holding the phase sequence used by
L<App::hopen>.  See L<App::hopen::Manual/PHASES> for details.

=cut

sub PHASES () { $_phases }

=head1 FUNCTIONS

=head2 find_hopen_files

Find the hopen files applicable to the given build directory.
Returns a list of hopen files, if any, to process for the given directory.
Hopen files match C<*.hopen.pl> or C<.hopen.pl>.  Usage:
Also locates context files.  For example, when processing C<~/foo/.hopen>,
Check will also find C<~/foo.hopen> if it exists.

    my $files_array = find_hopen_files(
        [$proj_dir[, $dest_dir[, $ignore_MY_hopen]]])

If no C<$proj_dir> is given, the current directory is used.

If C<$ignore_MY_hopen> is truthy, C<$dest_dir> will not be checked for
a C<MY.hopen.pl> file.

The returned files should be processed in left-to-right order.

The return array will include a context file if any is present.
For C<$dir eq '/foo/bar'>, for example, C</foo/bar.hopen.pl> is the
name of the context file.

=cut

sub find_hopen_files {
    my $proj_dir        = @_ ? dir($_[0]) : dir;
    my $dest_dir        = dir($_[1]) if @_ >= 2;
    my $ignore_MY_hopen = $_[2];

    local *d = sub { $proj_dir->file(shift) };

    hlog { 'Looking for hopen files in', $proj_dir->absolute };

    # Look for files that are included with the project
    my @candidates = sort(grep { !isMYH && -r } (
            bsd_glob(d('*.hopen.pl'), GLOB_NOSORT),
            bsd_glob(d('.hopen.pl'),  GLOB_NOSORT),
    ));
    hlog { 'Candidates:', @candidates ? @candidates : 'none' };
    @candidates = $candidates[$#candidates] if @candidates;

    # Only use the last one

    # Look in the parent dir for context files.
    # The context file comes after the earlier candidate.
    my $parent = $proj_dir->parent;
    if($parent ne $proj_dir) {    # E.g., not root dir
        my $me = $proj_dir->absolute->basename;

        # Absolute because dir might be `.`.
        my $context_file = $parent->file("$me.hopen.pl");
        if(-r $context_file) {
            push @candidates, $context_file;
            hlog { 'Context file', $context_file };
        }
    } ## end if($parent ne $proj_dir)

    hlog {
        @candidates
          ? ('Using hopen files', @candidates)
          : 'No hopen files found on disk'
    };
    return [@candidates];
} ## end sub find_hopen_files

=head2 find_myhopen

Find a C<MY.hopen.pl> file, if any.  Returns undef if none is present.

=cut

sub find_myhopen {
    return if $_[1];                   # $ignore_MY_hopen
    my $dest_dir = shift or return;    # No dest dir => no MY.hopen.pl

    # Find $dest_dir/MY.hopen.pl, if there is one.
    my $fn = $dest_dir->file(MYH);
    return $fn if -r $fn;
} ## end sub find_myhopen

1;
__END__
# vi: set fdm=marker: #
