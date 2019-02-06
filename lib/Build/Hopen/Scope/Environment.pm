# Build::Hopen::Scope::Environment - a hopen Scope for %ENV
package Build::Hopen::Scope::Environment;
use Build::Hopen::Base;
use Build::Hopen qw(hlog);

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::Scope';

use Build::Hopen::Arrrgs;
use Set::Scalar;

# Docs {{{1

=head1 NAME

Build::Hopen::Scope::Environment - a Build::Hopen::Scope of %ENV

=head1 SYNOPSIS

This is a thin wrapper around C<%ENV>, implemented as a
L<Build::Hopen::Scope>.  It only supports one set of data
(L<Build::Hopen::Scope/$set>), which is named C<0> for consistency
with L<Build::Hopen::Scope::Hash>.

=head1 METHODS

=cut

# }}}1

### Protected functions ###

# Don't support -set, but permit `-set=>0` for the sake of code calling
# through the Scope interface.  Call as `_set0($set)`.
# Returns truthy of OK, falsy if not.
# Better a readily-obvious crash than a subtle bug!
sub _set0 {
    my $set = shift;
    return false if defined($set) && $set ne '0';
    return true;
} #_set0()

=head2 _find_here

Find a named data item in C<%ENV> and return it.  Returns undef on
failure.

=cut

sub _find_here {
    my ($self, %args) = parameters('self', [qw(name ; set)], @_);
    _set0 $args{set} or croak 'I only support set 0';
    return $ENV{$args{name}}
} #_find_here()

=head2 add

Updates the corresponding environment variables, in order, by setting C<$ENV{}>.
Returns the instance.

=cut

sub add {
    my $self = shift;
    croak "Got an odd number of parameters" if @_%2;
    while(@_) {
        my $k = shift;
        $ENV{$k} = shift;
    }
    return $self;
} #add()

=head2 _names_here

Add the names in C<%ENV> to the given L<Set::Scalar>.

=cut

sub _names_here {
    my ($self, %args) = parameters('self', [qw(retval ; set)], @_);
    _set0 $args{set} or croak 'I only support set 0';
    hlog { __PACKAGE__ . '::_names_here' };
    $args{retval}->insert(keys %ENV);
    hlog { Dumper $args{retval} };
} #_names_here()

1;
__END__
# vi: set fdm=marker: #
