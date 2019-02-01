# t/samples/01/01.hopen.pl

#   # TODO use Getargs::Long for arguments to compile or link? - No - too many
#   # deps, and Log::Agent doesn't test successfully on my Cygwin.
#   # Maybe Getargs::Mixed?  It is much simpler and has no non-core deps.

use language 'C';   # uses Build::Hopen::L::C, and makes ::C an alias for it.
    # The "language" package is synthesized by Build::Hopen::HopenFileKit.

$Build->C::compile('hello.c')->C::link->default_goal;
    # A fluent interface provided by the DAG in cooperation with the BHL::*
    # routines.  This compiles as:
    #   default_goal(
    #       C::link(
    #           C::compile($Build, 'hello.c')
    #       )
    #   )
    # so if the BHL routines return something that encapsulates the DAG
    # and various actions on it, you can write chains of this type.

# TODO? use Sub::Attribute or Attribute::Handlers to make it easier to write
# routines such as C::compile.  E.g.,
#   sub compile :foo { ... }
# and compile()'s $_[0] will be wrapped in the fluent interface if it's
# a raw DAG.
