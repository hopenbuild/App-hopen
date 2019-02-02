# Build::Hopen::HopenFileKit - set up a hopen file
package Build::Hopen::HopenFileKit;

# What we use
use Build::Hopen qw(:default loadfrom);
use Build::Hopen::Base;
use Build::Hopen::BuildSystemGlobals;
use Import::Into;
use Package::Alias ();

# What we export to the caller
use Build::Hopen ();
use Build::Hopen::Phases ();
use Path::Class ();

our $VERSION = '0.000005'; # TRIAL

use parent 'Exporter';  # Exporter-exported symbols {{{1
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw($__R_on_result *FILENAME);
                # ^ for Phases::on()
                #               ^ glob so it can be localized
    @EXPORT_OK = qw();
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
} # }}}1

# Docs {{{1

=head1 NAME

Build::Hopen::HopenFileKit - Kit to be used by a hopen file

=head1 SYNOPSIS

This is a special-purpose test kit used for interpreting hopen files.
See L<Build::Hopen::App/_run_phase>.  Usage:

    use Build::Hopen::HopenFileKit "<filename>"[, other args]

C<< <filename> >> is the name you want to use for the package using
this module, and will be loaded into constant C<$FILENAME> in that
package.

C<[other args]> are per Exporter, and should be omitted unless you
really know what you're doing!

=head1 FUNCTIONS

=cut

# }}}1

# Which languages we've loaded
my %_loaded_languages;

sub  _language_import { # {{{1

=head2

C<import()> routine for the fake "language" package

=cut

    my $target = caller;
    #say "language invoked from $target";
    shift;  # Drop our package name
    croak "I need at least one language name" unless @_;

    die "TODO permit aliases" if ref $_[0]; # TODO take { alias => name }

    foreach my $language (@_) {
        next if $_loaded_languages{$language};
            # Only load any given language once.  This avoids cowardly warnings
            # from Package::Alias, but still causes warnings if a language
            # overrides an unrelated package.  (For example, saying
            # `use language "Graph"` would be a Bad Idea :) .)

        # Find the package for the given language
        my ($src_package, $dest_package);
        $src_package = loadfrom($language, "${Toolset}::", '')
            or croak "Can't find a package for language ``$language'' " .
                        "in toolset ``$Toolset''";

        # Import the given language into the root namespace.
        # Use only the last ::-separated component if :: are present.
        $dest_package = ($src_package =~ m/::([^:]+)$/) ? $1 : $src_package;
        Package::Alias->import::into($target, $dest_package => $src_package);

        $_loaded_languages{$language} = true;
    } #foreach requested language
} #_language_import }}}1

sub _create_language { # {{{1

=head2

Create a package "language" so that the calling package can invoke it.

=cut

    #say "_create_language";
    return if %language::;  #idempotent

    {
        no strict 'refs';
        *{'language::import'} = \&_language_import;
    }

    $INC{'language.pm'} = 1;
} #_create_language() }}}1

sub import {    # {{{1

=head2 import

Set up the calling package.  See L</SYNOPSIS> for usage.

=cut

    my $target = caller;
    my $target_friendly_name = $_[1] or croak "Need a filename";
        # 0=__PACKAGE__, 1=filename
    my @args = splice @_, 1, 1;
        # Remove the filename; leave the rest of the args for Exporter's use

    # Export our stuff
    __PACKAGE__->export_to_level(1, @args);

    # Re-export packages
    $_->import::into($target) foreach qw(Build::Hopen::Base Path::Class
                                            Build::Hopen::BuildSystemGlobals);
    Build::Hopen->import::into($target, ':all');
    Build::Hopen::Phases->import::into($target, qw(:all :hopenfile));

    # Initialize data in the caller
    {
        no strict 'refs';
        *{ $target . '::FILENAME' } = eval("\\\"$target_friendly_name\"");
            # Need `eval` to make it read-only - even \"$target..." isn't RO
    }

    _create_language();
} #import()     # }}}1

1;
__END__
# vi: set fdm=marker: #
