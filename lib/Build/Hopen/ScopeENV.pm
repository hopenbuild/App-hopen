# Build::Hopen::ScopeENV - a hopen Scope for %ENV
package Build::Hopen::ScopeENV;
use Build::Hopen::Base;

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

=head2 find

Find a named data item in C<%ENV> and return it.  Returns undef on
failure.  Does not do any fallback.

=cut

sub find {
    my $self = shift;   # No failure since we actually don't care :)
    my $name = shift or croak 'Need a name';
        # Therefore, '0' is not a valid name

    # Ignore `content`
    return $ENV{$name} if exists $ENV{$name};
    # Ignore `outer` - no fallback

    return undef;   # report failure
} #find()

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

=head2 names

Returns a list of the items available through this Scope, including all its
parent Scopes (if any).

=cut

sub names {
    my $self = shift;
    my $retval = Set::Scalar->new;
    $retval->insert($_) foreach keys %ENV;
    if($self->outer) {
        $retval->insert($_) foreach $self->outer->names;
    }

    return @$retval;
} #names()
1;
__END__
# vi: set fdm=marker: #
