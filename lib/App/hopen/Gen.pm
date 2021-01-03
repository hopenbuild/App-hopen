# App::hopen::Gen - base class for hopen generators
package App::hopen::Gen;
use Data::Hopen qw(:default *QUIET);
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use parent 'Data::Hopen::Visitor';  # uses Class::Tiny below

use App::hopen::Asset;
use App::hopen::BuildSystemGlobals;
use App::hopen::Util::String qw(eval_here);
use Data::Hopen::G::DAG;
use Data::Hopen::Util::Data qw(forward_opts);
use File::pushd qw(pushd);
use Path::Class ();
use Scalar::Util qw(refaddr);

# Docs (general and attrs) {{{1

=head1 NAME

App::hopen::Gen - Base class for hopen generators

=head1 SYNOPSIS

The code that generates blueprints for specific build systems
lives under C<App::hopen::Gen>.  L<App::hopen> calls modules
under C<App::hopen::Gen> to create the blueprints.  Those modules must
implement the interface defined here.

A generator (C<App::hopen::Gen> subclass) is a Visitor plus a bit.

B<Note>:
The generator does not have access to L<Data::Hopen::G::Link> instances.
That lack of access is the primary distinction between Ops and Links in
L<Data::Hopen>.  Don't expect that access here :) .

=head1 ATTRIBUTES

=head2 proj_dir

(Required) A L<Path::Class::Dir> instance specifying the root directory of
the project.

=head2 dest_dir

(Required) A L<Path::Class::Dir> instance specifying where the generated output
(e.g., blueprint or other files) should be written.

=head2 architecture

(Optional) A string of architecture information meaningful to the generator.
TODO specify the format of this information.

=head1 ATTRIBUTES FOR USE BY SUBCLASSES

=head2 _assets

A hash (L<Tie::RefHash>) from each asset to C<1>.  A hash rather than
a list for ease of lookup.

This is filled in by L</visit>, so if you override C<visit()> and don't call
C<SUPER::visit()>, don't use this.

=cut

# }}}1

# TODO eventually support coercions?  I'm trying to avoid pulling in
# Type::Tiny, but that would be the thing to do if I need the coercions.
use vars::i '$IsPathClassDir' => [
    sub { eval { $_[0]->DOES('Path::Class::Dir') } },
    sub { "Need a Path::Class::Dir instance" }
];

use Class::Tiny::ConstrainedAccessor {
    proj_dir => $IsPathClassDir,
    dest_dir => $IsPathClassDir,
};

use Class::Tiny qw(proj_dir dest_dir), {
    architecture => '',

    # private

    _assets => sub { tie my %h, 'Tie::RefHash'; \%h },
};

=head1 FUNCTIONS

=cut

## =head2 asset
##
## Called by an Op (L<App::hopen::G::Op> subclass) to add an asset
## (L<App::hopen::G::AssetOp> instance) to the build.  Usage:
##
##     $Generator->asset([-asset=>]$asset, [-from=>]$from[, [-how=>]$how]);
##
## If C<$how> is specified, it will be saved in the C<AssetOp> for use later.
## Later calls with the same asset and a defined C<$how> will overwrite the
## C<how> value in the C<AssetOp>.  Specify 'UNDEF' as the C<$how> to
## expressly undefine a C<how>.
##
## Returns the C<AssetOp>.
##
## =cut
##
## sub asset {
##     my ($self, %args) = getparameters('self', [qw(asset; how)], @_);
##     hlog { 'Generator adding asset at',refaddr($args{asset}),$args{asset} } 3;
##
##     my $existing_op = $self->_assetop_by_asset->{refaddr($args{asset})};
##
##     # Update an existing op
##     if(defined $existing_op) {
##         if( ($args{how}//'') eq 'UNDEF') {
##             $existing_op->how(undef);
##         } elsif(defined $args{how}) {
##             $existing_op->how($args{how});
##         }
##         return $existing_op;
##     }
##
##     # Need to create an op.  First, load its class.
##     my $class = $self->_assetop_class;
##
##     eval_here <<EOT;
## require $class;
## EOT
##     die "$@" if $@;
##
##     # Create a new op
##     my $op = $class->new(name => 'Op:<<' . $args{asset}->target . '>>',
##                             forward_opts(\%args, qw(asset how)));
##     $self->_assetop_by_asset->{refaddr($args{asset})} = $op;
##     $self->_assets->add($op);
##     return $op;
## } #asset()
##
## =head2 connect
##
## Add a dependency edge between two assets or goals.  Any assets must have already
## been added using L</asset>.  Usage:
##
##     $Generator->connect([-from=>]$from, [-to=>$to]);
##
## TODO add missing assets automatically?
##
## TODO rename the asset-graph public interface so it's more clear that it's
## the asset graph and not the command graph.
##
## =cut
##
## sub connect {
##     my ($self, %args) = getparameters('self', [qw(from to)], @_);
##     my %nodes;
##
##     # Get the nodes if we were passed assets.
##     foreach my $field (qw(from to)) {
##         if(eval { $args{$field}->DOES('App::hopen::Asset') }) {
##             $nodes{$field} = $self->_assetop_by_asset->{refaddr($args{$field})};
##         } else {
##             $nodes{$field} = $args{$field};
##         }
##     }
##
##     # TODO better error messages
##     croak "No From node for asset " . refaddr($args{from}) unless $nodes{from};
##     croak "No To node for asset " . refaddr($args{to}) unless $nodes{to};
##     $self->_assets->connect($nodes{from}, $nodes{to});
## } #connect()
##
## =head2 asset_default_goal
##
## Read-only accessor for the default goal of the asset graph
##
## =cut
##
## sub asset_default_goal () { shift->_assets->default_goal }

