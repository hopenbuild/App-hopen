# Build::Hopen::Phase::Probe - probe-phase operations
package Build::Hopen::Phase::Probe;
use Build::Hopen;
use Build::Hopen::Base;
#use parent 'Exporter';

our $VERSION = '0.000003'; # TRIAL

#use Class::Tiny qw(TODO);

# Docs {{{1

=head1 NAME

Build::Hopen::Phase::Probe - Check the build system

=head1 SYNOPSIS

Probe runs first.  Probe reads a foundations file and outputs a capability
file and an options file.  The user can then edit the options file to
customize the build.

Probe also locates context files.  For example, when processing C<~/foo/.hopen>,
Probe will also find C<~/foo.hopen> if it exists.

=cut

# }}}1

=head1 FUNCTIONS

=head2 todo

TODO

=cut

sub todo {
    my $self = shift or croak 'Need an instance';
    ...
} #todo()

#our @EXPORT = qw();
#our @EXPORT_OK = qw();
#our %EXPORT_TAGS = (
#    default => [@EXPORT],
#    all => [@EXPORT, @EXPORT_OK]
#);

#sub import {    # {{{1
#} #import()     # }}}1

#1;
__END__
# vi: set fdm=marker: #
