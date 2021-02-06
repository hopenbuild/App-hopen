# App::hopen::Gen::Ninja - generator for a generic make(1).
package App::hopen::Gen::Ninja;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::Util::GenWithoutAssetGraph';    # and Class::Tiny below

use App::hopen::Util::Templates;
use Data::Hopen;
use File::Which;

use Class::Tiny {

    # Rule names, indexed by recipe
    _rules => sub { +{} },
};

# Docs {{{1

=head1 NAME

App::hopen::Gen::Ninja - hopen generator for simple Ninja files

=head1 SYNOPSIS

This generator makes a build.ninja file.

=head1 FUNCTION OVERRIDES

L<App::Hopen::Util::GenWithoutAssetGraph/_filename>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_postamble>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_asset_info>,
L<App::Hopen::Util::GenWithoutAssetGraph/_do_asset>,
L<App::hopen::Gen/_default_toolset>,
L<App::hopen::Gen/_run_build>

=cut

# }}}1

sub _filename { 'build.ninja' }

sub _do_postamble {
    my ($self, $fh, $graph) = @_;

    say $fh 'default ', $graph->default_goal->name;
}

sub _do_asset_info {
    my ($self, $fh, $asset) = @_;

    say $fh template('verbose')->(asset => $asset);
}

sub _do_asset {
    state $ruleidx = 0;
    my ($self, $fh, $asset, $lrPrereqTags) = @_;
    my @prereq_tags = @$lrPrereqTags;
    my $recipe      = $asset->how;
    my $output      = $self->_tags->{$asset};

    return unless @prereq_tags || $recipe;

    if(defined $recipe) {

        # TODO refactor this processing into a utility module/function
        warn "I don't yet support #first very well (in ``$recipe'')"
          if $recipe =~ /#first/;
        $recipe =~ s<#first\b><\$in>g;    # first input   # TODO FIXME
            # TODO: any recipe using #first gets a `first = x` var shadow
            # in its build block

        $recipe =~ s<#all\b><\$in>g;    # all inputs
        $recipe =~ s<#out\b><\$out>g;
    } ## end if(defined $recipe)

    if($asset->isdisk) {                # File target

        my $rulename = $self->_rules->{$recipe};
        unless($rulename) {
            $rulename = 'rule_' . ++$ruleidx;
            print $fh <<"EOT";
rule $rulename
    command = $recipe

EOT
            $self->_rules->{$recipe} = $rulename;
        } ## end unless($rulename)

        print $fh <<"EOT";
build $output: $rulename @{[join(" ", @prereq_tags)]}

EOT
    } else {    # Goal target

        print $fh <<"EOT";
build $output: phony @{[join(" ", @prereq_tags)]}

EOT
    } ## end else [ if($asset->isdisk) ]

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
    my $path = File::Which::which('ninja');
    if(defined $path) {
        hlog { Running => $path };
        system $path, ();
    } else {
        warn "Could not find the 'ninja' program";
    }
} ## end sub _run_build

1;
__DATA__

@@ verbose
?# Explanation of an asset's build block --- emitted when $VERBOSE
# ninja piece from node <?= $v{asset}->name ?>: <?= $v{asset}->target ?>
#   <? if($v{asset}->how) { ?>Recipe: <?= $v{asset}->how ?><? } else { ?><?= '<no recipe>' ?><? } ?>
? my $deps = join ', ', map { $_->target } @{$v{asset}->made_from};
#   Depends on <?= $deps || "nothing" ?>

@@ __ignore__
# vi: set fdm=marker: #
