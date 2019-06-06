# App::hopen::Gen::Ninja - generator for ninja(1).
package App::hopen::Gen::Ninja;
use strict; use warnings;
use Data::Hopen::Base;

# TODO reduce code duplication between this and Gen::Make
# TODO here and in Gen::Make, remove the need for AssetGraphVisitor by
# creating an extra AssetGraphNode to represent the goal.

our $VERSION = '0.000012'; # TRIAL

use parent 'App::hopen::Gen';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;
use App::hopen::Phases qw(is_last_phase);
use Data::Hopen qw(:default getparameters $QUIET);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Util::Data qw(forward_opts);
use File::Which;
use Hash::Ordered;
use Path::Class;
use Quote::Code;

use App::hopen::Gen::Ninja::AssetGraphNode;     # for $OUTPUT
use App::hopen::Gen::Ninja::AssetGraphVisitor;

# Docs {{{1

=head1 NAME

Data::Hopen::Gen::Ninja - hopen generator for simple Ninja files

=head1 SYNOPSIS

This generator makes a build.ninja file.

=head1 FUNCTIONS

=cut

# }}}1

=head2 visit_goal

Add a target corresponding to the name of the goal.  Usage:

    $Generator->visit_goal($node, $node_inputs);

This happens while the command graph is being run.

=cut

sub visit_goal {
    my ($self, %args) = getparameters('self', [qw(goal node_inputs)], @_);

    # --- Add the goal to the asset graph ---

    my $asset_goal = $self->_assets->goal($args{goal}->name);

    # Pull the inputs.  TODO refactor out the code in common with
    # AhG::Cmd::input_assets().
    my $hrSourceFiles =
        $args{node_inputs}->find(-name => 'made',
                                    -set => '*', -levels => 'local') // {};
    die 'No input files to goal ' . $args{goal}->name
        unless scalar keys %$hrSourceFiles;

    my $lrSourceFiles = $hrSourceFiles->{(keys %$hrSourceFiles)[0]};
    hlog { 'found inputs to goal', $args{goal}->name, Dumper($lrSourceFiles) } 2;

    # TODO? verify that all the assets are actually in the graph first?
    $self->connect($_, $asset_goal) foreach @$lrSourceFiles;

} #visit_goal()

=head2 finalize

Write out the Ninja file.

=cut

sub finalize {
    my ($self, %args) = getparameters('self', [qw(phase dag data)], @_);
    hlog { Finalizing => __PACKAGE__ , '- phase', $args{phase} };
    return unless is_last_phase $args{phase};

    hlog { __PACKAGE__, 'Asset graph', '' . $self->_assets->_graph } 3;

    # During the Gen phase, create the Ninja file
    open my $fh, '>', $self->dest_dir->file('build.ninja')
        or die "Couldn't create Ninjafile";
    print $fh qc_to <<"EOT";
# Ninja file generated by hopen (https://github.com/hopenbuild/App-hopen)
# at #{gmtime} GMT
# From ``#{$self->proj_dir->absolute}'' into ``#{$self->dest_dir->absolute}''

EOT

    my $context = Data::Hopen::Scope::Hash->new;
    $context->put(App::hopen::Gen::Ninja::AssetGraphNode::OUTPUT, $fh);

    # Write the Ninja file.  TODO? flip the order?

    $self->_assets->run(-context => $context,
        -visitor => App::hopen::Gen::Ninja::AssetGraphVisitor->new,
        forward_opts(\%args, {'-'=>1}, qw(phase))
    );

    close $fh;
} #finalize()

=head2 default_toolset

Returns the package name of the default toolset for this generator,
which is C<Gnu> (i.e., L<Data::Hopen::T::Gnu>).

=cut

sub default_toolset { 'Gnu' }

=head2 _assetop_class

The class of asset-graph operations, which in this case is
L<App::hopen::Gen::Ninja::AssetGraphNode>.

=cut

sub _assetop_class { 'App::hopen::Gen::Ninja::AssetGraphNode' }

=head2 _run_build

Implementation of L<App::hopen::Gen/run_build>.

=cut

sub _run_build {
    # Look for the make(1) executable.  Listing make before gmake since a
    # system with both Cygwin and Strawberry Perl installed has cygwin's
    # make(1) and Strawberry's gmake(1).
    my $path = File::Which::which('ninja');
    if(defined $path) {
        hlog { Running => $path };
        system $path, ();
    } else {
        warn "Could not find the 'ninja' program";
    }
} #_run_build()

=head1 INTERNALS

=head2 _expand

Produce the command line or lines associated with a work item.  Used by
L</finalize>.

=cut

sub _expand {
    my $item = shift or croak 'Need a work item';
    hlog { __PACKAGE__ . '::_expand()', Dumper($item) } 2;
    my $retval = $item->{how} or return '';    # no `how` => no output; not an error
    $retval = $retval->[0] if ref $retval eq 'ARRAY';

    my $first = $item->{from}->[0];
    $first = $first->orig->relative($DestDir)
        if $first->DOES('App::hopen::Util::BasedPath');

    my $out = $item->{to}->[0];
    $out = $out->orig->relative($DestDir)
        if $out->DOES('App::hopen::Util::BasedPath');

    $retval =~ s{#first\b}{$first // ''}ge;          # first input
    $retval =~ s{#all\b}{join(' ', @{$item->{from}})}ge;   # all inputs
    $retval =~ s{#out\b}{$out // ''}ge;

    return $retval;
} #_expand()

=head2 BUILD

Constructor

=cut

sub BUILD {
    my ($self, $hrArgs) = @_;
} #BUILD()


1;
__END__
# vi: set fdm=marker: #
