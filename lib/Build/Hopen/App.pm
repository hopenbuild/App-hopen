# Build::Hopen::App: hopen(1) program
package Build::Hopen::App;
use Build::Hopen qw(:default hlog hnew loadfrom);
use Build::Hopen::Base;

our $VERSION = '0.000005'; # TRIAL

use Build::Hopen::AppUtil qw(find_hopen_files);
use Build::Hopen::Scope;
use Build::Hopen::ScopeENV;
use Data::Dumper;
use File::Path::Tiny;
use File::Slurper;
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt);
use Hash::Merge;
use Path::Class;

use constant DEBUG          => false;

# Shell exit codes
use constant EXIT_OK        => 0;   # success
use constant EXIT_PROC_ERR  => 1;   # error during processing
use constant EXIT_PARAM_ERR => 2;   # couldn't understand the command line

my @PHASES = ['Check', 'Gen'];
    # TODO be more sophisticated about this :)

# === Command line parsing ============================================== {{{1

my %CMDLINE_OPTS = (
    # hash from internal name to array reference of
    # [getopt-name, getopt-options, optional default-value]
    #   --- However, if default-value is a reference, it will be the
    #   --- destination for that value.
    # They are listed in alphabetical order by option name,
    # lowercase before upper, although the code does not require that order.

    ARCHITECTURE => ['a','|A|architecture|platform=s', ''],
        # -A and --platform are for the comfort of folks migrating from CMake

    #DUMP_VARS => ['d', '|dump-variables', false],
    #DEBUG => ['debug','', false],
    DEFINE => ['D',':s%'],
    EVAL => ['e','|eval=s@'],   # Perl source to run as the last hopen file
    #RESTRICTED_EVAL => ['E','|exec=s@'],
    PROJ_DIR => ['from','=s'],

    GENERATOR => ['g', '|G|generator=s', 'Make'],     # -G is from CMake
        # *** This is where the default generator is set ***

    # -h and --help reserved
    #INCLUDE => ['i','|include=s@'],
    #LIB => ['l','|load=s@'],
    #LANGUAGE => ['L','|language:s'],
    # --man reserved
    # OUTPUT_FILENAME => ['o','|output=s', ""],
    # OPTIMIZE => ['O','|optimize'],
    QUIET => ['q'],
    #SANDBOX => ['S','|sandbox',false],
    #SOURCES reserved
    TOOLCHAIN => ['t','|T|toolchain=s'],        # -T is from CMake
    DEST_DIR => ['to','=s'],
    # --usage reserved
    PRINT_VERSION => ['version','', false],
    VERBOSE => ['v','+', 0],
    # -? reserved

);

