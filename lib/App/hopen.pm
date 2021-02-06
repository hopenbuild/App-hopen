# App::hopen: Implementation of the hopen(1) program
package App::hopen;
our $VERSION = '0.000013'; # TRIAL

# Imports {{{1
use strict; use warnings;
use Data::Hopen::Base 0.000020;

use App::hopen::AppUtil ':all';
use App::hopen::BuildSystemGlobals;
use App::hopen::G::Goal ();
use App::hopen::MYhopen;
use App::hopen::Util qw(isMYH MYH);
use App::hopen::Util::String qw(line_mark_string);
use Data::Hopen qw(:default loadfrom *VERBOSE *QUIET);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Scope::Environment;
use Data::Hopen::Util::Data qw(dedent forward_opts);
use Data::Dumper;
use File::Path::Tiny;
use File::stat ();
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt);
use Hash::Merge;
use Path::Class;
use Scalar::Util qw(looks_like_number);

# }}}1

use Class::Tiny {
    argv => sub { [] },
    cmdopts => sub { +{} },
    did_set_phase => sub { false },
    hrData => sub { +{} },
};

BEGIN { $Data::Dumper::Indent = 1; }    # DEBUG

# Documentation {{{1
# README is this file's POD

=pod

=encoding UTF-8

=head1 NAME

App::hopen - Graph-driven cross-platform build system

=head1 CURRENT STATUS

Most features are not yet implemented ;) .  However it will generate a
C<Makefile> or C<build.ninja> file for a C C<Hello, World> program at this
point!  It can generate command lines for gcc(1) or for Microsoft's C<cl.exe>.

=head1 INTRODUCTION

hopen is a cross-platform software build generator.  It makes files you can
pass to Make, Ninja, Visual Studio, or other build tools, to compile and
link your software.  hopen gives you:

=over

=item *

A full, Turing-complete, robust programming language to write your
build scripts (specifically, Perl 5.14+)

=item *

No hidden magic!  All your data is visible and accessible in a build graph
(whence "graph-driven").

=item *

Context-sensitivity.  Your users can tweak their own builds for their own
platforms without affecting your project.

=back

See L<App::hopen::Manual> for details of the input format.

Why Perl?  Because (1) you probably already have it installed, and
(2) it is the original write-once, run-everywhere language!

=head2 Example

Create a file C<.hopen.pl> in your source tree.  Then:

    $ hopen
    From ``.'' into ``built''
    Running Check phase

Now C<built/MY.hopen.pl> has been created, and loaded with information about
your configuration.  You can edit that file if you want to change what will
happen next.

    $ hopen
    From ``.'' into ``built''
    Running Gen phase

Now C<built/Makefile> has been created.

    $ hopen
    From ``.'' into ``built''
    Running Build phase
    Building in foo/built...
    <make(1) output>

And your software is ready to go!  C<make> has been run in C<built/>,
with output left in C<built/>.

See L<App::hopen::Manual> for information on writing C<.hopen.pl> files.

=head1 SYNOPSIS

    hopen [options] [--] [destination dir [project dir]]

If no project directory is specified, the current directory is used.

If no destination directory is specified, C<< <project dir>/built >> is used.

See L<App::hopen::Manual> for more details.

=head1 OPTIONS

=over

=item -a C<architecture>

Specify the architecture.  This is an arbitrary string interpreted by the
generator or toolset.

=item --build

Run the generator to process the blueprint files.  Cannot be used
with C<--fresh>.

=item -e C<Perl code>

Add the C<Perl code> as if it were a hopen file.  C<-e> files are processed
after all other hopen files, so can modify anything that has been set up
by those files.  Can be specified more than once.

=item --fresh

Start a fresh build --- ignore any C<MY.hopen.pl> file that may exist in
the destination directory.  Cannot be used with C<--build>.

Note that this B<does not> completely delete the build directory and
start over.

=item --from C<project dir>

Specify the project directory.  Overrides a project directory given as a
positional argument.

=item -g C<generator> (or -G)

Specify the generator.  The given C<generator> should be either a full package
name or the part after C<App::hopen::Gen::>.  Also accepts C<-G> to ease
the transition from cmake.

