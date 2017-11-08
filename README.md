# hopen
A build generator with first-class edges and explicit dependencies

## General

Input is the first-sorting file in `.` matching `*.hopen`, unless you 
specify otherwise.  Output is a build file for a build system (Ninja will
be first).  You will eventually be able to pick a generator, a la CMake.
The invoker will put the selected generator's path
first in `LUA_PATH`, but other than that it's all straight Lua.

## Inspiration

Luke, plus a bit of Ant, and my own frustrations working with CMake

## Plumbing

 - A class representing an operation 
 - `connect(<inputs>,<operation>)`

## License

[LGPL 3.0](LICENSE)

