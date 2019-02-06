# Build::Hopen::TEMPLATE - template for a hopen module
package Build::Hopen::TEMPLATE;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000006'; # TRIAL

# TODO if using exporter
use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw();
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

# TODO if a class
use parent 'TODO';
use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

Build::Hopen::TEMPLATE - The great new Build::Hopen::TEMPLATE

=head1 SYNOPSIS

TODO

=cut

# }}}1

=head1 FUNCTIONS

=head2 todo

=cut

sub todo {
    my $self = shift or croak 'Need an instance';
    ...
} #todo()

# TODO if using a custom import()
#sub import {    # {{{1
#} #import()     # }}}1

#1;
__END__
# vi: set fdm=marker: #
