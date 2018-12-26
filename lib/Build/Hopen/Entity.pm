# Build::Hopen::Entity - base class for hopen's data model
package Build::Hopen::Entity;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000001';

use Class::Tiny qw(name);

=head1 NAME

Build::Hopen::Entity - The base class for all hopen nodes and edges

=head1 SYNOPSIS

hopen creates and manages a graph of entities: nodes and edges.  This class
holds common information.  For now, that is nothing but a node name.  The name
is for human consumption and is not used by hopen to make any decisions.

=cut

#1;
__END__
# vi: set fdm=marker: #
