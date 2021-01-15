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

This module just holds a reference and a name.  The name is the name of a
configuration key and the reference points to the value.


=head1 ATTRIBUTES

=head2 tgt

(Required) A reference this thunk refers to.

=head2 name

(Required) A name for this thunk.

=cut

sub BUILD {
    my $self = shift;
    die "'tgt' argument is required" unless $self->tgt;
    die "'tgt' argument must be a reference" unless ref $self->tgt;
    die "'name' argument is required" unless $self->name;
    die "'tgt' argument must not be a reference" if ref $self->name;
}

1;
__END__
# vi: set fdm=marker: #
