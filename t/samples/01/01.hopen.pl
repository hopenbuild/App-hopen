# t/samples/01/01.hopen.pl

#   # TODO use Getargs::Long for arguments to compile or link? - No - too many
#   # deps, and Log::Agent doesn't test successfully on my Cygwin.
#   # Maybe Getargs::Mixed?  It is much simpler and has no non-core deps.

use language 'C';   # uses Build::Hopen::L::C, and makes ::C an alias for it.
    # TODO how to give this compile-time effect?  Keyword::Declare has too
    # many cpantesters failures.  Maybe Keyword::API?  Or some preprocessing
    # in B::H::App::_run_phase()?  Or `use language 'C'` instead?  (That last
    # is the easiest.)

    # *** In _run_phase(), use a package that creates package "language"
    # by hand and fakes out $INC{language}.  Then `use language 'C'` will
    # have the desired effect, but we won't pollute the global namespace
    # with a "language" module.  Also, `use language qw(C Fortran ...)`
    # will work.

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

# Or?---
# C::compile('hello.c') | C::link | $Build->default_goal
#   - This looks nicer, but invokes C::link, in this case, before `|`.
#     As a result, you might need `| &C::link |` or `| 'C::link' |` ---
#     neither is great.

# Or?---
# pipe &C::compile => ['hello.c'], &C::link, $build->default_goal;
#   - Maybe not - don't want to have to take code refs manually if
#     we can help it.
