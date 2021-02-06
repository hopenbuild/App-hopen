# App::hopen::G::AssetOp - parent class for operations used by a
# generator to build an asset
package App::hopen::G::AssetOp;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::G::Cmd';

# TODO why is this not directly a child of Data::Hopen::G::Op?
# It uses input_assets, but could that be refactored out to a parent
# of which this and AhG::Cmd were siblings?

# we use Class::Tiny below

use Class::Tiny::ConstrainedAccessor asset => [
    sub {
        eval { $_[0]->DOES('App::hopen::Asset') }
    },
    sub { ($_[0] // '<undef>') . ' is not an App::hopen::Asset or subclass' }
];

use Class::Tiny qw(asset);

# Docs

=head1 NAME

App::hopen::G::AssetOp - parent class for operations used by a generator to build an asset

=head1 SYNOPSIS

This is an abstract L<App::hopen::G::Cmd> that stores an asset.

=head1 ATTRIBUTES

=head2 asset

An L<App::hopen::Asset> instance.

=cut

1;
__END__
# vi: set fdm=marker: #
