# 003-double-file-double-compile/.hopen.pl

use language 'C';   # uses <toolset>::C, and makes `C` an alias for it.
    # The "language" package is synthesized by Data::Hopen::HopenFileKit.

on check => {};     # Nothing to do during the Check phase

# Executable
my $exe = $Build
    ->C::link('hello', -name=>'LinkHello');
        # link the inputs together into a single executable.

# First source file
my $hello_o = $Build
    ->H::files('hello.c', -name=>'hello.c')
    ->C::compile(-name=>'Compile hello.c');

# Second source file
my $printmsg_o = $Build
    ->H::files('printmsg.c', -name=>'printmsg.c')
    ->C::compile(-name=>'Compile printmsg.c');

# Finally, connect everything together.  The default_goal call should be last.
$hello_o->to($exe);
$printmsg_o->to($exe);
$exe->default_goal;
