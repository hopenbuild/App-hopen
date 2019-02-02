# Build::Hopen::App: hopen(1) program
package Build::Hopen::App;
our $VERSION = '0.000005'; # TRIAL

# Imports {{{1
use Build::Hopen::Base;

use Build::Hopen qw(:default loadfrom MYH);
use Build::Hopen::AppUtil ':all';
use Build::Hopen::Phases qw(:default phase_idx next_phase);
use Build::Hopen::Scope;
use Build::Hopen::ScopeENV;
use Data::Dumper;
use File::Path::Tiny;
use File::Slurper;
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt);
use Hash::Merge;
use Path::Class;

# }}}1
# Constants {{{1

use constant DEBUG          => false;

# Shell exit codes
use constant EXIT_OK        => 0;   # success
use constant EXIT_PROC_ERR  => 1;   # error during processing
use constant EXIT_PARAM_ERR => 2;   # couldn't understand the command line

# }}}1
# Documentation {{{1

=pod

=encoding UTF-8

=head1 NAME

Build::Hopen::App - hopen build system command-line interface

=head1 USAGE

    hopen [options] [--] [destination dir [project dir]]

If no project directory is specified, the current directory is used.

If no destination directory is specified, C<< <project dir>/built >> is used.

=head1 INTERNALS

=cut

# }}}1
# === Command line parsing ============================================== {{{1

=head2 %CMDLINE_OPTS

A hash from internal name to array reference of
[getopt-name, getopt-options, optional default-value].

If default-value is a reference, it will be the destination for that value.
=cut

my %CMDLINE_OPTS = (
    # They are listed in alphabetical order by option name,
    # lowercase before upper, although the code does not require that order.

    ARCHITECTURE => ['a','|A|architecture|platform=s'],
        # -A and --platform are for the comfort of folks migrating from CMake

    #BUILD => ['build'],    # TODO implement this --- if specified, do not
                            # run any phases.  Instead, run the
                            # build tool indicated by the generator.

    #DUMP_VARS => ['d', '|dump-variables', false],
    #DEBUG => ['debug','', false],
    DEFINE => ['D',':s%'],
    EVAL => ['e','|eval=s@'],   # Perl source to run as a hopen file
    #RESTRICTED_EVAL => ['E','|exec=s@'],
    # TODO add -f to specify additional hopen files
    FRESH => ['fresh'],         # Don't run MY.hopen.pl
    PROJ_DIR => ['from','=s'],

    GENERATOR => ['g', '|G|generator=s', 'Make'],     # -G is from CMake
        # *** This is where the default generator is set ***

    #GO => ['go'],  # TODO implement this --- if specified, run all phases
                    # and invoke the build tool without requiring the user to
                    # re-run hopen.

    # -h and --help reserved
    #INCLUDE => ['i','|include=s@'],
    #LIB => ['l','|load=s@'],   # TODO implement this.  A separate option
                                # for libs only used for hopen files?
    #LANGUAGE => ['L','|language:s'],
    # --man reserved
    # OUTPUT_FILENAME => ['o','|output=s', ""],
    # OPTIMIZE => ['O','|optimize'],

    PHASE => ['phase','=s'],    # NO DEFAULT so we can tell if --phase was used

    QUIET => ['q'],
    #SANDBOX => ['S','|sandbox',false],
    #SOURCES reserved
    TOOLSET => ['t','|T|toolset=s'],        # -T is from CMake
    DEST_DIR => ['to','=s'],
    # --usage reserved
    PRINT_VERSION => ['version','', false],
    VERBOSE => ['v','+', 0],
    # -? reserved

);

