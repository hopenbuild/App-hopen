# App::hopen::Gen::Ninja - generator for ninja(1).
package App::hopen::Gen::Ninja;
use strict; use warnings;
use Data::Hopen::Base;

# TODO reduce code duplication between this and Gen::Make

our $VERSION = '0.000013'; # TRIAL

use parent 'App::hopen::Gen';
use Class::Tiny;

use App::hopen::BuildSystemGlobals;
use App::hopen::Phases qw(is_gen_phase);
use Data::Hopen qw(:default getparameters *QUIET);
use Data::Hopen::Scope::Hash;
use Data::Hopen::Util::Data qw(forward_opts);
use File::Which;
use Path::Class;
use Quote::Code;

use App::hopen::Gen::Ninja::AssetGraphNode;     # for $OUTPUT

# Docs {{{1

=head1 NAME

App::hopen::Gen::Ninja - hopen generator for simple Ninja files

=head1 SYNOPSIS

This generator makes a build.ninja file.

=head1 FUNCTIONS

=cut

# }}}1

=head2 finalize

Write out the Ninja file.  Usage:

    $Generator->finalize($phase, $dag);     # $data parameter unused

C<$dag> is the build graph.

=cut

sub finalize {
    my ($self, %args) = getparameters('self', [qw(phase dag; data)], @_);
    hlog { Finalizing => __PACKAGE__ , '- phase', $args{phase} };
    return unless is_gen_phase $args{phase};

    hlog { __PACKAGE__, 'Asset graph', '' . $self->_assets->_graph } 3;

    # During the Gen phase, create the Ninja file
    open my $fh, '>', $self->dest_dir->file('build.ninja')
        or die "Couldn't create Ninja file";
    print $fh qc_to <<"EOT";
# Ninja file generated by hopen (https://github.com/hopenbuild/App-hopen)
# at #{gmtime} GMT
# From ``#{$self->proj_dir->absolute}'' into ``#{$self->dest_dir->absolute}''

EOT

#    # Make sure the first goal is 'all' regardless of order.
#    say $fh qc'first__goal__: {$args{dag}->default_goal->name}\n';

    my $context = Data::Hopen::Scope::Hash->new;
    $context->put(App::hopen::Gen::Ninja::AssetGraphNode::OUTPUT, $fh);

    # Write the Ninja file.  TODO? flip the order?

    $self->_assets->run(-context => $context,
        forward_opts(\%args, {'-'=>1}, qw(phase))
    );

    close $fh;
} #finalize()

=head2 default_toolset

Returns the package name of the default toolset for this generator,
which is C<Gnu> (i.e., L<App::hopen::T::Gnu>).

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

1;
__END__
# vi: set fdm=marker: #
