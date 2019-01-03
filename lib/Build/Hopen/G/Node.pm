# Build::Hopen::G::Node - base class for hopen nodes
package Build::Hopen::G::Node;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use parent 'Build::Hopen::G::Entity';
use Class::Tiny {
    outputs => sub { +{} }
};

=head1 NAME

Build::Hopen::G::Node - The base class for all hopen nodes

=head1 VARIABLES

=head2 outputs

Hashref of the outputs from the last time this node was run.  Default C<{}>.

=cut

#DEBUG: sub BUILD { use Data::Dumper; say __PACKAGE__,Dumper(\@_); }
1;
__END__
# vi: set fdm=marker: #
