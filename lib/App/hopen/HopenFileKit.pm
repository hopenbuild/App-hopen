# App::hopen::HopenFileKit - set up a hopen file
package App::hopen::HopenFileKit;
use strict; use warnings;
use Data::Hopen::Base;

use Import::Into;
use Package::Alias ();

# Imports.  Note: `()` marks packages we export to the caller but
# don't use ourselves.  These are in the same order as in import().
require App::hopen::AppUtil;
use App::hopen::BuildSystemGlobals;
use App::hopen::Util::BasedPath ();
use Path::Class ();

use App::hopen::Phases ();
use Data::Hopen qw(:default loadfrom);

our $VERSION = '0.000013'; # TRIAL

# Exporter-exported symbols {{{1
use parent 'Exporter';
use vars::i {
    '@EXPORT' => [qw($__R_on_result *FILENAME rule dethunk)],
                    #  ^ for Phases::on()
                    #              ^ glob so it can be localized
    '@EXPORT_OK' => [qw()],
};
use vars::i '%EXPORT_TAGS' => (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
);
# }}}1

# Docs {{{1

=head1 NAME

App::hopen::HopenFileKit - Kit to be used by a hopen file

=head1 SYNOPSIS

This is a special-purpose kit used for interpreting hopen files.
See L<App::hopen/_run_phase>.  Usage: in a hopen file:

    our $IsHopenFile;   # not on disk --- added before eval()
    use App::hopen::HopenFileKit "<filename>"[, other args]

C<< <filename> >> is the name you want to use for the package using
this module, and will be loaded into constant C<$FILENAME> in that
package.  If a filename is omitted, a default name will be used.

C<[other args]> are per L<Exporter>, and should be omitted unless you
really know what you're doing!

See L</import> for details about C<$IsHopenFile>.  That C<our> statement
should not exist in the hopen file on disk, but should be added before
the hopen file's source is evaled.

=head1 FUNCTIONS

=cut

# }}}1

# Which languages we've loaded
my %_loaded_languages;

sub  _language_import { # {{{1

=head2 _language_import

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
            # TODO add to Package::Alias the ability to pass parameters
            # to the package being loaded.

        $_loaded_languages{$language} = true;

        # Create the LSP.  A language may not have an LSP; this is not
        # an error.  E.g., a self-contained assembly project probably
        # doesn't need to reference external code!
        LSP: {
            eval "require App::hopen::Lang::$language";
            (hlog { "Could not load LSP for $language:", $@ }), last LSP if $@;

            my $lsp = eval { "App::hopen::Lang::$language"->new };
            (hlog { "Could not create LSP for $language:", $@ }), last LSP if $@;

            $LSP{$language} = $lsp if $lsp;
        }
    } #foreach requested language
} #_language_import }}}1

sub _create_language { # {{{1

=head2 _create_language

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

# TODO add a function to import hopen files?

=head2 rule

A convenience accessor for L<App::hopen::BuildSystemGlobals/$Build>.

=cut

sub rule { $Build }

=head2 dethunk

Walk a hashref and replace all the L<App::hopen::Util::Thunk> instances with
their L<App::hopen::Util::Thunk/tgt|tgt>s.  Operates in-place.  Usage:

    dethunk(\%config, \%data)

=cut

our $_config;

sub _iskid { ref $_[0] eq 'ARRAY' || ref $_[0] eq 'HASH' }

sub dethunk {
    my $data = shift;
    die "need a data arrayref or hashref" unless _iskid $data;

    _dethunk_walk($data);
}

# Dethunk.  Can't use Data::Walk because of <https://github.com/gflohr/Data-Walk/issues/2>.
# Precondition: $node is an arrayref or hashref
sub _dethunk_walk {
    my $node = shift;
    my $ty = ref $node;
    my $ishash = $ty eq 'HASH';

    my @kids;

    if($ishash) {
        foreach my $k (keys %$node) {
            my $v = $node->{$k};
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                hlog { Dethunk => $v->name } 4;
                $v = $node->{$k} = $v->tgt;
            }
            push @kids, $v if _iskid($v)
        }

    } else {    # array
        foreach my $pair (map { [$_, $node->[$_]] } 0..$#$node) {
            my ($i, $v) = @$pair;
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                hlog { Dethunk => $v->name } 4;
                $v = $node->[$i] = $v->tgt;
            }
            push @kids, $v if _iskid($v)
        }
    }

    _dethunk_walk($_) foreach @kids;
}

my $_uniq_idx = 0;  # for fake filenames

sub import {    # {{{1

=head2 import

Set up the calling package.  See L</SYNOPSIS> for usage.
Dies if the calling package does not have a package variable called
C<$IsHopenFile>.  The value of that variable is not checked.  This is a
rudimentary sanity check to make things like `perl .hopen.pl` more
benign.  (Maybe someday we can make that usage valid, but not now!)

=cut

    my $target = caller;
    my $target_friendly_name;
    unless($target_friendly_name = $_[1]) {
        warn "No filename given --- creating one";
        $target_friendly_name = '__R_hopenfile_' . $_uniq_idx++;
    }

    my @args = splice @_, 1, 1;
        # 0=__PACKAGE__, 1=filename
        # Remove the filename; leave the rest of the args for Exporter's use

    {
        no strict 'refs';
        die "Not loaded as a hopen file --- run hopen(1) instead of running this file directly.\n"
            unless exists ${"$target\::"}{&App::hopen::AppUtil::HOPEN_FILE_FLAG};
    }

    # Export our stuff
    __PACKAGE__->export_to_level(1, @args);

    # Re-export packages
    $_->import::into($target) foreach qw(
        Data::Hopen::Base
        App::hopen::BuildSystemGlobals
        App::hopen::Util::BasedPath
        Path::Class
    );

    App::hopen::Phases->import::into($target, qw(:all :hopenfile));
    Data::Hopen->import::into($target, ':all');

    # Initialize data in the caller
    {
        no strict 'refs';
        *{ $target . '::FILENAME' } = eval("\\\"\Q$target_friendly_name\E\"");
            # Need `eval` to make it read-only - even \"$target..." isn't RO.
            # \Q and \E since, on Windows, $friendly_name is likely to
            # include backslashes.
    }

    # Create packages at the top level
    _create_language();
    Package::Alias->import::into($target, 'H' => 'App::hopen::H')
        unless eval { scalar keys %H:: };
        # Don't import twice, but without the need to set Package::Alias::BRAVE
        # TODO permit handling the situation in which an actual package H is
        # loaded, and the hopenfile needs to use something else.
        # TODO look inside $target to make sure H is visible within $target,
        # rather than just checking if H has been loaded anywhere.
} #import()     # }}}1

1;
__END__
# vi: set fdm=marker: #
