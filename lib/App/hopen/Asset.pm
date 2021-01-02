# App::hopen::Asset - record representing a file to be produced
package App::hopen::Asset;
use strict; use warnings;
use Data::Hopen::Base;

use Path::Class;
use Scalar::Util qw(weaken);
# and we use Class::Tiny below.  This class has no parent.

our $VERSION = '0.000013'; # TRIAL

# Docs {{{1

=head1 NAME

App::hopen::Asset - record representing a file to be produced

=head1 SYNOPSIS

An asset is something to be produced, e.g., a file on disk or something
else that could be a target in a Makefile.

=head1 ATTRIBUTES

=head2 target

TODO: should on-disk targets be required to be BasedPath instances?

The name of the asset.  Must be one of:

=over

=item *

A L<Path::Class> instance, representing a file or directory on disk

=item *

An L<App::hopen::Util::BasedPath> instance, representing a file or directory
on disk

=item *

Something that stringifies to a non-disk target (e.g., a goal).  Anything in
this category will be stored as its stringified value, NOT as its original
value.

=back

No default, so don't call C<< $obj->target >> until you've assigned a target!

=head2 made_by

The L<App::hopen::G::Cmd> (or subclass) instance that produced this asset, or
C<undef>.  Used to distinguish assets from different sources.  Stored as a weak
reference, but will probably be returned as a strong reference --- see
L<Scalar::Util/weaken>.

=head2 name

An optional asset name.  If you don't specify one, a unique one will be
generated automatically.

=head1 METHODS

=cut

# }}}1

# The accessor for the target attribute.
sub target {
    my $self = shift;
    if (@_) {
        my $candidate = shift;
        croak "targets must not be falsy" unless $candidate;
        if(eval { $candidate->DOES('Path::Class::File') ||
            $candidate->DOES('Path::Class::Dir') ||
            $candidate->DOES('App::hopen::Util::BasedPath' ) }
        ) {
            return $self->{target} = $candidate;
        } else {
            return $self->{target} = "$candidate";
        }
    } elsif ( exists $self->{target} ) {
        return $self->{target};
    } else {    # No default.
        croak "I don't have a target to give you";
    }
} #target()

# The accessor for the made_by attribute.  Makes sure values are weak refs.
sub made_by {
    my $self = shift;
    if (@_) {   # Setter
        my $candidate = shift;

        return $self->{made_by} = $candidate unless defined $candidate;
        croak 'made_by values must implement App::hopen::G::Cmd'
            unless eval { $candidate->DOES('App::hopen::G::Cmd') };

        $self->{made_by} = $candidate;
        weaken $self->{made_by};
        return $self->{made_by};    # NOTE: most likely a strong ref

    } else {    # Getter
        return $self->{made_by};
    }
} #made_by()

# Set up the rest of the class
use Class::Tiny qw(target made_by name);

=head2 isdisk

Returns truthy if the L</target> is an on-disk entity, i.e., a
directory or file.

=cut

sub isdisk {
    my $self = shift or croak 'Need an instance';
    return ($self->target->DOES('Path::Class::File') ||
            $self->target->DOES('Path::Class::Dir') ||
            $self->target->DOES('App::hopen::Util::BasedPath')
    );
} #isdisk()

=head2 BUILD

Enforces the requirement for C<target> and C<made_by>.

=cut

my $_id_counter;

sub BUILD {
    my ($self) = @_;
    $self->name('__R_Asset_' . $_id_counter++) unless $self->name;
    # Check the custom constraints by re-setting the values
    $self->target($self->{target});     # Check the custom constraint on target
    $self->made_by($self->{made_by});
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
