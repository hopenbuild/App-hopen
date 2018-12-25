use 5.014;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Spec;

my $VERSION_FROM = File::Spec->catfile(qw(lib Build Hopen.pm));
my $IS_TRIAL = check_trial();

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
my $provides;
eval {
    require Module::Metadata;
    $provides = Module::Metadata->provides(version => '2', dir => 'lib');
        # Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
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
} # get_perl_filename() }}}1

my $secure_perl_path = get_perl_filename();

# Makefile customization (MY) {{{1
{   package MY;

    # dist_core: make `dist` a :: target rather than a : target,
    # and add -TRIAL if necessary.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\s*:[^:]/dist:: /m;

        # Add -TRIAL if it's a trial release
        if($IS_TRIAL) {
            # Note: we don't have to worry about EOL; Appveyor uses gmake even
            # on Windows, and it only uses \n.
            print STDERR "TRIAL version\n";
            my $newtext .=  # Command to rename the tgz
                "\t$secure_perl_path -MExtUtils::Command -e mv -- " .
                "\"\$(DISTVNAME).tar\$(SUFFIX)\" " .
                "\"\$(DISTVNAME)-TRIAL.tar\$(SUFFIX)\"\n";

            # Insert $newtext at the end of the `dist` target
            $text =~ s{
                ^(dist\h*:.*\n      # dist header line
                    (?:\h+\S.*\n)+) # dist body lines.  `.` doesn't match `\n`.
                                    # NOTE: on Appveyor, the continuation line
                                    # begins with a space rather than a tab.
                                    # Therefore, look for \h after \n.
                                    # Not \s, because that matches a \n!
            }{$1$newtext}mx;
        } #endif $IS_TRIAL

        return $text;
    } # MY::dist_core

    # Generate README.md; add uninstall target and other test targets
    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)

        # Note: pod2markdown is marked with a hyphen so that `make` can
        # succeed and generate META files even if Pod::Markdown is not yet
        # installed.

        return <<EOT;
authortest:
\tRELEASE_TESTING=1 prove -lvj4 xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: @{[$VERSION_FROM]} Makefile.PL
\t-pod2markdown \$< | \\
\t$secure_perl_path -ne 'print if /LICENSE/; next if /INTERNALS/../LICENSE/; print' \\
> \$@

all :: README.md
dist :: README.md

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

EOT

    } #postamble()
} #package MY }}}1

# Main options for EUMM
my %opts = (
    NAME             => 'Build::Hopen',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION_FROM     => 'lib/Build/Hopen.pm',
    ABSTRACT_FROM    => 'lib/Build/Hopen.pm',
    LICENSE          => 'lgpl_2_1',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
        'File::Spec' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #TODO
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cxw42/hopen.git',
                web  => 'https://github.com/cxw42/hopen',
            },
        },

        prereqs => {
            develop => {
                requires => {
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'Data::Dumper' => '0',
                    'Module::Metadata' => '1.000016',
                },
            },
        },

        $provides ? (provides => $provides) : (),

    }, #META_MERGE

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Build-Hopen-*' },
); # %opts

$opts{META_MERGE}->{release_status} = 'testing' if $IS_TRIAL;

WriteMakefile(%opts);
# vi: set fdm=marker fdl=0: #