sub _parse_command_line { # {{{2
    # Takes {into=>hash ref, from=>array ref}.  Fills in the hash with the
    # values from the command line, keyed by the keys in %CMDLINE_OPTS.

    my %params = @_;
    #local @_Sources;

    my $hrOptsOut = $params{into};

    # Easier syntax for checking whether optional args were provided.
    # Syntax thanks to http://www.perlmonks.org/?node_id=696592
    local *have = sub { return exists($hrOptsOut->{ $_[0] }); };

    # Set defaults so we don't have to test them with exists().
    %$hrOptsOut = (     # map getopt option name to default value
        map { $CMDLINE_OPTS{ $_ }->[0] => $CMDLINE_OPTS{ $_ }[2] }
        grep { (scalar @{$CMDLINE_OPTS{ $_ }})==3 }
        keys %CMDLINE_OPTS
    );

    # Get options
    my $opts_ok = GetOptionsFromArray(
        $params{from},                  # source array
        $hrOptsOut,                     # destination hash
        'usage|?', 'h|help', 'man',     # options we handle here
        map { $_->[0] . ($_->[1] // '') } values %CMDLINE_OPTS, # options strs
        );

    # Help, if requested
    if(!$opts_ok || have('usage') || have('h') || have('man')) {
        # Only pull in the Pod routines if we actually need them.
        require Pod::Usage;
        Pod::Usage::pod2usage(-verbose => 0, -exitval => EXIT_PARAM_ERR, -input => __FILE__) if !$opts_ok;    # unknown opt
        Pod::Usage::pod2usage(-verbose => 0, -exitval => EXIT_OK, -input => __FILE__) if have('usage');
        Pod::Usage::pod2usage(-verbose => 1, -exitval => EXIT_OK, -input => __FILE__) if have('h');
        Pod::Usage::pod2usage(-verbose => 2, -exitval => EXIT_OK, -input => __FILE__) if have('man');
    }

    # Map the option names from GetOptions back to the internal names we use,
    # e.g., $hrOptsOut->{EVAL} from $hrOptsOut->{e}.
    my %revmap = map { $CMDLINE_OPTS{$_}->[0] => $_ } keys %CMDLINE_OPTS;
    for my $optname (keys %$hrOptsOut) {
        $hrOptsOut->{ $revmap{$optname} } = $hrOptsOut->{ $optname };
    }

    # Process other arguments.  The first two non-option arguments are destination
    # dir and project dir, if --from and --to were not given.
    $hrOptsOut->{DEST_DIR} //= $params{from}->[0] if @{$params{from}};
    $hrOptsOut->{PROJ_DIR} //= $params{from}->[1] if @{$params{from}}>1;

    # Option overrides: -q beats -v
    $hrOptsOut->{VERBOSE} = 0 if $hrOptsOut->{QUIET};

} #_parse_command_line() }}}2

# }}}1
# === Main worker code ================================================== {{{1

our $_hrData;   # the hashref of current data

# Run the given phase by executing the hopen files and running the DAG. {{{2
sub _run_phase {
    my %opts = @_;
    $Phase = $opts{phase} if $opts{phase};
    my $lrHopenFiles = $opts{files} // [];

    local $_hrData = $opts{data} // {};

    my $idx = 0;
    my $e_count = 0;    # How many -e commannds we've run
    my $merger = Hash::Merge->new('RETAINMENT_PRECEDENT');

    foreach my $fn (@$lrHopenFiles) {

        # Make the hopen file into a package we can eval

        my ($friendly_name, $text);
        if(ref $fn eq 'SCALAR') {
            hlog { 'Processing -e number', ++$e_count };
            $text = $$fn;
            $friendly_name = "-e #$e_count";

        } else {
            hlog { 'Processing', $fn };
            $text = File::Slurper::read_text($fn);
            $friendly_name = ($fn =~ s{"}{-}gr);
                # as far as I can tell, #line can't handle embedded quotes.
        }

        my $src = <<EOT;
{
    package __R_pkg$idx;
    use Build::Hopen::Base;
    use Build::Hopen ':all';

    sub __R_file$idx {
#line 1 "$friendly_name"
$text
    }

    return __R_file$idx(\$Build::Hopen::App::_hrData);
}
EOT

        # Run the package

        my $hrAddlData = eval($src);
        die "Error in $fn: $@" if $@;

        hlog { 'new data', Dumper($hrAddlData) } 2;

        # TODO? Remove all __R* hash keys from $hrAddlData unless it's a
        # MY.hopen.pl file?

        # Merge in the data

        $_hrData = $merger->merge($_hrData, $hrAddlData) if $hrAddlData;
        hlog { 'data after merge', Dumper($hrAddlData) } 2;
        ++$idx;
    } # foreach hopen file

    hlog { 'Graph is', $Build->empty ? 'empty.' : 'not empty.',
            ' Final data is', Dumper($_hrData) } 2;

    # If there is no build graph, just return the data.  This is useful for
    # debugging.

    return $_hrData if $Build->empty;

    # = Execute the resulting build graph ===================================

    # Wrap the final data in a Scope
    my $env = Build::Hopen::ScopeENV->new(name => 'outermost');
    my $scope = Build::Hopen::Scope->new(name => 'from hopen files');
    $scope->adopt_hash($_hrData);

    # Run the DAG
    my $result_data = $Build->run($scope);
    return $result_data;
} #_run_phase() }}}2

# _inner: Do a run.  {{{2
# Dies on failure.  _Main() then translates the die() into a print and
# error return.
sub _inner {
    my %opts = @_;

    if($opts{PRINT_VERSION}) {  # print version, raw and dotted
        if($Build::Hopen::VERSION =~ m<^([^\.]+)\.(\d{3})(\d{3})>) {
            printf "hopen version %d.%d.%d ($Build::Hopen::VERSION)\n", $1, $2, $3;
        } else {
            say "hopen $VERSION";
        }
        if($opts{VERBOSE} >= 1) {
            say "Build::Hopen: $INC{'Build/Hopen.pm'}";
        }
        return EXIT_OK;
    }

    # Get the project dir
    my $proj_dir = $opts{PROJ_DIR} ? dir($opts{PROJ_DIR}) : dir;    #default=cwd

    # Get the destination dir
    my $dest_dir;
    if($opts{DEST_DIR}) {
        $dest_dir = dir($opts{DEST_DIR});
    } else {
        $dest_dir = $proj_dir->subdir('built');
    }

    # Prohibit in-source builds
    die <<EOT if $proj_dir eq $dest_dir;
I'm sorry, but I don't support in-source builds (dir ``$proj_dir'').  Please
specify a different project directory (--from) or destination directory (--to).
EOT

    # Prohibit builds if there's a MY.hopen.pl file in the project directory,
    # since those are the marker of a destination directory.
    die <<EOT if -e $proj_dir->file(MYH);
I'm sorry, but project directory ``$proj_dir'' appears to actually be a
build directory --- it has a @{[MYH]} file.  If you really want to build
here, remove or rename @{[MYH]} and run me again.
EOT

    # See if we have hopen files associated with the project dir
    my $lrHopenFiles = find_hopen_files($proj_dir, $dest_dir);
    push(@$lrHopenFiles, map { \$_ } @{$opts{EVAL}})
        if $opts{EVAL} && @{$opts{EVAL}};

    hlog { 'hopen files: ', Dumper($lrHopenFiles) } 2;

    die <<EOT unless @$lrHopenFiles;
I can't find any hopen project files (.hopen.pl or *.hopen.pl) for
project directory ``$proj_dir''.
EOT

    $HopenFiles = @$lrHopenFiles;
    $Phase = 'Check';   # TODO

    # = Initialize ==========================================================

    say "Preparing ``$proj_dir'' into ``$dest_dir''" unless $opts{QUIET};

    # Load generator
    my ($gen, $gen_class);
    $gen_class = loadfrom($opts{GENERATOR}, 'Build::Hopen::Gen::', '');
    die "Can't find generator $opts{GENERATOR}" unless $gen_class;
    hlog { "Generator spec ``$opts{GENERATOR}'' -> using generator $gen_class" };

    $gen = "$gen_class"->new(proj_dir => $proj_dir, dest_dir => $dest_dir,
        architecture => $opts{ARCHITECTURE})
            or die "Can't initialize generator";
    $Generator = $gen;

    # Load toolchain
    my ($toolchain, $toolchain_class);
    $opts{TOOLCHAIN} //= $gen->default_toolchain;
    $toolchain_class = loadfrom($opts{TOOLCHAIN},
                                    'Build::Hopen::Toolchain::', '');
    die "Can't find toolchain $opts{TOOLCHAIN}" unless $toolchain_class;

    hlog { "Toolchain spec ``$opts{TOOLCHAIN}'' -> using toolchain $toolchain_class" };

    $toolchain = "$toolchain_class"->new(proj_dir => $proj_dir,
        dest_dir => $dest_dir, architecture => $opts{ARCHITECTURE})
            or die "Can't initialize toolchain";
    $Toolchain = $toolchain;

    # Create the initial DAG
    $Build = hnew DAG => '__R_main';

    # Prepare the destination directory if it doesn't exist
    File::Path::Tiny::mk($dest_dir) or die "Couldn't create $dest_dir: $!";

    # = Run the hopen files =================================================
    my $new_data = _run_phase(files => $lrHopenFiles);

    # = Save state in MY.hopen.pl for the next run ==========================

    # TODO? give the generators a way to stash information that will be
    # written at the top of MY.hopen.pl.  This way, the user may only
    # need to edit right at the top of the file, and not also at the

    my $dumper = Data::Dumper->new([$new_data], ['__R_new_data']);
    $dumper->Purity(1);
    $dumper->Maxrecurse(0);     # no limit
    $dumper->Sortkeys(true);    # For consistency between runs
    $dumper->Sparseseen(true);  # We don't use Seen()

    hlog { Dumper($new_data) };
    File::Slurper::write_text($dest_dir->file(MYH),
        'do { my ' . $dumper->Dump . ' }');

} #_inner() }}}2

# }}}1
# === Command-line runner =============================================== {{{1

# Command-line runner.  Call as Build::Hopen::App::_Main(\@ARGV).
sub _Main {
    my $lrArgs = shift // [];

    # = Process options =====================================================

    my %opts;
    _parse_command_line(from => $lrArgs, into => \%opts);
    ++$Build::Hopen::VERBOSE for 1 .. $opts{VERBOSE};   # Verbosity first

    eval { _inner(%opts); };
    my $msg = $@;
    if($msg) {
        print STDERR $msg;
        return EXIT_PROC_ERR;
    }

    return EXIT_OK;
} #Main()

# }}}1

# no import() --- call Main() directly with its fully-qualified name

1; # End of Build::Hopen::App
__END__
# === Documentation ===================================================== {{{1

=pod

=encoding UTF-8

=head1 NAME

Build::Hopen::App - hopen build system command-line interface

=head1 USAGE

    hopen [options] [--] [destination dir [project dir]]

If no project directory is specified, the current directory is used.

If no destination directory is specified, C<< <project dir>/built >> is used.

=head1 OPTIONS

=over

=item -a C<architecture>

Specify the architecture.  This is an arbitrary string interpreted by the
generator or toolchain.

=item -e C<Perl code>

Add the C<Perl code> as if it were a hopen file.  C<-e> files are processed
after all other hopen files, so can modify anything that has been set up
by those files.  Can be specified more than once.

=item --from C<project dir>

Specify the project directory.  Overrides a project directory given as a
positional argument.

=item -g C<generator>

Specify the generator.  The given C<generator> should be either a full package
name or the part after C<Build::Hopen::Gen::>.

=item -t C<toolchain>

Specify the toolchain.  The given C<toolchain> should be either a full package
name or the part after C<Build::Hopen::Toolchain::>.

=item --to C<destination dir>

Specify the destination directory.  Overrides a destination directory given
as a positional argument.

=item -q

Produce no output (quiet).  Overrides C<-v>.

=item -v

Verbose.  Specify more C<-v>'s for more verbosity.

=item --version

Print the version of hopen and exit

=back

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Build::Hopen::App

You can also look for information at:

=over 4

=item * GitHub: The project's main repository and issue tracker

L<https://github.com/cxw42/hopen>

=item * MetaCPAN

L<https://metacpan.org/pod/Build::Hopen::App>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut

# }}}1
# vi: set ts=4 sts=4 sw=4 et ai foldmethod=marker: #
