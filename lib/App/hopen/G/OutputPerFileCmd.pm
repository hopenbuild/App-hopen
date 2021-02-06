# App::hopen::G::OutputPerFileCmd - hopen Cmd that makes outputs from input separately
package App::hopen::G::OutputPerFileCmd;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use parent 'App::hopen::G::Cmd';
use Class::Tiny { _stash => +{}, };

use Data::Hopen::Util::Data qw(fwdopts);

# Docs {{{1

=head1 NAME

App::hopen::G::OutputPerFileCmd - hopen Cmd that makes outputs for each input separately

=head1 SYNOPSIS

In a Cmd package:

    use parent 'App::hopen::G::OutputPerFileCmd';
    use Class::Tiny;
    sub Gen {   # runs during the Gen phase
        my ($self, $source_asset) = @_;
            # $source_asset is an App::hopen::Asset
        ... # Return a list of [$asset, $how] arrayrefs
    }

=cut

# }}}1

=head1 FUNCTIONS

=head2 Check, Gen, Build

TODO RESUME HERE:

    - In the Check phase, commands output { 'config key' => Thunk }*.
    - In the Gen phase, commands output `made`.
    - All local inputs, plus command outputs, are passed along as outputs
        to the next node in the chain.  In this way, configuration keys are
        made available to downstream nodes.
    - Add helper functions (here or elsewhere) to retrieve a configuration
        value's Thunk, setting a default if it doesn't exist.
    - The data hashref from MY.hopen.pl will have all the config values,
        possibly including user changes.  Add that as a scope inward of
        the system environment.

Makes output assets for a given input asset.  Must be implemented
by subclasses.  Called as:

    $self->FOO(-asset=>$asset,
        -visitor=>$visitor);

where FOO is a valid phase from L<App::hopen::AppUtil/PHASES> (as of writing,
C<Check>, C<Gen>, or C<Build>).
Should return a list of asset(s).  May also put data in hashref
C<< $self->_stash >>; that data will also be output from the node.

=cut

# These are not defined by default --- _run() checks for them using
# UNIVERSAL::can().
#sub Check { }
#sub Gen { }
#sub Build { }

=head2 _run

Creates the output list by calling phase-specific functions, if they exist.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(visitor ; *)], @_);
    my @visitor_if_any = fwdopts(%args, ['visitor']);

    my $routine = $self->can($self->getphase);

    return $self->passthrough(-nocontext => 1) unless $routine;

    hlog { Node => $self->name, running => $self->getphase } 3;

    if($self->getphase eq 'Gen') {

        # Pull the inputs
        my $lrSourceFiles = $self->input_assets;
        unless(@$lrSourceFiles) {
            warn $self->name . ': no inputs --- skipping';
            return;
        }
        hlog { 'found inputs', Dumper($lrSourceFiles) } 2;

        my @outputs;
        $self->_stash(+{});
        foreach my $src (@$lrSourceFiles) {
            my $obj = $self->$routine(-asset => $src, @visitor_if_any);
            $obj->made_from([$src]) unless @{ $obj->made_from };
            push @outputs, $obj;
        }

        $self->make(@outputs);

    } else {    # not Gen
        $self->_stash(+{});
        $self->$routine(@visitor_if_any);
    }

    return $self->_stash;
} ## end sub _run

1;
__END__
# vi: set fdm=marker: #
