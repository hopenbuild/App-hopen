# App::hopen::Lang - base class for a language-support package (LSP)
package App::hopen::Lang;
use Data::Hopen;
use strict;
use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000013';    # TRIAL

use Class::Tiny;

# Docs {{{1

=head1 NAME

App::hopen::Lang - base class for a language-support package (LSP)

=head1 SYNOPSIS

A class C<< App::hopen::Lang::<language name> >>, and its subclasses,
provide information needed for a particular language.  For example,
LSPs find dependencies.
See L<App::hopen::Manual/COMPONENTS USED BY THE BUILD SYSTEM>
for more information.

Different languages have different LSPs because they have different ways of
representing dependencies.  For example, Vala's C<--pkg foo> might be
equivalent to C's C<-I/usr/include/foo -L/usr/lib/foo -lfoo>.

Throughout this document, toolset C<Gnu> and language C<C> are used as
examples.

=head1 STRUCTURE OF AN LSP

Each LSP supports one language, independent of toolset and generator.
For example, in C, making a program requires include paths, library
paths, and libraries.  The C LSP provides facilities to determine those
for a given library.  It is up to the toolset how to use the information
from the LSP.

=head1 ATTRIBUTES

TODO

=head1 METHODS

=cut

# }}}1

=head2 find_deps

Find dependencies.  Usage:

    my $hrDeps = $lang->find_deps(\%deps[, \%choices])

If C<%choices> are provided, they are used as is --- the assumption is that
those are the user's choices.

=cut

sub find_deps {
    my ($self, %args) = getparameters('self', [qw(deps ; choices)], @_);
    ...;
}

1;
__END__
# vi: set fdm=marker: #
