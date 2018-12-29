# Build::Hopen::G::Edge - base class for hopen edges
package Build::Hopen::G::Edge;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000001';

use parent 'Build::Hopen::G::Entity';
use Class::Tiny {
    ops => sub { [] }
};

=head1 NAME

Build::Hopen::G::Edge - The base class for all hopen edges

=head1 VARIABLES

=head2 ops

An arrayref of the operations to be performed while data traverses that
edge.  Operations are performed in order of increasing array index.

=cut

#1;
__END__
# vi: set fdm=marker: #
