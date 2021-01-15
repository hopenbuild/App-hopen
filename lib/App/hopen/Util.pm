package App::hopen::Util;
our $VERSION = '0.000013'; # TRIAL

# Docs {{{1

=head1 NAME

App::hopen::Util - general utilities for App::hopen

=cut

use strict; use warnings;
use parent 'Exporter';
use vars::i {
    '@EXPORT' => [qw(isMYH nicedump)],
    '@EXPORT_OK' => [qw(MYH)]
};
use vars::i '%EXPORT_TAGS' => {
    default => [@EXPORT],
    all => [@EXPORT, @EXPORT_OK],
};

use Data::Dumper;

=head1 CONSTANTS

=head2 MYH

The name C<MY.hopen.pl>, centralized here.  Not exported by default.

=cut

use constant MYH => 'MY.hopen.pl';

=head1 FUNCTIONS

=head2 isMYH

Returns truthy if the given argument is the name of a C<MY.hopen.pl> file.
See also L</MYH>.

=cut

sub isMYH {
    my $name = @_ ? $_[0] : $_;
    return ($name =~ /\b\Q@{[MYH]}\E$/)
} #isMYH()

=head2 nicedump

Return a clean string rendering (from L<Data::Dumper>) of the input(s).  Usage:

    my $string = nicedump(\@vars, \@labels);

=cut

sub nicedump {
    my $dumper = Data::Dumper->new(@_);
    $dumper->Indent(1);         # fixed indent size
    $dumper->Quotekeys(0);
    $dumper->Purity(1);
    $dumper->Maxrecurse(0);     # no limit
    $dumper->Sortkeys(1);       # For consistency between runs
    return $dumper->Dump;
}

1;
