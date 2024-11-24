# App::hopen::Gen::MSBuild - generator for msbuild
package App::hopen::Gen::MSBuild;
use strict; use warnings;
use Data::Hopen::Base;
use Syntax::Construct qw(/r);

our $VERSION = '0.000015';

use parent 'App::hopen::Gen';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;
use App::hopen::Phases qw(is_last_phase);
use App::hopen::Util::XML::FromPerl qw(xml_from_perl);
use Data::Hopen qw(:default getparameters *QUIET);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Util::Data qw(forward_opts);
use File::Which;
use Quote::Code;

use App::hopen::Gen::MSBuild::AssetGraphNode;     # for $OUTPUT

# Docs {{{1

=head1 NAME

App::hopen::Gen::MSBuild - hopen generator for MSBuild

=head1 SYNOPSIS

This generator makes a C<.proj> file that can be run with MSBuild.

=head1 FUNCTIONS

=cut

# }}}1

=head2 finalize

Write out the project file (for now, always called C<build.proj>).  Usage:

    $Generator->finalize($dag);     # $data parameter unused

C<$dag> is the build graph.

=cut

sub finalize {
    my ($self, %args) = getparameters('self', [qw(dag; data)], @_);
    hlog { Finalizing => __PACKAGE__ , '- phase', $Phase };
    return unless is_last_phase $Phase;   # Only do work during Gen

    hlog { __PACKAGE__, 'Asset graph', '' . $self->_assets->_graph } 3;

    my $context = Data::Hopen::Scope::Hash->new;
    $context->put($App::hopen::Gen::MSBuild::AssetGraphNode::OUTPUT, undef);
        # undef => will be ignored when making the XML

    # Generate the XML
    my $hrOut = $self->_assets->run(-context => $context);

    my $lrXML = $hrOut->{$self->asset_default_goal->name}
                        ->{$App::hopen::Gen::MSBuild::AssetGraphNode::OUTPUT};
    die "Empty XML!" unless defined $lrXML && @$lrXML;

    # Make the header.  NOTE: no '--' allowed within a comment, so s///gr.
    my $comment = qc_to <<"EOT";
MSBuild project file generated by hopen
(https://github.com/hopenbuild/App-hopen)
at #{gmtime =~ s/--/-/gr} GMT
From ``#{$self->proj_dir->absolute =~ s/--/-/gr}''
into ``#{$self->dest_dir->absolute =~ s/--/-/gr}''
EOT

    # Create the MSBuild file
    my $doc = xml_from_perl(
        ['Project',
            {   xmlns => 'http://schemas.microsoft.com/developer/msbuild/2003',
                id => '__R_ROOT',
            },
            [ '!--', $comment ],
            $lrXML      # TODO @$lrXML?
        ]);
    $doc->setEncoding('utf-8');

    # Write the file
    if($doc->toFile( $self->dest_dir->file('build.proj') ) == -1) {
        die "Couldn't create build.proj";
    }

} #finalize()

=head2 default_toolset

Returns the package name of the default toolset for this generator,
which is C<Gnu> (i.e., L<App::hopen::T::Gnu>).

=cut

sub default_toolset { 'Gnu' }   # TODO

=head2 _assetop_class

The class of asset-graph operations, which in this case is
L<App::hopen::Gen::MSBuild::AssetGraphNode>.

=cut

sub _assetop_class { 'App::hopen::Gen::MSBuild::AssetGraphNode' }

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
__END__
# vi: set fdm=marker: #
