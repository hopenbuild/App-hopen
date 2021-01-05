# App::hopen::Gen::Make - generator for a generic make(1).
package App::hopen::Gen::Make;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use parent 'App::hopen::Gen';   # and Class::Tiny below

use App::hopen::Asset;
use App::hopen::BuildSystemGlobals;
use App::hopen::Phases qw(is_gen_phase);
use App::hopen::Util::String qw(line_mark_string);
use App::hopen::Util::Templates;
use Data::Hopen qw(:default getparameters *QUIET *VERBOSE);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Util::Data qw(forward_opts);
use File::Which;
use Tie::RefHash;

use Class::Tiny {
    # .PHONY targets
    _phony => sub { [] },
};

# Docs {{{1

=head1 NAME

App::hopen::Gen::Make - hopen generator for simple Makefiles

=head1 SYNOPSIS

This generator makes a Makefile that does its best to run on cmd.exe or sh(1).

=head1 FUNCTIONS

=cut

# }}}1

=head2 _finalize

Write out the Makefile.  Usage:

    $Generator->_finalize(-phase => $phase, -graph => $dag);    # $data parameter unused

C<$dag> is the build graph.

=cut

use constant FIRSTGOALNAME => 'first__goal__';

sub _finalize {
    my ($self, %args) = getparameters('self', [qw(phase graph; data)], @_);
    hlog { Finalizing => __PACKAGE__ , '- phase', $args{phase} };
    return unless is_gen_phase $args{phase};

    hlog { __PACKAGE__, 'Assets:', join ', ',
            map { $_->target } keys %{$self->_assets}
    } 3;

    # During the Gen phase, create the Makefile
    open my $fh, '>', $self->dest_dir->file('Makefile') or die "Couldn't create Makefile";
    push @{$self->_phony}, FIRSTGOALNAME;
    print $fh <<EOT;
# Makefile generated by hopen (https://github.com/hopenbuild/App-hopen)
# at @{[scalar gmtime]} GMT
# From ``@{[$self->proj_dir->absolute]}'' into ``@{[$self->dest_dir->absolute]}''

EOT

    # Make sure the first goal is 'all' regardless of order.
    say $fh FIRSTGOALNAME, ': ', $args{graph}->default_goal->name, "\n";

    # Make the Make-friendly name ("tag") of each of the assets we have
    tie my %tags, 'Tie::RefHash';
    foreach my $asset (keys %{$self->_assets}) {

        # Goals
        unless($asset->isdisk) {
            $tags{$asset} = $asset->target;
            push @{$self->_phony}, $tags{$asset};
            next;
        }

        # Files
        my $output = $asset->target;
        $output = $output->path_wrt($self->dest_dir) if eval { $output->DOES('App::hopen::Util::BasedPath') };
        $tags{$asset} = $output;
    }

    # Write the Makefile goals and recipes.
    my @assets = sort App::hopen::Asset::assetwise keys %{$self->_assets};
    $self->_emit_asset($_, \%tags, $fh) foreach @assets;

    # Last thing: the .PHONY tag
    say $fh '.PHONY: ', join ' ', @{$self->_phony};

    close $fh;
} #_finalize()

sub _emit_asset {
    my ($self, $asset, $tags, $fh) = @_;

    if($VERBOSE) {
        hlog { __PACKAGE__, 'Emitting asset', $asset->target } 3;
        say $fh template('verbose')->(asset => $asset);
    }

    my @prereq_tags = map { $tags->{$_} } @{$asset->made_from};
    my $recipe = $asset->how;

    return unless @prereq_tags || $recipe;

    if(defined $recipe) {
        # TODO RESUME HERE refactor this processing into a template
        $recipe =~ s<#first\b><$prereq_tags[0] // ''>ge;      # first input
        $recipe =~ s<#all\b><join(' ', @prereq_tags)>ge;      # all inputs
        my $tag = $tags->{$asset} // '';
        $recipe =~ s<#out\b><$tag>ge;
    }

    # Emit the entry.
    say $fh template('entry')->(
            asset => $asset, tags => $tags, prereqs => \@prereq_tags,
            recipe => $recipe,
    );
} # sub _emit_asset()

=head2 _default_toolset

Returns the package name of the default toolset for this generator,
which is C<Gnu> (i.e., L<App::hopen::T::Gnu>).

=cut

sub _default_toolset { 'Gnu' }

=head2 _run_build

Implementation of L<App::hopen::Gen/run_build>.

=cut

sub _run_build {
    # Look for the make(1) executable.  Listing make before gmake since a
    # system with both Cygwin and Strawberry Perl installed has cygwin's
    # make(1) and Strawberry's gmake(1).
    foreach my $candidate (qw[make gmake mingw32-make dmake]) {
        my $path = File::Which::which($candidate);
        next unless defined $path;
        hlog { Running => $path };
        system $path, ();
        return;
    }
    warn "Could not find a 'make' program to run";
} #_run_build()

1;
__DATA__

@@ verbose
?# Explanation of an asset's build block --- emitted when $VERBOSE
# Makefile piece from node <?= $v{asset}->name ?>: <?= $v{asset}->target ?>
#   <? if($v{asset}->how) { ?>Recipe: <?= $v{asset}->how ?><? } else { ?><?= '<no recipe>' ?><? } ?>
? my $deps = join ', ', map { $_->target } @{$v{asset}->made_from};
#   Depends on <?= $deps || "nothing" ?>

@@ entry
?# Main Makefile entry for an asset
<?= $v{tags}->{$v{asset}} ?>: <?= join ' ', @{$v{prereqs}} ?>
?= $v{recipe} ? "\t$v{recipe}" : ''

@@ __ignore__
# vi: set fdm=marker: #
