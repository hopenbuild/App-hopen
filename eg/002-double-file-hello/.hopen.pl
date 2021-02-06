# 002-double-file-hello/.hopen.pl

use language 'C';    # uses <toolset>::C, and makes `C` an alias for it.
    # The "language" package is synthesized by Data::Hopen::HopenFileKit.

on check => {};    # Nothing to do during the Check phase

$Build
  ->H::files(qw(hello.c printmsg.c), -name => 'FilesHello') ## Two source files

  # CompileHello will compile both of the C files listed above...
  ->C::compile(-name => 'CompileHello')

  # ... and LinkHello will link them together into a single executable.
  ->C::link('hello', -name => 'LinkHello')

  ->default_goal;
