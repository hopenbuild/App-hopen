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

=head2 made_from

Optional arrayref of Assets used in producing this asset.

TODO store these as weak references, and enforce that each entry be an Asset.
Note that copying a weak reference creates a strong reference --- see
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

# Set up the rest of the class
use Class::Tiny qw(target name), {
   made_from => sub { [] },
};

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

Enforces the requirement for C<target> and C<made_from>.

=cut

my $_id_counter;

sub BUILD {
    my ($self) = @_;
    $self->name('__R_Asset_' . $_id_counter++) unless $self->name;
    # Check the custom constraints by re-setting the values
    $self->target($self->{target});
    $self->made_from($self->{made_from});
} #BUILD()

1;
__END__
# vi: set fdm=marker: #
