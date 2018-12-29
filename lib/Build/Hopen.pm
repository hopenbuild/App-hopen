package Build::Hopen;
use Build::Hopen::Base;

our $VERSION = '0.000001';

1; # End of Build::Hopen
__END__

=head1 NAME

Build::Hopen - A build generator with first-class edges and explicit dependencies

=head1 SYNOPSIS

Input is the last-sorting file in C<.> matching C<*.hopen>, unless you
specify otherwise.  That way you can call your build file C<.hopen> if
you want it hidden, or C<z.hopen> if you want it to sort below all your other
files.  Sort order is Lua's C<<>, which is by byte value.

Output is a build file for a build system (Ninja or Make will
be first).  You will eventually be able to pick a generator, a la CMake.
The invoker will put the selected generator's path
first in C<@INC>, but other than that it's all straight Perl.

=head1 INSTALLATION

Easiest: install C<cpanminus> if you don't have it - see
L<https://metacpan.org/pod/App::cpanminus#INSTALLATION>.  Then run
C<cpanm Build::Hopen>.

Manually: clone or untar into a working directory.  Then, in that directory,

    perl Makefile.PL
    make
    make test

... and if all the tests pass,

    make install

If some of the tests fail, please check the issues and file a new one if
no one else has reported the problem yet.

=head1 AUTHOR

Christopher White, C<< <cxwembedded at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Build::Hopen

You can also look for information at:

=over 4

=item * GitHub (report bugs here)

L<https://github.com/cxw42/hopen>

=item * MetaCPAN

L<https://metacpan.org/release/Build-Hopen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Build-Hopen>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Build-Hopen>

=back

=head1 INSPIRED BY

=over

=item *

L<Luke|https://github.com/gvvaughan/luke>

=item *

a bit of L<Ant|https://ant.apache.org/>

=item *

a tiny bit of L<Buck|https://buckbuild.com/concept/what_makes_buck_so_fast.html>

=item *

my own frustrations working with CMake.

=back

=head1 INTERNALS

 - C<Op>: A class representing an operation
   - C<Op:run()> takes a table of inputs and returns a table of outputs.
   - C<Op:describe()> returns a table listing those inputs and outputs.


=head2 Implementation


After the C<hopen> file is processed, cycles are detected and reported as
errors.  *(TODO change this to support LaTeX multi-run files?)*  Then the DAG
is traversed, and each operation writes the necessary information to the
file being generated.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 Christopher White

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut
