# Build::Hopen::ScopeENV - a hopen Scope for %ENV
package Build::Hopen::ScopeENV;
use Build::Hopen::Base;
use Build::Hopen qw(hlog);

our $VERSION = '0.000005'; # TRIAL

use parent 'Build::Hopen::Scope';

use Set::Scalar;

# Docs {{{1

=head1 NAME

Build::Hopen::ScopeENV - a Build::Hopen::Scope of %ENV

=head1 SYNOPSIS

This is a thin wrapper around C<%ENV>, implemented as a
L<Build::Hopen::Scope>.

=head1 METHODS

=cut

# }}}1

### Protected functions ###

=head2 _find_here

Find a named data item in C<%ENV> and return it.  Returns undef on
failure.

=cut

sub _find_here {
    $ENV{$_[1]}
} #_find_here()

=head2 add

Updates the corresponding environment variables, in order, by setting C<$ENV{}>.
Returns the instance.

=cut

sub add {
    my $self = shift;
    while(@_) {
        my $k = shift;
        $ENV{$k} = shift;
    }
    croak "Got an odd number of parameters" if @_;
    return $self;
} #add()

=head2 adopt_hash

Not supported.

=cut

sub adopt_hash { ... }

=head2 _names_here

Add the names in C<%ENV> to the given L<Set::Scalar>.

=cut

sub _names_here {
    my $set = $_[1];
    hlog { __PACKAGE__ . '::_names_here' };
    $set->insert(keys %ENV);
    hlog { Dumper $set };
} #_names_here()

1;
__END__
# vi: set fdm=marker: #
