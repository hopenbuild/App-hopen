# Build::Hopen::AppUtil - utility routines used by Build::Hopen::App
package Build::Hopen::AppUtil;
use Build::Hopen qw(:default MYH);
use Build::Hopen::Base;
use parent 'Exporter';

our $VERSION = '0.000005'; # TRIAL

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw(find_hopen_files find_myhopen dedent forward_opts);
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
    my $proj_dir = @_ ? dir($_[0]) : dir;
    my $dest_dir = dir($_[1]) if @_>=2;
    my $ignore_MY_hopen = $_[2];

    local *d = sub { $proj_dir->file(shift) };

    hlog { 'Looking for hopen files in', $proj_dir->absolute };

    # Look for files that are included with the project
    my @candidates = sort(
        grep { !isMYH && -r } (
            bsd_glob(d('*.hopen.pl'), GLOB_NOSORT),
            bsd_glob(d('.hopen.pl'), GLOB_NOSORT),
        )
    );
    hlog { 'Candidates:', @candidates ? @candidates : 'none' };
    @candidates = $candidates[$#candidates] if @candidates;
        # Only use the last one

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

=head2 find_myhopen

Find a C<MY.hopen.pl> file, if any.  Returns undef if none is present.

=cut

sub find_myhopen {
    return if $_[1];    # $ignore_MY_hopen
    my $dest_dir = shift or return;     # No dest dir => no MY.hopen.pl

    # Find $dest_dir/MY.hopen.pl, if there is one.
    my $fn = $dest_dir->file(MYH);
    return $fn if -r $fn;
} #find_myhopen

=head2 dedent

Yet Another routine for dedenting multiline strings.  Removes the leading
horizontal whitespace on the first nonblank line from all lines.  If the first
argument is a reference, also trims for use in multiline C<q()>/C<qq()>.
Usage:

    dedent " some\n multiline string";
    dedent [], q(
        very indented
    );      # [] (or any ref) means do the extra trimming.

The extra trimming includes:

=over

=item *

Removing the initial C<\n>, if any; and

=item *

Removing trailing horizontal whitespace between the last C<\n> and the
end of the string.

=back

=cut

sub dedent {
    my $extra_trim = (@_ && ref $_[0]) ? (shift, true) : false;
    my $val = @_ ? $_[0] : $_;
    my $initial_NL;

    if($val =~ /\A\n/) {
        $initial_NL = true;
        $val =~ s/^\A\n//;
    }

    if($val =~ m/^(?<ws>\h+)\S/m) {
        $val =~ s/^$+{ws}//gm;
    }

    $val =~ s/^\h+\z//m if $extra_trim;

    return (($initial_NL && !$extra_trim) ? "\n" : '') . $val;
} #dedent()

=head2 forward_opts

Returns a list of key-value pairs extracted from a given hashref.  Usage:

    my %forwarded_opts = forward_opts(\%original_opts, [option hashref,]
                                        'name'[, 'name2'...]);

If the option hashref is given, the following can be provided:

=over

=item lc

If truthy, lower-case the key names in the output

=back

=cut

sub forward_opts {
    my $hrIn = shift or croak 'Need an input option set';
    croak 'Need a hashref' unless ref $hrIn eq 'HASH';
    my $hrOpts = {};
    $hrOpts = shift if ref $_[0] eq 'HASH';

    my %result;
    foreach my $name (@_) {
        my $newname = $hrOpts->{lc} ? lc($name) : $name;
        $result{$newname} = $hrIn->{$name} if exists $hrIn->{$name};
    }

    return %result;
} #forward_opts()

1;
__END__
# vi: set fdm=marker: #
