# App::hopen::HopenFileKit - set up a hopen file
package App::hopen::HopenFileKit;
use strict; use warnings;
use Data::Hopen::Base;

use Import::Into;
use Package::Alias ();

# Imports.  Note: `()` marks packages we export to the caller but
# don't use ourselves.  These are in the same order as in import().
use App::hopen::AppUtil qw(:default :constants);
use App::hopen::BuildSystemGlobals;
use App::hopen::Util;
use App::hopen::Util::BasedPath ();
use Getargs::Mixed;
use Path::Class ();

# NOTE: we don't use List::Util::pairs*() because those were added in L::U 1.29,
# and Perl 5.14 (which we support) only has L::U 1.23 in core.

use Data::Hopen qw(:default loadfrom);

our $VERSION = '0.000013'; # TRIAL

# Exporter-exported symbols
use parent 'Exporter';
use vars::i {
    '@EXPORT' => [qw($__R_on_result *FILENAME on rule dethunk extract_thunks)],
                    #  ^ for on()
                    #               ^ glob so it can be localized
    '@EXPORT_OK' => [qw()],
};
use vars::i '%EXPORT_TAGS' => (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
);

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

=head1 LANGUAGE SUPPORT

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

=head1 ROUTINES FOR USE BY WRITERS OF HOPEN FILES

These routines are part of the public API of the hopen build system.

=head2 on

Take a given action only in a specified phase.  Usage examples:

    on check => { foo => 42 };  # Just return the given hashref
    on gen => 1337;             # Returns { Gen => 1337 }
    on check => sub { return { foo => 1337 } };
        # Call the given sub and return its return value.

This is designed for use within a hopen file.
See L<App::hopen/_run_phase> for the execution environment C<on()> is
designed to run in.

When run as part of a hopen file, C<on()> will skip the rest of the file if it
runs.  For example:

    say "Hello, world!";                # This always runs
    on check => { answer => $answer };  # This runs during the Check phase
    on gen => { done => true };         # This runs during the Gen phase
    say "Phase was neither Check nor Gen";  # Doesn't run in Check or Gen

TODO support C<< on '!last' => ... >> or similar to take action when not in
the given phase.

=cut

sub on {
    my $caller = caller;
    my (%args) = parameters([qw(phase value)], @_);

    my $run_in_phase = PHASES->check($args{phase});

    return unless $run_in_phase eq $Phase;

    my $val = $args{value};

    # We are in the correct phase.  Take appropriate action.
    # However, don't change our own return value.
    my $result;
    if(ref $val eq 'CODE') {
        $result = &$val;
    } elsif(ref $val eq 'HASH') {
        $result = $val;     # TODO? clone?
    } else {
        $result = {$Phase => $val};
    }

    # Stash the value for the caller.
    {
        no strict 'refs';
        ${ $caller . "::__R_on_result" } = $result;
    }

    # Done --- skip the rest of the hopen file if we're in one.
    hlog { 'Done with script for phase ``' . $Phase . "''" } 3;
    eval {
        no warnings 'exiting';
        last __R_DO;
    };
} #on()

=head2 rule

A convenience accessor for L<App::hopen::BuildSystemGlobals/$Build>.

=cut

sub rule { $Build }

=head1 ROUTINES FOR USE BY PROCESSORS OF HOPEN FILES

These routines are B<not> part of the public API of the hopen build
system.  They are used inside L<App::hopen> to help process hopen files.

=head2 dethunk

Walk a hashref and replace all the L<App::hopen::Util::Thunk> instances with
their L<tgt|App::hopen::Util::Thunk/tgt>s.  Operates in-place.  Usage:

    dethunk(\%config, \%data)

See L<App::hopen::MYhopen/extract_thunks> for creating C<%config>.

=cut

our $_config;

sub dethunk {
    my $data = shift;
    die "need a data arrayref or hashref" unless isaggref $data;

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
            push @kids, $v if isaggref $v;
        }

    } else {    # array
        foreach my $pair (map { [$_, $node->[$_]] } 0..$#$node) {
            my ($i, $v) = @$pair;
            hlog { Value => $v } 5;
            if(ref $v eq 'App::hopen::Util::Thunk') {
                hlog { Dethunk => $v->name } 4;
                $v = $node->[$i] = $v->tgt;
            }
            push @kids, $v if isaggref $v;
        }
    }

    _dethunk_walk($_) foreach @kids;
} #_dethunk_walk


sub import {    # {{{1

=head2 import

Set up the calling package.  See L</SYNOPSIS> for usage.
Dies if the calling package does not have a package variable called
C<$IsHopenFile>.  The value of that variable is not checked.  This is a
rudimentary sanity check to make things like `perl .hopen.pl` more
benign.  (Maybe someday we can make that usage valid, but not now!)

=cut

    state $uniq_idx = 0;  # for fake filenames

    my $target = caller;
    my $target_friendly_name;
    unless($target_friendly_name = $_[1]) {
        warn "No filename given --- creating one";
        $target_friendly_name = '__R_hopenfile_' . $uniq_idx++;
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

    App::hopen::AppUtil->import::into($target, qw(:default :constants));
    Data::Hopen->import::into($target, ':all');

    # Initialize data in the caller
    {
        no strict 'refs';
        *{ $target . '::FILENAME' } = eval("\\\"\Q$target_friendly_name\E\"");
            # Need `eval` to make it read-only - even \"$target..." isn't RO.
            # \Q and \E since, on Windows, $friendly_name is likely to
            # include backslashes.
            # TODO check if this gets double-backslashed.
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
