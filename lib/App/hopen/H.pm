# App::hopen::H - basic functions for use by user code in hopen files
package App::hopen::H;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'Exporter';
use vars::i '@EXPORT'      => [];
use vars::i '@EXPORT_OK'   => qw(files want);    # TODO move these to @EXPORT?
use vars::i '%EXPORT_TAGS' => (
    default => [@EXPORT],
    all     => [ @EXPORT, @EXPORT_OK ]
);

use App::hopen::BuildSystemGlobals;
use App::hopen::G::FilesCmd;
use App::hopen::G::FindDependencyCmd;
use App::hopen::Util::BasedPath;
use Data::Hopen qw(hlog getparameters);
use Data::Hopen::G::GraphBuilder;
use Data::Hopen::Util::Data qw(forward_opts);
use Hash::MultiValue;
use List::Flatten::Recursive;
use Path::Class;
use PerlX::Maybe qw(:all);

# Docs {{{1

=head1 NAME

App::hopen::H - basic functions for use by user code in hopen files

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

    my @files =
      map { based_path(path => file($_), base => $ProjDir) } @$lrFiles;
    hlog { __PACKAGE__, 'file objects:', @files } 3;

    # A separate Cmd node for each file
    my $idx      = 0;
    my @files_op = map {
        App::hopen::G::FilesCmd->new(
            files => [$_],
            provided_deref exists($args{name}),
            sub { name => ($args{name} . $idx++) },
        )
    } @files;

    return { complete => \@files_op };
} ## end sub files

make_GraphBuilder 'files';

=head2 want

Declare an optional dependency.  The necessary information to use the
dependency will be sent down the build graph from this node.  Usage:

    $Build->H::want([-type => 'value',]+ [-name => 'foo'])

E.g.,

    $Build->H::want(-lib => 'va', -name => 'libva checker')

You can also give an arrayref:

    $Build->H::want(-lib => ['va', 'glib-2.0'], -name => 'check two libs')

=cut

sub want {
    my $builder = shift;

    # Regularize the dependency lists
    my $args = Hash::MultiValue->new(@_);
    foreach my $k (keys %$args) {
        $args->set($k, flat($args->get_all($k)));
    }

    hlog { __PACKAGE__, 'want:', Dumper($args->multi) } 3;
    my $cmd = App::hopen::G::FindDependencyCmd->new(
        deps     => $args->multi,
        required => false
    );

    # TODO: create a node
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
    return $cmd;
} ## end sub want

make_GraphBuilder 'want';

1;
__END__
# vi: set fdm=marker: #
