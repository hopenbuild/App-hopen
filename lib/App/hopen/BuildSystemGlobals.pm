# Build::Hopen::BuildSystemGlobals - global data for build-system use cases.
package Build::Hopen::BuildSystemGlobals;
use Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000009'; # TRIAL

use parent 'Exporter';
our @EXPORT;
BEGIN { @EXPORT = qw(*Generator *Toolset *Build *Phase *ProjDir *DestDir); }
        # export with `*` => `local` will work.

=head1 NAME

Build::Hopen::BuildSystemGlobals - global data for hopen build-system use cases

=head1 SYNOPSIS

This module exports variables used when employing hopen(1) as a build system.
They are in a separate module so that it's easy to tell which parts of
L<Build::Hopen> I<don't> need them.

=head1 VARIABLES

=head2 $Generator

The current L<Build::Hopen::Gen> instance.

=head2 $Toolset

The name of the current toolset.  Support for language C<Foo> is in
package C<${Toolset}::Foo>.

=head2 $Build

The L<Build::Hopen::G::DAG> instance representing the current build.
Goals in C<$Build> will become, e.g., top-level targets of a
generated C<Makefile>.

=head2 $Phase

Which phase we're in (string).

=head2 $ProjDir

A L<Path::Class::Dir> instance representing the project directory.

=head2 $DestDir

A L<Path::Class::Dir> instance representing the destination directory.

=cut

our ($Generator, $Toolset, $Build, $Phase, $ProjDir, $DestDir);

1;
__END__
# vi: set fdm=marker: #
