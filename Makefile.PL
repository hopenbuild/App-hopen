#!perl
#<<< No perltidy
# Makefile.PL for App::hopen
use 5.014;
use strict; use warnings;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Spec;

my $VERSION_FROM = File::Spec->catfile(qw(lib App hopen.pm));
my $IS_TRIAL = check_trial();
my $secure_perl_path = get_perl_filename();
my @provides = ();

# Check if this is a TRIAL version {{{1
sub check_trial {
    TRIAL: {
        # Get the VERSION line
        open my $fd, '<', $VERSION_FROM or last TRIAL;
        my $linetext;
        while(<$fd>) {
            next unless /VERSION/;
            $linetext = $_;
            last;
        }
        close $fd;
        return !!($linetext =~ /\bTRIAL\b/);
    }
    return 0;
} #check_trial()

# }}}1
# Module metadata {{{1
eval {
    require Module::Metadata;
    @provides =
        (provides => Module::Metadata->provides(version => '2', dir => 'lib'));
        # Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
        # for suggesting Module::Metadata.
};

# }}}1
# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    return $secure_perl_path;
} # get_perl_filename()

# }}}1
# Makefile customization (MY) {{{1
{   package MY;

    # special_targets: add to .PHONY
    sub special_targets {
        my $self = shift;
        my $text = $self->SUPER::special_targets(@_);
        $text =~ s/^(\.PHONY: )/$1cover html p prettyprint tags /m;
        return $text;
    }

    # dist_core: make `dist` a :: target rather than a : target,
    # and add distcheck before dist.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\h*:[^:]/dist:: distcheck /m;

        return $text;
    } # MY::dist_core

    # Generate README.md; add uninstall target and other test targets
    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)

        # Note: pod2markdown is marked with a hyphen so that `make` can
        # succeed and generate META files even if Pod::Markdown is not yet
        # installed.

        my $make_readme_md = File::Spec->catfile(qw(support readme.pl));
        my $make_cpanfile = File::Spec->catfile(qw(support cpanfile.pl));

        # author test: kwalitee.t dies if META.yml is missing, and manifest.t
        # dies if it is present.  Oh well!
        return <<EOT;
authortest: all
\tRELEASE_TESTING=1 prove -lvj4 xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: @{[$VERSION_FROM]} Makefile.PL $make_readme_md
\t"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f md --appveyor cxw42/app-hopen --travis hopenbuild/app-hopen

README: @{[$VERSION_FROM]} Makefile.PL $make_readme_md
\t"$secure_perl_path" "$make_readme_md" -i "\$<" -o "\$@" -f text

# Update cpanfile, but if the dev dependencies aren't installed, it's OK.
cpanfile: @{[$VERSION_FROM]} Makefile.PL $make_cpanfile MYMETA.json
\t-"$secure_perl_path" "$make_cpanfile"

all :: README.md README cpanfile
dist :: README.md README cpanfile

# Uninstallation: mimic what the normal "uninstall" target does, but actually
# carry out the actions.
# Note: this may leave empty directories in place, since the packlist only
# includes files.

ACTUALLY_UNINSTALL = "$secure_perl_path" -MExtUtils::Install -e 'uninstall(shift,1)' --

actually_uninstall :: actually_uninstall_from_\$(INSTALLDIRS)dirs
\t\$(NOECHO) \$(NOOP)

actually_uninstall_from_perldirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(PERL_ARCHLIB)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_sitedirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(SITEARCHEXP)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_vendordirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(VENDORARCHEXP)/auto/\$(FULLEXT)/.packlist"

# Code-coverage testing
cover: all
\tHARNESS_OPTIONS=j4 cover -test

# HTML documentation using Pod::ProjectDocs
html: all
\tpod2projdocs -l lib -l `perldoc -lm Data::Hopen | sed 's,.Data.Hopen.pm\$\$,,'` -o html -title "The hopen build system"

# Pretty-printing and tags
prettyprint:
\t-perltidy -pro=.perltidyrc -b `grep -E '\\.(pm|pl|t)\$\$' MANIFEST`

