# App::hopen::H - basic functions for use in hopen files
package App::hopen::H;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use parent 'Exporter';
use vars::i '@EXPORT' => [];
use vars::i '@EXPORT_OK' => qw(files want);     # TODO move these to @EXPORT?
use vars::i '%EXPORT_TAGS' => (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );

use App::hopen::BuildSystemGlobals;
use App::hopen::G::FilesCmd;
#use App::hopen::G::FindDependencyCmd;
use App::hopen::Util::BasedPath;
use Data::Hopen qw(hlog getparameters);
use Data::Hopen::G::GraphBuilder;
use Data::Hopen::Util::Data qw(forward_opts);
use Path::Class;
use PerlX::Maybe qw(:all);

# Docs {{{1

=head1 NAME

App::hopen::H - basic functions for use in hopen files

=head1 SYNOPSIS

This module is loaded as C<H::*> into hopen files by
L<App::hopen::HopenFileKit>.

=head1 FUNCTIONS

=cut

# }}}1

=head2 files

Creates a command-graph node representing a set of input files.
Example usage:

    $Build->H::files('foo.c')->C::compile->C::link('foo')->default_goal;

The node is an L<App::hopen::G::FilesCmd>.

The file path is assumed to be relative to the current project directory.
TODO handle subdirectories.

Adds each specified file as a separate node in the asset graph.

=cut

sub files {
    my ($builder, %args) = getparameters('self', ['*'], @_);
    my $lrFiles = $args{'*'} // [];
    hlog { __PACKAGE__, 'files:', Dumper($lrFiles) } 3;

    my @files = map { based_path(path => file($_), base => $ProjDir) } @$lrFiles;
    hlog { __PACKAGE__, 'file objects:', @files } 3;

    # A separate Cmd node for each file
    my $idx = 0;
    my @files_op = map { App::hopen::G::FilesCmd->new(
        files => [ $_ ],
        provided_deref exists($args{name}), sub { name => ($args{name} . $idx++) },
    ) } @files;

    return { complete => \@files_op };
} #files()

make_GraphBuilder 'files';

=head2 want

Declare an optional dependency.  The necessary information to use the
dependency will be sent down the build graph from this node.

=cut

sub want {
    my ($builder, %args) = getparameters('self', ['*'], @_);
    hlog { __PACKAGE__, 'want:', Dumper(\%args) } 3;

    # TODO: create a node and give it a reference to the graph.
    # That node, when run, will:
    #  - collect the list of all its successors in the graph (not just
    #    direct children)
    #  - Use the package names of those successors (or in some other way)
    #    figure out which languages are used in the graph
    #    - Do Cmds need to carry a language tag?
    #  - Invoke language-specific search routines to find the wanted dependendencies
    #  - Output those as keys under, e.g, $hr->{lang}->{C}->{I} (and likewise
    #    {l} and {L}).  Or, e.g., $hr->{lang}->{Vala}->{pkg} (and likewise
    #    {vapidir}).
    ...
} #want()

make_GraphBuilder 'want';

1;
__END__
# vi: set fdm=marker: #
