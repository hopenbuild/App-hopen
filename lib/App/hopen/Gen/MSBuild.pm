# App::hopen::Gen::MSBuild - generator for msbuild
package App::hopen::Gen::MSBuild;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::Gen'; # And Class::Tiny below

use App::hopen::AppUtil qw(:constants);
use App::hopen::BuildSystemGlobals;
use App::hopen::Util::XML::FromPerl qw(xml_from_perl);
use Data::Hopen qw(:default getparameters *QUIET *VERBOSE);
use Data::Hopen::Scope::Hash;
## use File::Which;
use Tie::RefHash;

use App::hopen::Gen::MSBuild::AssetGraphNode;    # for $OUTPUT

my $_dag_idx = 0;

use Class::Tiny { _asset_graph =>
      sub { hnew DAG => '__R_MSBuild_asset_graph_' . $_dag_idx++ }, };

# Docs {{{1

=head1 NAME

App::hopen::Gen::MSBuild - hopen generator for MSBuild

=head1 SYNOPSIS

This generator makes a C<.proj> file that can be run with MSBuild.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _finalize

Write out the project file (for now, always called C<build.proj>).  Usage:

    $Generator->_finalize($phase, $dag);     # $data parameter unused

C<$dag> is the build graph.

=cut

sub _finalize {
    my ($self, %args) = getparameters('self', [qw(phase graph; data)], @_);
    hlog { Finalizing => __PACKAGE__, '- phase', $args{phase} };
    return unless PHASES->is($args{phase}, 'gen');

    $self->_populate_asset_graph;

    my $context = Data::Hopen::Scope::Hash->new;
    $context->put($App::hopen::Gen::MSBuild::AssetGraphNode::OUTPUT, undef);

    # undef => will be ignored when making the XML

    # Generate the XML
    my $hrOut = $self->_asset_graph->run(-context => $context);

    my $lrXML = $hrOut->{default}
      ->{$App::hopen::Gen::MSBuild::AssetGraphNode::OUTPUT};
    die "Empty XML!" unless defined $lrXML && @$lrXML;

    # Make the header.  NOTE: no '--' allowed within a comment, so s///gr.
    my $comment = <<"EOT";
MSBuild project file generated by hopen
(https://github.com/hopenbuild/App-hopen)
at @{[gmtime =~ s/--/-/gr]} GMT
From ``@{[$self->proj_dir->absolute =~ s/--/-/gr]}''
into ``@{[$self->dest_dir->absolute =~ s/--/-/gr]}''
EOT

    # Create the MSBuild file
    my $doc = xml_from_perl(
        [
            'Project', {
                xmlns => 'http://schemas.microsoft.com/developer/msbuild/2003',
                id    => '__R_ROOT',
            },
            [ '!--', $comment ],
            $lrXML    # TODO @$lrXML?
        ]
    );
    $doc->setEncoding('utf-8');

    # Write the file
    if($doc->toFile($self->dest_dir->file('build.proj')) == -1) {
        die "Couldn't create build.proj";
    }

} ## end sub _finalize

=head2 _populate_asset_graph

Populate the asset graph (!).  No retval.

=cut

sub _populate_asset_graph {
    my $self = shift;

    tie my %nodes,   'Tie::RefHash';    # asset->assetop
    tie my %hassucc, 'Tie::RefHash';    # asset->1 if the asset has a successor

    # Load the assets into the graph
    foreach my $asset (keys %{ $self->_assets }) {
        $nodes{$asset} = App::hopen::Gen::MSBuild::AssetGraphNode->new(
            asset => $asset,
            name  => '[' . $asset->target . '](assetop)'
        ) unless exists $nodes{$asset};

        foreach my $pred (@{ $asset->made_from }) {
            $nodes{$pred} = App::hopen::Gen::MSBuild::AssetGraphNode->new(
                asset => $pred,
                name  => '[' . $pred->target . '](assetop)'
            ) unless exists $nodes{$pred};

            $self->_asset_graph->connect($nodes{$pred}, $nodes{$asset});
            $hassucc{$pred} = 1;
        } ## end foreach my $pred (@{ $asset...})
    } ## end foreach my $asset (keys %{ ...})

    # Link any node without a successor to the default goal
    foreach my $asset (keys %{ $self->_assets }) {
        next if $hassucc{$asset};
        $self->_asset_graph->connect($nodes{$asset},
            $self->_asset_graph->goal('default'));
    }

    hlog { __PACKAGE__, 'Asset graph', '' . $self->_asset_graph } 3;
} ## end sub _populate_asset_graph

=head2 _default_toolset

Returns the package name of the default toolset for this generator,
which is C<Gnu> (i.e., L<App::hopen::T::Gnu>).

=cut

sub _default_toolset { 'Gnu' }    # TODO

## =head2 _run_build
##
## Implementation of L<App::hopen::Gen/run_build>.
##
## =cut
##
## sub _run_build {
##     # Look for the make(1) executable.  Listing make before gmake since a
##     # system with both Cygwin and Strawberry Perl installed has cygwin's
##     # make(1) and Strawberry's gmake(1).
##     foreach my $candidate (qw[make gmake mingw32-make dmake]) {
##         my $path = File::Which::which($candidate);
##         next unless defined $path;
##         hlog { Running => $path };
##         system $path, ();
##         return;
##     }
##     warn "Could not find a 'make' program to run";
## } ## end sub _run_build

1;
__END__
# vi: set fdm=marker: #