=head2 run_build

Runs the build tool for which this generator has created blueprint files.
Runs the tool with the destination directory as the current dir.
Uses abstract L</_run_build>.

=cut

sub run_build {
    my $self = shift or croak 'Need an instance';
    my $abs_dir = $self->dest_dir->absolute;
        # NOTE: You have to call this *before* pushd() or chdir(), because
        # it may be a relative path, and absolute() converts with respect
        # to cwd at the time of the call.
    my $dir = pushd($abs_dir);
    say "Building in ${abs_dir}..." unless $QUIET;
    $self->_run_build();
} #run_build()

## =head2 BUILD
##
## Constructor.
##
## =cut
##
## sub BUILD {
##     my ($self, $args) = @_;
##
##     # Create the asset graph
##     $self->_assets(hnew DAG => 'asset graph');
##     $self->_assets->goal('__R_asset_default_goal');
##         # Create and set default goal
## } #BUILD()

=head1 FUNCTIONS TO BE IMPLEMENTED BY SUBCLASSES

=cut

## =head2 _assetop_class
##
## (Required) Returns the name of the L<App::hopen::G::AssetOp> subclass that
## should be used to represent assets in the C<_assets> graph.
##
## =cut
##
## sub _assetop_class { ... }

=head2 _default_toolset

(Required) Returns the package stem of the default toolset for this generator.

When a hopen file invokes C<use language "Foo">, hopen will load
C<< App::hopen::T::<stem>::Foo >>.  C<< <stem> >> is the return
value of this function unless the user has specified a different toolset.

As a sanity check, hopen will first try to load C<< App::hopen::T::<stem> >>,
so make sure that is a valid package.

=cut

sub _default_toolset { ... }

=head2 _finalize

(Optional)
Do whatever the generator wants to do to finish up.  By default, no-op.
Is provided the L<Data::Hopen::G::DAG> instance as a parameter.  Usage:

    $generator->_finalize(-phase=>$Phase, -graph=>$Build,
                        -data=>$data)

C<$dag> is the command graph, and C<$data> is the output from the
command graph.

C<_finalize> is always called with named parameters.

=cut

sub _finalize { }

=head2 _run_build

(Optional)
Implementation of L</run_build>.  The default does not die, but does warn().

=cut

sub _run_build {
    warn "This generator is not configured to run a build tool.  Sorry!";
} #_run_build()

=head2 visit

Stash all the assets from this node in L</_assets>.

Also delegate to L</_visit_node>.

=cut

sub visit {
    my ($self, %args) = getparameters('self', [qw(node type node_inputs preds)], @_);

    # Stash all the assets
    my $assets = $args{node}->outputs->{made} // [];
    $self->_assets->{$_} = 1 foreach @$assets;

    $self->_assets->{$args{node}->asset} = 1 if $args{type} eq 'goal' && $args{node}->asset;

    return $self->_visit_node($args{node}, $args{type}, $args{node_inputs}, $args{preds})

} #visit_goal()

=head2 _visit_node

(Optional) Do whatever the generator wants to do with a
L<Data::Hopen::G::Node>.  By default, no-op.  Parameters are as L</visit>.

=cut

sub _visit_node { }

1;
__END__
# vi: set fdm=marker: #