sub _parse_command_line { # {{{2

=head2 _parse_command_line

Takes {into=>hash ref, from=>array ref}.  Fills in the hash with the
values from the command line, keyed by the keys in L</%CMDLINE_OPTS>.

=cut

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

        # Terminal formatting, if present.
        {
            no warnings 'once';
            eval "require Pod::Text::Termcap";
            $Pod::Usage::Formatter = 'Pod::Text::Termcap' unless $@;
        }

        require Pod::Usage;

        my @in = (-input => __FILE__);
        Pod::Usage::pod2usage(-verbose => 0, -exitval => EXIT_PARAM_ERR, @in)
            unless $opts_ok;   # unknown opt
        Pod::Usage::pod2usage(-verbose => 0, -exitval => EXIT_OK, @in)
            if have('usage');
        Pod::Usage::pod2usage(-verbose => 1, -exitval => EXIT_OK, @in)
            if have('h');

        # --man: suppress "INTERNALS" section.  Note that this does
        # get rid of the automatic pager we would otherwise get
        # by virtue of pod2usage's invoking perldoc(1).  Oh well.

        Pod::Usage::pod2usage(
            -exitval => EXIT_OK, @in,
            -verbose => 99, -sections => '!INTERNALS'   # suppress
        ) if have('man');
    }

    # Map the option names from GetOptions back to the internal names we use,
    # e.g., $hrOptsOut->{EVAL} from $hrOptsOut->{e}.
    my %revmap = map { $CMDLINE_OPTS{$_}->[0] => $_ } keys %CMDLINE_OPTS;
    for my $optname (keys %$hrOptsOut) {
        $hrOptsOut->{ $revmap{$optname} } = $hrOptsOut->{ $optname };
    }

    # Process other arguments.  The first two non-option arguments are dest
    # dir and project dir, if --from and --to were not given.
    $hrOptsOut->{DEST_DIR} //= $params{from}->[0] if @{$params{from}};
    $hrOptsOut->{PROJ_DIR} //= $params{from}->[1] if @{$params{from}}>1;

    # Option overrides: -q beats -v
    $hrOptsOut->{VERBOSE} = 0 if $hrOptsOut->{QUIET};

} #_parse_command_line() }}}2

# }}}1
# === Main worker code ================================================== {{{1

=head2 $_hrData

The hashref of the current data we have built up by processing hopen files.

=cut

our $_hrData;   # the hashref of current data

