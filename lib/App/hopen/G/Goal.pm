# App::hopen::G::Goal - A named build goal
package App::hopen::G::Goal;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000020';

use parent qw(Data::Hopen::G::Goal App::hopen::G::Cmd);

use Class::Tiny {
    _asset => undef,    # Backing storage for asset()
};

use Data::Hopen;
use Data::Hopen::Util::Data qw(forward_opts);

# Docs {{{1

=head1 NAME

App::hopen::G::Goal - a named target in a hopen build

=head1 SYNOPSIS

A C<Goal> is a named target, e.g., C<doc>, C<dist>, or C<all>.  The name
C<all> is used for the default goal of the build.

=head1 ATTRIBUTES

=head1 FUNCTIONS

=head2 asset

Returns an asset that represents this goal.

=cut

sub asset {
    my $self = shift;
    croak "Cannot retrieve asset from a Goal that has not yet been run"
        unless $self->_asset;

    return $self->_asset;
}

=head2 _run

Creates an L<App::hopen::Asset> representing the goal and makes that
asset available through L</asset>.

=cut

# }}}1

sub _run {
    my ($self, %args) = getparameters('self', [qw(; visitor)], @_);
    hlog { __PACKAGE__, $self->name } 2;

    my $inputs = $self->input_assets;
    my $asset = App::hopen::Asset->new(target => $self->name,
                                        made_from => $inputs);
    $self->_asset($asset);
        # Not an output, since output is controlled by
        # Data::Hopen::G::Goal::should_output.  Therefore, we also don't
        # call make($asset).

    return $self->Data::Hopen::G::Goal::_run(forward_opts(\%args, {'-'=>1}, qw(visitor)));
} #_run()

1;
__END__
# vi: set fdm=marker: #
