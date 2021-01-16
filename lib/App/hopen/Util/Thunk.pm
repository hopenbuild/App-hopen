# App::hopen::Util::Thunk - Thunk for use in MY.hopen.pl
package App::hopen::Util::Thunk;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use Class::Tiny qw(tgt name);

=head1 NAME

App::hopen::Util::Thunk - Thunk for use in MY.hopen.pl

=head1 SYNOPSIS

    my $answer = 42;
    my $t = App::hopen::Util::Thunk->new(tgt => \$answer, name => 'me!');

NOTE: this would probably be a great use case for L<Data::Thunk>, but that
module is currently unmaintained.

=head1 DESCRIPTION

This module just holds a reference (L</tgt>) and a L</name>.  The name is the name of a
configuration key and the reference points to the value.

This module does not enforce uniqueness or any other properties of the name.
However, L<App::hopen::HopenFileKit/dethunk> and
L<App::hopen::MYhopen/extract_thunks> do enforce conditions on the names; see
L<App::hopen::Manual/Configuration keys>.

=head1 ATTRIBUTES

=head2 tgt

(Required) A reference this thunk refers to, or C<undef>.  If C<undef>,
this thunk represents a value to be filled in.

=head2 name

(Required) A name for this thunk.  Must be truthy (i.e., C<0> is not a
valid name).

=cut

sub BUILD {
    my ($self, $args) = @_;
    die "'tgt' argument is required" unless exists $args->{tgt};
    die "'tgt' argument must be a reference or undef"
        unless !defined($self->tgt) || ref $self->tgt;
    die "'name' argument is required" unless $self->name;
    die "'name' argument must not be a reference" if ref $self->name;
}

1;
__END__
# vi: set fdm=marker: #
