# t/samples/01/01.hopen.pl

use language 'C';   # uses <toolset>::C, and makes `C` an alias for it.
    # The "language" package is synthesized by Build::Hopen::HopenFileKit.

$Build
    ->C::compile('hello.c', -name=>'CompileHello')
    ->C::link('hello', -name=>'LinkHello')
    ->default_goal;