=item -t C<toolset> (or -T)

Specify the toolset.  The given C<toolset> should be either a full package
name or the part after C<App::hopen::T::>.  Also accepts C<-T> to ease
the transition from cmake.

=item --to C<destination dir>

Specify the destination directory.  Overrides a destination directory given
as a positional argument.

=item --phase C<phase>

Specify which phase of the process to run.  Note that this overrides whatever
is specified in any MY.hopen.pl file, so may cause unexpected results!

If C<--phase> is given, no other hopen file can set the phase, and hopen will
terminate if a file attempts to do so.

=item -q

Produce no output (quiet).  Overrides C<-v>.

=item -v, --verbose=n

Verbose.  Specify more C<v>'s for more verbosity.  At present, C<-vv>
(equivalently, C<--verbose=2>) gives
you detailed traces of the data, and C<-vvv> gives you more detailed
code tracebacks on error.

=item --version

Print the version of hopen and exit

=back

=head1 INTERNALS

After the C<hopen> file is processed, cycles are detected and reported as
errors.  *(TODO change this to support LaTeX multi-run files?)*  Then the DAG
is traversed, and each operation writes the necessary information to the
file being generated.

=head1 INTERNAL DATA

=head2 Instance member variables

=head3 argv

Arrayref of the command-line parameters, or C<[]>.

=head3 cmdopts

Hashref of the parsed command-line options, or C<{}>.

=head3 did_set_phase

Set to truthy if MY.hopen.pl sets the phase.

=head3 hrData

The hashref of the current data we have built up by processing hopen files.

=cut

# }}}1
# Constants {{{1

use constant DEBUG          => false;

# Shell exit codes
use constant EXIT_OK        => 0;   # success
use constant EXIT_PROC_ERR  => 1;   # error during processing
use constant EXIT_PARAM_ERR => 2;   # couldn't understand the command line

# }}}1
# Globals (ick) {{{1

=head2 C<$RUNNING>

Set truthy when a hopen run is in progress.  This is so modules don't have
to C<die()> if they are being run under C<perl -c>, for example.

TODO replace this with a package parameter --- see
L<App::hopen::HopenFileKit/_language_import>.

=cut

our $RUNNING;

=head2 C<$_hf_pkg_idx>

Used to give each hopen file or C<-e> a unique package name.

=cut

my $_hf_pkg_idx = 0;    # unique ID for the packages of hopen files

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

    BUILD => ['build'],     # If specified, jump ahead to the last phase, and
                            # run the build tool indicated by the generator.

    # TODO CHECK => ['c']   # Like `perl -c`, but for hopen files

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
        # TODO? add an option to pass parameters to the generator?
        # E.g., which make(1) to use?  Or maybe that should be part of the
        # ARCHITECTURE string.

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
    VERBOSE2 => ['verbose',':s'],   # --verbose=<n>
    # -? reserved

);

=head1 INTERNAL FUNCTIONS

=cut