sub _execute_hopen_file {       # Load and run a single hopen file {{{2

=head2 _execute_hopen_file

Execute a single hopen file, but B<do not> run the DAG.  Usage:

    _execute_hopen_file($filename[, options...])

This function takes input from L</$_hrData> unless a C<< DATA=>{...} >> option
is given.  This function updates L</$_hrData> based on the results.

Options are:

=over

=item phase

If given, force the phase to be the one specified.

=item quiet

If truthy, suppress extra output.

=item libs

If given, it must be an arrayref of directories.  Each of those will be
turned into a C<use lib> statement (see L<lib>) in the generated source.

=back

=cut

    my $fn = shift or croak 'Need a file to run';
    my %opts = @_;
    $Phase = $opts{phase} if $opts{phase};

    my $merger = Hash::Merge->new('RETAINMENT_PRECEDENT');

    # == Set up code pieces related to phase control ==

    my ($set_phase, $cannot_set_phase, $cannot_set_phase_warn);
    my $setting_phase_allowed = false;

    $set_phase = q(
        sub can_set_phase { true }
        sub set_phase {
            my $new_phase = shift or croak 'Need a phase';
            croak "Phase $new_phase is not one of the ones I know about (" .
                join(', ', @PHASES) . ')'
                    unless defined phase_idx($new_phase);
            $Build::Hopen::Phase = $new_phase;
    ) .
    ($opts{quiet} ? '' : 'say "Phase is now $new_phase";') . "}\n";

    $cannot_set_phase = q(
        sub can_set_phase { false }
        sub set_phase {
            croak "I'm sorry, but this file (``$FILENAME'') is not allowed to set the phase"
        }
    );

    $cannot_set_phase_warn = q(
        sub can_set_phase { false }
        sub set_phase {
    ) .
    ($opts{quiet} ? '' :
        q(
            warn "``$FILENAME'': Ignoring attempt to set phase";
        )
    ) . "}\n";

    my $lib_dirs = '';
    if($opts{libs}) {
        $lib_dirs .= "use lib '" .  (dir($_)->absolute =~ s/'/\\'/gr) .  "';\n"
            foreach @{$opts{libs}};
    }

    # == Make the hopen file into a package we can eval ==

    my ($friendly_name, $pkg_name, $file_text, $phase_text);

    $phase_text = q(
        use Build::Hopen::Phases ':all';
    );

    # -- Load the file

    if(ref $fn eq 'HASH') {       # it's a -e
        hlog { 'Processing', $fn->{name} };
        $file_text = $fn->{text};
        $friendly_name = $fn->{name};
        $pkg_name = 'CmdLineE' . $fn->{num};
        $phase_text .= defined($opts{phase}) ? $cannot_set_phase : $set_phase;
            # -e's can set phase unless --phase was specified

    } else {
        hlog { 'Processing', $fn };
        $file_text = File::Slurper::read_text($fn);
        $pkg_name = ($fn =~ s/[^a-zA-Z0-9]/_/gr);
        $friendly_name = $fn;

        if( isMYH($fn) and !defined($opts{phase}) ) {
            # MY.hopen.pl files can set $Phase unless --phase was given.
            $phase_text .= $set_phase;
            $setting_phase_allowed = true;

        } else {
            # For MY.hopen.pl, when --phase is set, set_phase doesn't croak.
            # If this were not the case, every second or subsequent run
            # of hopen(1) would croak if --phase were specified!
            $phase_text .= isMYH($fn) ? $cannot_set_phase_warn : $cannot_set_phase;
        }
    } #endif -e else

    $friendly_name =~ s{"}{-}g;
        # as far as I can tell, #line can't handle embedded quotes.

    # -- Build the package

    my $src = <<EOT;
{
    package __Rpkg_$pkg_name;
    use Build::Hopen::HopenFileKit "$friendly_name";

    # Other lib dirs
    $lib_dirs
    # /Other lib dirs

    # Other phase text
    $phase_text
    # /Other phase text
EOT

    # Now shadow $Phase so the hopen file can't change it without
    # really trying!  Note that we actually interpolate the current
    # phase in as a literal so that it's read-only (see perlmod).

    unless($setting_phase_allowed) {
        $src .= <<EOT;
    our \$Phase;
    local *Phase = \\"$Phase";
EOT
    }

    $src .= <<EOT;

    sub __Rsub_$pkg_name {
        my \$__R_retval = do {   # return statements in here will exit the Rsub
            __R_DO: {
#line 1 "$friendly_name"
$file_text
            } #__R_DO
        }; # do{}
EOT

    # If the file_text did not expressly return(), control will reach the
    # following block, where we get the correct return value.  If the file_text
    # ran to completion, we have a defined __R_retval.  If the file text exited
    # via Phases::on(), we have a defined __R_on_result.  If either of those
    # is defined, make sure it's not a DAG or GraphBuilder.  Those should not
    # be put into the return data.

    $src .= <<EOT;
        \$__R_retval //= \$__R_on_result;

        if(defined(\$__R_retval) && ref(\$__R_retval)) {
            die 'Hopen files may not return graphs'
                if eval { \$__R_retval->DOES('Build::Hopen::G::DAG') };
            die 'Hopen files may not return graph builders (is a ->goal or ->default_goal missing?)'
                if eval { \$__R_retval->DOES('Build::Hopen::G::GraphBuilder') };
        }

        # Otherwise, no data.
        return \$__R_retval;
    } #__Rsub_$pkg_name

    return __Rsub_$pkg_name(\$Build::Hopen::App::_hrData);
} #package
EOT

    hlog { "Source for $fn\n", $src, "\n" } 3;

    # == Run the package ==

    my $hrAddlData = eval($src);
    die "Error in $friendly_name: $@" if $@;

    hlog { 'old data', Dumper($_hrData) } 3;
    hlog { 'new data', Dumper($hrAddlData) } 2;

    # TODO? Remove all __R* hash keys from $hrAddlData unless it's a
    # MY.hopen.pl file?

    # == Merge in the data ==

    $_hrData = $merger->merge($_hrData, $hrAddlData) if $hrAddlData;
    hlog { 'data after merge', Dumper($_hrData) } 2;

} #_execute_hopen_file() }}}2

sub _run_phase {    # Run a single phase. {{{2

=head2 _run_phase

Run a phase by executing the hopen files and running the DAG.
Reads from and writes to L</$_hrData>, which must be initialized by
the caller.  Usage:

    my $hrDagOutput = _run_phase(files=>[...][, options...])

Options C<phase>, C<quiet>, and C<libs> are as L</_execute_hopen_file>.
Other options are:

=over

=item files

(Required) An arrayref of filenames to run

=item norun

(Optional) if truthy, do not run the DAG.  Note that the DAG will also not
be run if it is empty.

=back

=cut

    my %opts = @_;
    $Phase = $opts{phase} if $opts{phase};
    my $lrHopenFiles = $opts{files};
    croak 'Need files=>[...]' unless ref $lrHopenFiles eq 'ARRAY';

    # = Process the files ======================================

    foreach my $fn (@$lrHopenFiles) {
        _execute_hopen_file($fn,
            forward_opts(\%opts, qw(phase quiet libs))
        );
    } # foreach hopen file

    hlog { 'Graph is', ($Build->empty ? 'empty.' : 'not empty.'),
            ' Final data is', Dumper($_hrData) } 2;

    hlog { Data::Dumper->new([$Build], ['$Build'])->Indent(1)->Dump } 4;

    # If there is no build graph, just return the data.  This is useful
    # enough for debugging that I am making it documented behaviour.

    return $_hrData if $Build->empty or $opts{norun};

    # = Execute the resulting build graph ======================

    # Wrap the final data in a Scope
    my $env = Build::Hopen::ScopeENV->new(name => 'outermost');
    my $scope = Build::Hopen::Scope->new(name => 'from hopen files');
    $scope->adopt_hash($_hrData);

    # Run the DAG
    my $result_data = $Build->run($scope);
    return $result_data;
} #_run_phase() }}}2

sub _inner {    # Run a single invocation of hopen(1). {{{2

=head2 _inner

Do the work for one invocation of hopen(1).  Dies on failure.  Main() then
translates the die() into a print and error return.

=cut

    my %opts = @_;
    local $_hrData = {};

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

    # Start with the default phase unless one was specified.
    $Phase = $opts{PHASE} // $PHASES[0];
    die "Phase $Phase is not one of the ones I know about (" .
        join(', ', @PHASES) . ')'
            unless defined phase_idx($Phase);

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
    my $myhopen = find_myhopen($dest_dir, !!$opts{FRESH});
    my $lrHopenFiles = find_hopen_files($proj_dir, $dest_dir, !!$opts{FRESH});

    if($opts{EVAL}) {   # Add -e's to the list as hashrefs.
        my $which_e = 0;
        push @$lrHopenFiles,
            map {
                ++$which_e;
                +{text=>$_, num=>$which_e, name=>("-e #" . $which_e)}
            } @{$opts{EVAL}};
    }

    hlog { 'hopen files: ',
            map { ref eq 'HASH' ? "<<$_->{text}>>" : "``$_''" }
                ($myhopen // (), @$lrHopenFiles) } 2;

    die <<EOT unless $myhopen || @$lrHopenFiles;
I can't find any hopen project files (.hopen.pl or *.hopen.pl) for
project directory ``$proj_dir''.
EOT

    # = Initialize ==========================================================

    say "From ``$proj_dir'' into ``$dest_dir''" unless $opts{QUIET};

    # Prepare the destination directory if it doesn't exist
    File::Path::Tiny::mk($dest_dir) or die "Couldn't create $dest_dir: $!";

    # Create the initial DAG before loading anything so that the
    # generator and toolset can add initialization operations.
    $Build = hnew DAG => '__R_main';

    # Load MY.hopen.pl first so the results of the Probe phase are
    # available to the generator and toolset.
    if($myhopen) {
        _execute_hopen_file($myhopen,
            forward_opts(\%opts, {lc=>1}, qw(PHASE QUIET)),
        );  # TODO support _e_h_f libs option
    }

    # Load generator
    my ($gen, $gen_class);
    $gen_class = loadfrom($opts{GENERATOR}, 'Build::Hopen::Gen::', '');
    die "Can't find generator $opts{GENERATOR}" unless $gen_class;
    hlog { "Generator spec ``$opts{GENERATOR}'' -> using generator $gen_class" };

    $gen = "$gen_class"->new(proj_dir => $proj_dir, dest_dir => $dest_dir,
        architecture => $opts{ARCHITECTURE})
            or die "Can't initialize generator";
    $Generator = $gen;

    # Load toolset
    my $toolset_class;
    $opts{TOOLSET} //= $gen->default_toolset;
    $toolset_class = loadfrom($opts{TOOLSET},
                                    'Build::Hopen::T::', '');
    die "Can't find toolset $opts{TOOLSET}" unless $toolset_class;

    hlog { "Toolset spec ``$opts{TOOLSET}'' -> using toolset $toolset_class" };
    $Toolset = $toolset_class;

    # = Run the hopen files =================================================

    my $new_data;
    if(@$lrHopenFiles) {
        $new_data = _run_phase(
            files => [@$lrHopenFiles],
            forward_opts(\%opts, {lc=>1}, qw(PHASE QUIET))
        );      # TODO support _run_phase libs option

    } else {    # No hopen files (other than MYH) => just use the data from MYH
        $new_data = $_hrData;
    }

    # = Save state in MY.hopen.pl for the next run ==========================

    # If we get here, _run_phase succeeded.  Therefore, we can move
    # on to the next phase.
    my $new_phase = next_phase() // $Phase;

    # TODO? give the generators a way to stash information that will be
    # written at the top of MY.hopen.pl.  This way, the user may only
    # need to edit right at the top of the file, and not also at the

    my $dumper = Data::Dumper->new([$new_data], ['__R_new_data']);
    $dumper->Quotekeys(0);
    $dumper->Purity(1);
    $dumper->Maxrecurse(0);     # no limit
    $dumper->Sortkeys(true);    # For consistency between runs
    $dumper->Sparseseen(true);  # We don't use Seen()

    my $new_text = dedent [], qq(
        # @{[MYH]} generated at @{[scalar gmtime]} GMT
        # From ``@{[$proj_dir->absolute]}'' into ``@{[$dest_dir->absolute]}''

        set_phase '$new_phase';
        do {
            my @{[$dumper->Dump]}
        }
    );

    File::Slurper::write_text($dest_dir->file(MYH), $new_text);

} #_inner() }}}2

# }}}1
# === Command-line runner =============================================== {{{1

sub Main {

=head2 Main

Command-line runner.  Call as C<< Build::Hopen::App::Main(\@ARGV) >>.

=cut

    my $lrArgs = shift // [];

    # = Process options =====================================================

    my %opts;
    _parse_command_line(from => $lrArgs, into => \%opts);
    if($opts{VERBOSE}) {    # Verbosity first
        $Build::Hopen::VERBOSE += $opts{VERBOSE};

        # Under -v, keep stdout and stderr lines in order.
        use IO::Handle;
        STDOUT->autoflush;
        STDERR->autoflush;
    }

    # Don't print the source of an eval'ed hopen file unless -vvv or higher.
    # Need 3 for the "..." that Carp prints when truncating.
    $Carp::MaxEvalLen = 3 unless $Build::Hopen::VERBOSE >= 3;

    eval { _inner(%opts); };
    my $msg = $@;
    if($msg) {
        print STDERR $msg;
        return EXIT_PROC_ERR;   # eval{} so we can do this (die() exitcode = 2)
    }

    return EXIT_OK;
} #Main()

# }}}1

# no import() --- call Main() directly with its fully-qualified name

1; # End of Build::Hopen::App
__END__
# === Command-line usage documentation ================================== {{{1

=head1 OPTIONS

=over

=item -a C<architecture>

Specify the architecture.  This is an arbitrary string interpreted by the
generator or toolset.

=item -e C<Perl code>

Add the C<Perl code> as if it were a hopen file.  C<-e> files are processed
after all other hopen files, so can modify anything that has been set up
by those files.  Can be specified more than once.

=item --fresh

Start a fresh build --- ignore any C<MY.hopen.pl> file that may exist in
the destination directory.

=item --from C<project dir>

Specify the project directory.  Overrides a project directory given as a
positional argument.

=item -g C<generator>

Specify the generator.  The given C<generator> should be either a full package
name or the part after C<Build::Hopen::Gen::>.

=item -t C<toolset>

Specify the toolset.  The given C<toolset> should be either a full package
name or the part after C<Build::Hopen::T::>.

=item --to C<destination dir>

Specify the destination directory.  Overrides a destination directory given
as a positional argument.

=item --phase

Specify which phase of the process to run.  Note that this overrides whatever
is specified in any MY.hopen.pl file, so may cause unexpected results!

If C<--phase> is given, no other hopen file can set the phase, and hopen will
terminate if a file attempts to do so.

=item -q

Produce no output (quiet).  Overrides C<-v>.

=item -v

Verbose.  Specify more C<v>'s for more verbosity.  At present, C<-vv> gives
you detailed traces of the data, and C<-vvv> gives you more detailed
code tracebacks on error.

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
