# App::hopen::Gen::Make - generator for a generic make(1).
package App::hopen::Gen::Make;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::Util::GenWithoutAssetGraph';    # and Class::Tiny below

use App::hopen::Util::Templates;
use Data::Hopen;
use File::Which;

use Class::Tiny;

use constant FIRSTGOALNAME => 'first__goal__';

# Docs {{{1

=head1 NAME

App::hopen::Gen::Make - hopen generator for simple Makefiles

=head1 SYNOPSIS

This generator makes a Makefile that does its best to run on cmd.exe or sh(1).

=head1 FUNCTION OVERRIDES

L<App::Hopen::Util::GenWithoutAssetGraph/_filename>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_preamble>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_postamble>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_asset_info>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_asset>,
L<App::hopen::Gen/_default_toolset>,
L<App::hopen::Gen/_run_build>

=cut

# }}}1

sub _filename { 'Makefile' }

sub _do_preamble {
    my ($self, $fh, $graph) = @_;
    push @{ $self->_phony }, FIRSTGOALNAME;

    # Make sure the first goal is 'all' regardless of order.
    say $fh FIRSTGOALNAME, ': ', $graph->default_goal->name, "\n";
} ## end sub _do_preamble

sub _do_postamble {
    my ($self, $fh) = @_;

    # Last thing: the .PHONY tag
    say $fh '.PHONY: ', join ' ', @{ $self->_phony };
} ## end sub _do_postamble

sub _do_asset_info {
    my ($self, $fh, $asset) = @_;

    say $fh template('verbose')->(asset => $asset);
}

sub _do_asset {
    my ($self, $fh, $asset, $lrPrereqTags) = @_;
    my @prereq_tags = @$lrPrereqTags;
    my $recipe      = $asset->how;

    return unless @prereq_tags || $recipe;

    if(defined $recipe) {

        # TODO RESUME HERE refactor this processing into a template
        $recipe =~ s<#first\b><$prereq_tags[0] // ''>ge;    # first input
        $recipe =~ s<#all\b><join(' ', @prereq_tags)>ge;    # all inputs
        my $tag = $self->_tags->{$asset} // '';
        $recipe =~ s<#out\b><$tag>ge;
    } ## end if(defined $recipe)

    # Emit the entry.
    say $fh template('entry')->(
        asset   => $asset,
        tags    => $self->_tags,
        prereqs => $lrPrereqTags,
        recipe  => $recipe,
    );
}    # sub _do_asset()

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
    } ## end foreach my $candidate (qw[make gmake mingw32-make dmake])
    warn "Could not find a 'make' program to run";
} ## end sub _run_build

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