sub _parse_command_line { # {{{2

=head2 _parse_command_line

Usage: C<< $self->_parse_command_line; >>.  Fills in L</cmdopts> with the
values from L</argv>, keyed by the keys in L</%CMDLINE_OPTS>.

=cut

    #local @_Sources;

    my $self = shift or croak "Need an instance";
    my $hrOptsOut = $self->cmdopts;

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
        $self->argv,                    # source array
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

        # --man: suppress "INTERNAL" sections.  Note that this does
        # get rid of the automatic pager we would otherwise get
        # by virtue of pod2usage's invoking perldoc(1).  Oh well.

        Pod::Usage::pod2usage(
            -exitval => EXIT_OK, @in,   # VVV see Pod::Select for format
            -verbose => 99, -sections => '!INTERNAL.*'
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
    $hrOptsOut->{DEST_DIR} //= $self->argv->[0] if @{$self->argv};
    $hrOptsOut->{PROJ_DIR} //= $self->argv->[1] if @{$self->argv}>1;

    # Sanity check VERBOSE2, and give it a default of 0
    my $v2 = $hrOptsOut->{VERBOSE2} // 0;
    $v2 = 1 if $v2 eq '';   # --verbose without value === --verbose=1
    die "--verbose requires a positive numeric argument"
        if (defined $v2) && ( !looks_like_number($v2) || (int($v2) < 0) );
    $hrOptsOut->{VERBOSE2} = int($v2 // 0);

} #_parse_command_line() }}}2

# }}}1
# === Main worker code ================================================== {{{1

sub _execute_hopen_file {       # Load and run a single hopen file {{{2

=head2 _execute_hopen_file

Execute a single hopen file, but B<do not> run the DAG.  Usage:

    $instance->_execute_hopen_file($filename[, options...])

This function takes input from L</hrData> unless a C<< DATA=>{...} >> option
is given.  This function updates L</hrData> based on the results.

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

    my $self = shift or croak "Need an instance";
    my $fn = shift or croak 'Need a file to run';
    my %opts = @_;
    $Phase = PHASES->check($opts{phase}) if $opts{phase};
    croak "I don't know phase $opts{phase}" unless $Phase;

    my $merger = Hash::Merge->new('RETAINMENT_PRECEDENT');

    # == Set up code pieces related to phase control ==
    # TODO move these to HopenFileKit

    my ($set_phase, $cannot_set_phase, $cannot_set_phase_warn);
    my $setting_phase_allowed = false;

    # Note: all phase-setting functions succeed if there was nothing
    # for them to do!

    $set_phase = q(
        sub _mark_phase_as_set;
        sub can_set_phase { true }
        sub set_phase {
            my $new_phase = shift or croak 'Need a phase';
            return if PHASES->is($new_phase, $App::hopen::BuildSystemGlobals::Phase);
            $new_phase = PHASES->check($new_phase);
            croak "Phase $new_phase is not one of the ones I know about (" .
                join(', ', PHASES->all) . ')'
                    unless $new_phase;
            $App::hopen::BuildSystemGlobals::Phase = $new_phase;
            _mark_phase_as_set;
    ) .
    ($opts{quiet} ? '' : 'say "Running $new_phase phase";') . "}\n";

    $cannot_set_phase = q(
        sub can_set_phase { false }
        sub set_phase {
            my $new_phase = shift // '';
            return if PHASES->is($new_phase, $App::hopen::BuildSystemGlobals::Phase);
            croak "I'm sorry, but this file (``$FILENAME'') is not allowed to set the phase"
        }
    );

    $cannot_set_phase_warn = q(
        sub can_set_phase { false }
        sub set_phase {
            my $new_phase = shift // '';
            return if PHASES->is($new_phase, $App::hopen::BuildSystemGlobals::Phase);
    ) .
    ($opts{quiet} ? '' :
        q(
            warn "``$FILENAME'': Ignoring attempt to set phase $new_phase, " .
                "since phase $App::hopen::BuildSystemGlobals::Phase was " .
                "given on the command line\n";
        )
    ) . "}\n";

    my $lib_dirs = '';
    if($opts{libs}) {
        $lib_dirs .= "use lib '" .  (dir($_)->absolute =~ s/'/\\'/gr) .  "';\n"
            foreach @{$opts{libs}};
    }

    # == Make the hopen file into a package we can eval ==

    my ($friendly_name, $pkg_stem, $file_text, $phase_text);

    $phase_text = '';

    # -- Load the file

    if(ref $fn eq 'HASH') {       # it's a -e
        hlog { 'Processing', $fn->{name} };
        $file_text = $fn->{text};
        $friendly_name = $fn->{name};
        $pkg_stem = 'CmdLineE' . $fn->{num} . '_' . $_hf_pkg_idx++;
        $phase_text .= defined($opts{phase}) ? $cannot_set_phase : $set_phase;
            # -e's can set phase unless --phase was specified

    } else {
        hlog { 'Processing', $fn };
        $file_text = file($fn)->slurp;
        $pkg_stem = ($fn =~ s/[^a-zA-Z0-9]/_/gr) . '_' . $_hf_pkg_idx++;
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
            # TODO? permit regular hopen files to set the the phase if
            # neither MYH nor the command line did, and we're at the first
            # phase.  This is so the hopen file can say `set_phase 'Gen';`
            # if there's nothing to do during Check.
        }
    } #endif -e else

    $friendly_name =~ s{"}{-}g;
        # as far as I can tell, #line can't handle embedded quotes.

    my $pkg_name = "__Rpkg_$pkg_stem";
    my $sub_name = "__Rsub_$pkg_stem";
    my $instance_name = "$pkg_name\::__R_instance";

    # Give the package access to the instance
    do { no strict 'refs'; ${$instance_name} = $self };

    # -- Build the package

    # TODO move phase-setting to App::hopen::MYhopen
    # TODO set $App::hopen::MYhopen::IsMYH to indicate whether or not this
    # file is MY.hopen.pl.
    my $src = line_mark_string <<EOT ;
{
    package $pkg_name;
    our \$@{[App::hopen::AppUtil::HOPEN_FILE_FLAG]};    # A::h::HopenFileKit/import()
    use App::hopen::HopenFileKit "\Q$friendly_name\E";
EOT
        # \\Q and \\E since, on Windows, \$friendly_name is likely to
        # include backslashes.
        # TODO test if this gets double-backslashed.

    $src .= line_mark_string <<EOT ;

    # Other lib dirs
    $lib_dirs
    # /Other lib dirs

    sub _mark_phase_as_set { \$$instance_name\->did_set_phase(true) }

    # Other phase text
    $phase_text
    # /Other phase text
EOT

    # Now shadow $Phase so the hopen file can't change it without
    # really trying!  Note that we actually interpolate the current
    # phase in as a literal so that it's read-only (see perlmod).

    unless($setting_phase_allowed) {
        $src .= line_mark_string <<EOT;
    our \$Phase;
    local *Phase = \\"$Phase";
EOT
    }

    # Run the code given in the hopen file.  Wrap it in a named BLOCK so that
    # HopenFileKit::on() will work, but don't rely on the return value of that
    # BLOCK (per perlsyn).

    $src .= line_mark_string <<EOT;

    sub $sub_name {
        my \$__R_retval;
        __R_DO: {
            \$__R_retval = do {   # return statements in here will exit the Rsub
#line 1 "$friendly_name"
$file_text
            }; # do{}
        } #__R_DO
EOT

    # If the file_text did not expressly return(), control will reach the
    # following block, where we get the correct return value.  If the file_text
    # ran to completion, we have a defined __R_retval.  If the file text exited
    # via HopenFileKit::on(), we have a defined __R_on_result.  If either of those
    # is defined, make sure it's not a DAG or GraphBuilder.  Those should not
    # be put into the return data.
    #
    # Also, any defined, non-hash value is ignored, so that we don't
    # wind up with lots of hashes like { 1 => 1 }.
    #
    # If the file_text did expressly return(), whatever it returned will
    # be used as-is.  Like perlref says, we are not totalitarians.

    $src .= line_mark_string <<EOT;
        \$__R_retval //= \$__R_on_result;

        ## hlog { '$pkg_name retval before checks',
        ##        ref \$__R_retval, Dumper \$__R_retval} 3;

        if(defined(\$__R_retval) && ref(\$__R_retval)) {
            die 'Hopen files may not return graphs'
                if eval { \$__R_retval->DOES('Data::Hopen::G::DAG') };
            die 'Hopen files may not return graph builders (is a ->goal or ->default_goal missing?)'
                if eval { \$__R_retval->DOES('Data::Hopen::G::GraphBuilder') };

        }

        if(defined(\$__R_retval) and ref \$__R_retval ne 'HASH') {
            warn ('Hopen files must return hashrefs; ignoring ' .
                    lc(ref(\$__R_retval) || 'scalar')) unless \$QUIET;
            \$__R_retval = undef;
        }

        return \$__R_retval;
    } #$sub_name

    our \$hrNewData = $sub_name(\$$instance_name\->hrData);
} #package
EOT
        # Put the result in a package variable because that way I don't have
        # to remember the rules for the return value of eval().

    hlog { "Source for $fn\n", $src, "\n" } 3;

    # == Run the package ==

    eval($src);
    die "Error in $friendly_name: $@" if $@;

    # Get the data from the package we just ran
    my $hrAddlData = eval {
        no strict 'refs';
        ${ "$pkg_name\::hrNewData" }
    };
    die "Could not get output data from $friendly_name: $@" if $@;

    hlog { 'old data', Dumper($self->hrData) } 3;
    hlog { 'new data', Dumper($hrAddlData) } 2;

    # TODO? Remove all __R* hash keys from $hrAddlData unless it's a
    # MY.hopen.pl file?

    # == Merge in the data ==

    $self->hrData($merger->merge($self->hrData, $hrAddlData)) if $hrAddlData;
    hlog { 'data after merge', Dumper($self->hrData) } 2;

} #_execute_hopen_file() }}}2

sub _run_phase {    # Run a single phase. {{{2

=head2 _run_phase

Run a phase by executing the hopen files and running the DAG.
Reads from and writes to L</hrData>, which must be initialized by
the caller.  Usage:

    my $hrDagOutput = $instance->_run_phase(files=>[...][, options...])

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

    my $self = shift or croak "Need an instance";
    my %opts = @_;
    if($opts{phase}) {
        my $p = PHASES->check($opts{phase});
        $Phase = $p if $p;
    }
    my $lrHopenFiles = $opts{files};
    croak 'Need files=>[...]' unless ref $lrHopenFiles eq 'ARRAY';
    hlog { Phase => $Phase, Running => ('[' . join(', ', @$lrHopenFiles) . ']') };

    # = Process the files ======================================

    foreach my $fn (@$lrHopenFiles) {
        $self->_execute_hopen_file($fn,
            forward_opts(\%opts, qw(phase quiet libs))
        );
    } # foreach hopen file

    hlog { 'Graph is', ($Build->empty ? 'empty.' : 'not empty.'),
            ' Final data is', Dumper($self->hrData) } 2;

    hlog { 'Build graph', '' . $Build->_graph } 5;
    hlog { Data::Dumper->new([$Build], ['$Build'])->Indent(1)->Dump } 9;

    # If there is no build graph, just return the data.  This is useful
    # enough for debugging that I am making it documented behaviour.

    return $self->hrData if $Build->empty or $opts{norun};

    # = Execute the resulting build graph ======================

    # Wrap the final data in a Scope
    my $env = Data::Hopen::Scope::Environment->new(name => 'outermost');
    my $scope = Data::Hopen::Scope::Hash->new(name => 'from hopen files');
    $scope->adopt_hash($self->hrData);

    # Load hopen-owned variables
    $scope->put(KEY_PHASE, $Phase);
    $scope->put(KEY_GENERATOR_CLASS, ref $Generator);
    $scope->put(KEY_TOOLSET_CLASS, $Toolset);

    $scope->outer($env);    # make the environment accessible...
    $scope->local(true);    # ... but not copied by local-scope calls.

    # Run the DAG
    my $result_data = $Build->run(-context => $scope,
                                    -visitor => $Generator);
    hlog { Data::Dumper->new([$result_data], ['Build graph result data'])->Indent(1)->Dump } 2;
    return $result_data;
} #_run_phase() }}}2

sub _inner {    # Run a single invocation of hopen(1). {{{2

=head2 _inner

Do the work for one invocation of hopen(1).  Dies on failure.  L</Main> then
translates the die() into a print and error return.

Usage: C<< $instance->_inner; >>.

The return value of _inner is unspecified and ignored.

=cut

    my $self = shift or croak "Need an instance";

    $self->hrData({});

    # TODO FIXME.  This is a bit of a hack: Reset global variables on --fresh.
    # Instead, App::hopen should be a class, and each instance should have its
    # own data (I think).
    if($self->cmdopts->{FRESH}) {
        $self->did_set_phase(false);
    }

    if($self->cmdopts->{PRINT_VERSION}) {  # print version, raw and dotted
        if($App::hopen::VERSION =~ m<^([^\.]+)\.(\d{3})(\d{3})>) {
            printf "hopen version %d.%d.%d ($App::hopen::VERSION)\n", $1, $2, $3;
        } else {
            say "hopen $VERSION";
        }
        say "App::hopen in: $INC{'App/hopen.pm'}" if $VERBOSE >= 1;
        return;
    }

    # = Initialize phase ====================================================

    if($self->cmdopts->{BUILD} && $self->cmdopts->{PHASE} &&
            !PHASES->is($self->cmdopts->{PHASE}, 'build')) {
        die '--phase ' . $self->cmdopts->{PHASE} . ' and --build are mutually exclusive';
    }

    $self->cmdopts->{PHASE} = PHASES->enforce('build') if $self->cmdopts->{BUILD};

    # Start with the default phase unless one was specified.
    $Phase = $self->cmdopts->{PHASE} // PHASES->first;
    die "Phase $Phase is not one of the ones I know about (" .
        join(', ', PHASES->all) . ')'
            unless PHASES->check($Phase);

    # = Initialize filesystem-related build-system globals ==================

    # Get the project dir (default = cwd)
    my $proj_dir = $self->cmdopts->{PROJ_DIR} ? dir($self->cmdopts->{PROJ_DIR}) : dir;
    $ProjDir = $proj_dir;

    # Get the destination dir
    my $dest_dir;
    if($self->cmdopts->{DEST_DIR}) {
        $dest_dir = dir($self->cmdopts->{DEST_DIR});
    } else {
        $dest_dir = $proj_dir->subdir('built');
    }
    $DestDir = $dest_dir;

    # Prohibit in-source builds
    die <<EOT if $proj_dir eq $dest_dir;
I'm sorry, but I don't support in-source builds (dir ``$proj_dir'').  Please
specify a different project directory (--from) or destination directory (--to).
EOT

    # Prohibit builds if there's a MY.hopen.pl file in the project directory,
    # since those are the marker of a destination directory.
    if(-e $proj_dir->file(MYH)) { die <<EOT; }
I'm sorry, but project directory ``$proj_dir'' appears to actually be a
build directory --- it has a @{[MYH]} file.  If you really want to build
here, remove or rename @{[MYH]} and run me again.
EOT

    # See if we have hopen files associated with the project dir
    my $myhopen = find_myhopen($dest_dir, !!$self->cmdopts->{FRESH});
    my $lrHopenFiles = find_hopen_files($proj_dir, $dest_dir, !!$self->cmdopts->{FRESH});

    # Check the mtimes - we don't use MYH if another hopen file is newer.
    if($myhopen && -e $myhopen) {
        my $myhstat = file($myhopen)->stat;

        foreach my $fn (@$lrHopenFiles) {
            my $stat = file($fn)->stat;

            if( $stat->mtime > $myhstat->mtime ||
                $stat->ctime > $myhstat->ctime)
            {
                say "Skipping out-of-date ``$myhopen''" unless $QUIET;
                $myhopen = undef;
                last;
            }
        } #foreach hopen file
    } #if MYH exists

    # Add -e's to the list of hopen files
    if($self->cmdopts->{EVAL}) {
        my $which_e = 0;
        push @$lrHopenFiles,
            map {
                ++$which_e;
                +{text=>$_, num=>$which_e, name=>("-e #" . $which_e)}
            } @{$self->cmdopts->{EVAL}};
    }

    hlog { 'hopen files: ',
            map { ref eq 'HASH' ? "<<$_->{text}>>" : "``$_''" }
                ($myhopen // (), @$lrHopenFiles) } 2;

    # Can't proceed if the only hopen file is $myhopen.
    unless(@$lrHopenFiles) { die <<EOT; }
I can't find any hopen project files (.hopen.pl or *.hopen.pl) for
project directory ``$proj_dir''.
EOT

    # Prepare the destination directory if it doesn't exist
    File::Path::Tiny::mk($dest_dir) or die "Couldn't create $dest_dir: $!";

    # Create the initial DAG before loading anything so that the
    # generator and toolset can add initialization operations.
    $Build = hnew DAG => '__R_main', goal_class => 'App::hopen::G::Goal';

    # = Load generator and toolset (and run MYH) ============================

    say "From ``$proj_dir'' into ``$dest_dir''" unless $QUIET;

    # Load MY.hopen.pl first so the results of the Check phase are
    # available to the generator and toolset.
    if($myhopen) {
        $self->_execute_hopen_file($myhopen,
            forward_opts($self->cmdopts, {lc=>1}, qw(PHASE QUIET)),
        );  # TODO support _e_h_f libs option
    }

    # Tell the user the initial phase if MY.hopen.pl didn't change it
    say "Running $Phase phase" unless $self->did_set_phase or $QUIET;

    # Load generator
    {
        my ($gen, $gen_class);
        $gen_class = loadfrom($self->cmdopts->{GENERATOR}, 'App::hopen::Gen::', '');
        die "Can't find generator $self->cmdopts->{GENERATOR}" unless $gen_class;
        hlog { "Generator spec ``" . $self->cmdopts->{GENERATOR} .
                "'' -> using generator $gen_class" };

        $gen = "$gen_class"->new(proj_dir => $proj_dir, dest_dir => $dest_dir,
            architecture => $self->cmdopts->{ARCHITECTURE})
                or die "Can't initialize generator";
        $Generator = $gen;
    }

    # Load toolset
    {
        my $toolset_class;
        $self->cmdopts->{TOOLSET} //= $Generator->_default_toolset;
        $toolset_class = loadfrom($self->cmdopts->{TOOLSET},
                                        'App::hopen::T::', '');
        die "Can't find toolset $self->cmdopts->{TOOLSET}" unless $toolset_class;

        hlog { "Toolset spec ``" . $self->cmdopts->{TOOLSET} .
                "'' -> using toolset $toolset_class" };
        $Toolset = $toolset_class;
    }

    # Handle Build phase, now that myh is loaded ----------------
    if(PHASES->is($Phase, 'build')) {
        $Generator->run_build();
        return;
    }

    # = Run the hopen files (except MYH, already run) =======================

    my $new_data;
    if(@$lrHopenFiles) {
        $new_data = $self->_run_phase(
            files => [@$lrHopenFiles],
            forward_opts($self->cmdopts, {lc=>1}, qw(PHASE QUIET))
        );      # TODO support _run_phase libs option

    } else {    # No hopen files (other than MYH) => just use the data from MYH
        $new_data = $self->hrData;
    }

    $Generator->_finalize(-phase => $Phase, -graph => $Build,
        -data => $new_data);
        # TODO RESUME HERE - figure out how the generator works into this.

    # = Save state in MY.hopen.pl for the next run ==========================

    # If we get here, _run_phase succeeded.  Therefore, we can move
    # on to the next phase.  Stay in the last phase if there is no next phase.
    my $new_phase = PHASES->next($Phase) || $Phase;

    # TODO? give the generators a way to stash information that will be
    # written at the top of MY.hopen.pl.  This way, the user may only
    # need to edit right at the top of the file, and not also throughout
    # the hashref.

    # TODO RESUME HERE
    # - Find any thunks in $new_data
    # - List them as variables first in the Dumper ctor call
    # - Add code after the dump to replace all those thunks with their
    #   get() values.

    # TODO figure out how to carry the config forward from run to run.

    my $config = extract_thunks($new_data);
    my $VAR = '__R_new_data';
    my $dumper = Data::Dumper->new([$config, $new_data], ['Configuration', $VAR]);
    $dumper->Pad(' ' x 12);     # To line up with the do{}
    $dumper->Indent(1);         # fixed indent size
    $dumper->Quotekeys(0);
    $dumper->Purity(1);
    $dumper->Maxrecurse(0);     # no limit
    $dumper->Sortkeys(true);    # For consistency between runs
    $dumper->Sparseseen(true);  # We don't use Seen()

    # Four-space indent instead of two-space.  This is using an undocumented
    # feature of Data::Dumper, whence the eval{}.
    eval { $dumper->{xpad} = ' ' x 4 };

    my $dumped = $dumper->Dump;
    my $separ = '### Do not change below this line ' . ('#' x 45);
    $dumped =~ s{^(\h*)(\$__R_new_data\h*=)}{\n$1$separ\n\n$1$2}m;

    my $new_text = dedent [], qq(
        # ==================================================================
        # @{[MYH]} generated at @{[scalar gmtime]} GMT
        # From ``@{[$proj_dir->absolute]}'' into ``@{[$dest_dir->absolute]}''

        set_phase '$new_phase';
        do {
            my (\$Configuration, \$$VAR);
$dumped
            dethunk(\$$VAR);
            \$$VAR
        }
    );

    # Notes on the above $new_text:
    # - No semi after the Dump line --- Dump adds it automatically.
    # - Dump() may produce multiple statements, so add the
    #   express $__R_new_data at the end so the do{} will have a
    #   consistent return value.
    # - The Dump() line is not indented because it does its own indentation.

    $dest_dir->file(MYH)->spew($new_text);

} #_inner() }}}2

# }}}1
# === Command-line runner =============================================== {{{1

sub Main {

=head2 Main

Command-line runner.  Call as C<< App::hopen->Main(\@ARGV) >>.
Constructs a new instance and delegates to L</run>.

=cut

    my $class = shift;
    die "Call as a class method" if ref $class;

    my $lrArgs = shift // [];

    my $self = $class->new(argv => $lrArgs);
    return $self->run;
} #Main()

sub run {

=head2 run

Run hopen.  Usage: C<< $instance->run; >>.  Returns a shell exit code,
or dies.

=cut

    my $self = shift;

    # = Process options ================================================= {{{2

    $self->_parse_command_line;

    # Check for mutually-inconsistent options
    if($self->cmdopts->{FRESH} && $self->cmdopts->{BUILD}) {
        print STDERR '--fresh and --build cannot be used together';
        return EXIT_PARAM_ERR;
    }

    # Verbosity is the max of -v and --verbose
    $self->cmdopts->{VERBOSE} = $self->cmdopts->{VERBOSE2}
        if $self->cmdopts->{VERBOSE2} > $self->cmdopts->{VERBOSE};

    # Option overrides: -q beats -v
    $self->cmdopts->{VERBOSE} = 0 if $self->cmdopts->{QUIET};
    $QUIET = !!($self->cmdopts->{QUIET} // false);
    delete $self->cmdopts->{QUIET};
        # After this, code only refers to $QUIET for consistency.

    # Implement verbosity
    if(!$QUIET && $self->cmdopts->{VERBOSE}) {
        $VERBOSE += $self->cmdopts->{VERBOSE};
        #hlog { Verbosity => $VERBOSE };

        # Under -v, keep stdout and stderr lines in order.
        STDOUT->autoflush(true);
        STDERR->autoflush(true);
    }

    delete @{$self->cmdopts}{qw(VERBOSE VERBOSE2)};
        # After this, code only refers to $VERBOSE for consistency.

    # Don't print the source of an eval'ed hopen file unless -vvv or higher.
    # Need 3 for the "..." that Carp prints when truncating.
    $Carp::MaxEvalLen = 3 unless $VERBOSE >= 3;

    # }}}2
    # = Do it, Rockapella! ==================================================

    $RUNNING = true;
    eval { $self->_inner; };
    my $msg = $@;
    $RUNNING = false;

    if($msg) {
        print STDERR $msg;
        return EXIT_PROC_ERR;   # eval{} is so we can do this (die() exitcode = 2)
    }

    return EXIT_OK;
} #run()

# }}}1

# no import() --- call Main() directly with its fully-qualified name

1;
__END__
# === Rest of the documentation ========================================= {{{1

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::hopen                      For command-line options
    perldoc App::hopen::Manual         For terminology and workflow
    perldoc Data::Hopen                     For the underlying engine

You can also look for information at:

=over

=item * GitHub: The project's main repository and issue tracker

L<https://github.com/hopenbuild/App-hopen>

=item * MetaCPAN

L<https://metacpan.org/pod/App::hopen>

=item * This distribution

See the C<eg/> directory distributed with this software for examples.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018--2020 Christopher White.  All rights reserved.

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