tags:
\t-if [ -d ../Data-Hopen ]; then \\
\t\tctags -R --exclude='*.html' --exclude='html' --exclude='blib' . ../Data-Hopen ; \\
\telse \\
\t\tctags -R --exclude='*.html' --exclude='html' --exclude='blib' ; \\
\tfi

p:
\t+\$(MAKE) prettyprint
\t+\$(MAKE) tags

EOT
    } #postamble()
} #package MY

# }}}1

# Main options for EUMM
my %opts = (
    NAME             => 'App::hopen',
    AUTHOR           => q{Christopher White <cxw@cpan.org>},
    VERSION_FROM     => $VERSION_FROM,
    ABSTRACT_FROM    => $VERSION_FROM,
    LICENSE          => 'lgpl_2_1',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
        # For:
        #   - full Unicode support (this was the big one) (5.014)
        #   - string "eval" handles $@ correctly (see perldoc -f eval)
        #   - nondestructive replace (s///r) (5.014)
        #   - backtracking control verbs (5.010)
        #   - working smartmatch (5.010001)
        #   - stringifying regexes with modifiers (5.014)
        #   - FH->autoflush without needing IO::Handle (see
        #     perldoc -f select) (5.014)

    # In the following, if a specific version is listed, but no explanation
    # is given, that means we want that version for bugfixes it includes.
    # Prereqs commented out with "##" were used at one time but no longer
    # appear to be.
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
        'File::Spec' => '0',
        'strict' => '0',
        'warnings' => '0',
    },
    BUILD_REQUIRES => {
        'Getopt::Long' => '0',
        'Path::Class' => '0.37',
        'Pod::Markdown' => '0',     # pod2markdown
        'Pod::Text' => '0',         # pod2text
    },
    TEST_REQUIRES => {
        'Carp' => '0',
        'Exporter' => '0',
        'Import::Into' => '0',
        'rlib' => '0',
        'Scalar::Util' => '0',
        'Test::Directory' => '0.02',    # for subdirs
        'Test::Fatal' => '0.014',
        'Test::More' => '0',
        'Test::Spec' => '0.42',     # for context()
        # Test::TempDir::Tiny?  If so, remove Test::Directory dependency?
        'Test::UseAllModules' => '0.12',    # for _get_module_list()
        'Test::Warn' => '0.35',     # for metadata
    },
    PREREQ_PM => {
        # Other hopen packages -------------------
        'Data::Hopen' => '0.000020',    # for builder->nodes()

        # Non-hopen dependencies -----------------
        #'Algorithm::Dependency' => '1.106',
            # - Probably don't need this; we can use Graph::topological_sort().

        'Carp' => '0',

        'Class::Method::Modifiers' => '2.10',   # most recent code change
        'Class::Tiny' => '1.000',   # New API.  NOTE: <1.001 has no BUILDARGS
        #'Class::Tiny::Antlers' => '0',

        #'Class::Tiny::Chained' => '0.002',
            # - Looks like it might be handy.
            # 0.002+ because that has only core dependencies.

        'Class::Tiny::ConstrainedAccessor' => '0.000010',   # custom constraints

        ## 'Class::XPath' => '1.4',
        'Config' => '0',
        'Cwd' => '0',

        'constant' => '0',
        'Data::Dumper' => '2.154',      # For Maxrecurse
        'Data::Section::Simple' => '0.07',
        'Deep::Hash::Utils' => '0.03',  # For correct metadata
        ## 'experimental' => '0.009',      # For support on perl < 5.15.7
        'Exporter' => '0',
        'feature' => '0',
        # 'File::Find::Rule' => '0',    # - might be nice for finding files
        'File::Glob' => '0',
        #'File::Globstar' => '0.5',      # Fewer dependencies
        'File::Path::Tiny' => '0.9',
        'File::pushd' => '1.013',
        'File::Spec' => '0',
        'File::stat' => '0',
        'File::Which' => '1.22',    # for msys2 support
        'Hash::Merge' => '0.299',
        'Hash::MultiValue' => '0.12',
        #'Hash::Ordered' => '0.011',
        'Import::Into' => '0',
        'Getargs::Mixed' => '1.04', # For -undef_ok option
        'Getopt::Long' => '2.5',    # For long option bugfix
        'Graph' => '0.9704',        # For latest multiedged support
        'List::Flatten::Recursive' => '0.210100',   # for exporter that works
            # NOTE: 0.103460 is the latest version on CPAN.  Install from
            # https://github.com/DarwinAwardWinner/List-Flatten-Recursive/pull/2
            # or https://github.com/cxw42/List-Flatten-Recursive/releases/download/0.210100/List-Flatten-Recursive-0.210100.tar.gz
        'List::MoreUtils' => '0.428',

        # 'Module::Find' => '0.12', # For bugfixes
                                    # - Use for finding plugins to load.
                                    # - May also need Module::Runtime.
                                    # - Alternative is Module::Pluggable,
                                    #   but that appears to have more test
                                    #   failures.

        # 'Number::Compare' => '0', # - looks cool

        'overload' => '0',

        'Package::Alias' => '0.12',

        # 'Parse::RecDescent' => '1.967015',
            # - Use for parsing Lua tables as inline config data?
            #   I am thinking about using this for specifying flavors at
            #   build time.  E.g., `--flavor debug=1,["+"]=42`.
            # - Syntax at https://www.lua.org/pil/3.6.html .
            # - See https://www.perlmonks.org/?node_id=462581 for operator
            #   precedence in P::RD grammars.

        'Path::Class' => '0.37',
        'PerlX::Maybe' => '1.200',  # for latest API as of writing
        'Pod::Usage' => '0',
        # 'Probe::Perl' => '0', # For perl interpreter file location or other info.
                                # Alternative: Padre::Perl

        #'Quote::Code' => '1.01',   # very cool, but non-PP, and perltidy barfs on it
        #'Role::Tiny' => '1.000000',

        'Scalar::Util' => '0',
        'Set::Scalar' => '1.27',    # For correct metadata
        ## 'Storable' => '3.06',
            # So it can handle REGEXP -
            # https://rt.perl.org/Public/Bug/Display.html?id=50608

        'String::Print' => '0.92',
        ## 'Sub::ScopeFinalizer' => '0.02',        # For correct META.yml

        'strict' => '0',
        #'Syntax::Construct' => '0.07',
        'Text::MicroTemplate' => '0.23',
        'Tie::RefHash' => '0',
        'Type::Tiny' => '1.004004',

        'vars::i' => '1.06',
        'warnings' => '0',
        'XML::FromPerl' => '0',
        'XML::LibXML' => '1.60',            # for getElementById()
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            bugtracker => {
                web  => 'https://github.com/hopenbuild/App-hopen/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/hopenbuild/App-hopen.git',
                web  => 'https://github.com/hopenbuild/App-hopen',
            },
        },

        prereqs => {
            build => {
                recommends => {
                    'Pod::ProjectDocs' => '0.52',   # latest as of writing
                },
            },

            develop => {
                requires => {
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'CPAN::Meta' => '0',
                    'Devel::Cover' => '0',
                    'File::Slurp' => '9999.26',
                    'Module::CPANfile' => '0.9020', # for from_prereqs()
                    'Module::Metadata' => '1.000016',
                    'Test::Kwalitee' => '0',
                },
            },
        },

        @provides,

    }, #META_MERGE

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-hopen-*' },
); # %opts

if($IS_TRIAL) {
    print STDERR "TRIAL version\n";
    $opts{META_MERGE}->{release_status} = 'testing';
    $opts{DISTVNAME} = '$(DISTNAME)-$(VERSION)-TRIAL';
}

# Some tests run on older versions of EUMM that do not support TEST_REQUIRES.
# This is a workaround, modified from
# https://metacpan.org/source/RJBS/JSON-Typist-0.005/Makefile.PL ,
# linked from http://blogs.perl.org/users/neilb/2017/05/specifying-dependencies-for-your-cpan-distribution.html .
# If we are on a version of EUMM that doesn't support TEST_REQUIRES,
# move those dependencies to PREREQ_PM.
unless( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    $opts{PREREQ_PM}->{$_} = $opts{TEST_REQUIRES}->{$_}
        foreach keys %{$opts{TEST_REQUIRES}};
    delete $opts{TEST_REQUIRES};
}

WriteMakefile(%opts);
# vi: set fdm=marker fdl=0: #
