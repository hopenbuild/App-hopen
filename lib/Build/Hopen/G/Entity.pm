# Build::Hopen::G::Entity - base class for hopen's data model
package Build::Hopen::G::Entity;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000003'; # TRIAL

use Class::Tiny qw(name);

=head1 NAME

Build::Hopen::G::Entity - The base class for all hopen nodes and edges

=head1 SYNOPSIS

hopen creates and manages a graph of entities: nodes and edges.  This class
holds common information.

=head1 MEMBERS

=head2 name

The name of this entity.  The name is for human consumption and is not used by
hopen to make any decisions.  However, node names starting with an underscore
are reserved for hopen's internal use.

=cut

1;
__END__
# vi: set fdm=marker: #
