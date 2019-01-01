# Build::Hopen::G::Node - base class for hopen nodes
package Build::Hopen::G::Node;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000001';

use parent 'Build::Hopen::G::Entity';
#use Class::Tiny;

=head1 NAME

Build::Hopen::G::Node - The base class for all hopen nodes

=cut

#DEBUG: sub BUILD { use Data::Dumper; say __PACKAGE__,Dumper(\@_); }
1;
__END__
# vi: set fdm=marker: #
