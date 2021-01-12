# App::hopen::Util::Thunk - Thunk for use in MY.hopen.pl
package App::hopen::Util::Thunk;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013'; # TRIAL

use Class::Tiny qw(tgt name);

# Docs {{{1

=head1 NAME

App::hopen::Util::Thunk - Thunk for use in MY.hopen.pl

=head1 SYNOPSIS

    my $answer = 42;
    my $t = App::hopen::Util::Thunk->new(tgt => \$answer, name => 'me!');
    # ... later ...
    is($t->get, 42)     # yes!

NOTE: this would probably be a great use case for L<Data::Thunk>, but that
module is currently unmaintained.

=head1 ATTRIBUTES

=head2 tgt

(Required) A reference this thunk refers to.

=head2 name

(Required) A name for this thunk.

=cut

# }}}1

=head1 METHODS

=head2 get

Returns the referenced value.  TODO document me.

=cut

sub get {
    my $self = shift;
    my $ty = ref($self->tgt);
    if($ty eq 'ARRAY') {
        return @{$self->tgt} if wantarray;
        return $self->tgt;
    } elsif($ty eq 'HASH') {
        return %{$self->tgt} if wantarray;
        return $self->tgt;
    } elsif($ty eq 'CODE') {
        return $self->tgt->();
    } else {
        return ${$self->tgt};
    }
} #todo()

sub BUILD {
    my $self = shift;
    die "'tgt' argument is required" unless $self->tgt;
    die "'tgt' argument must be a reference" unless ref $self->tgt;
    die "'name' argument is required" unless $self->name;
}

1;
__END__
# vi: set fdm=marker: #
