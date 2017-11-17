# hopen
A build generator with first-class edges and explicit dependencies

## General

Input is the first-sorting file in `.` matching `*.hopen`, unless you
specify otherwise.  Sort order is Lua's `<`, which is by byte value.

Output is a build file for a build system (Ninja or Make will
be first).  You will eventually be able to pick a generator, a la CMake.
The invoker will put the selected generator's path
first in `LUA_PATH`, but other than that it's all straight Lua.

## Requirements

 - Lua 5.2
 - luarocks
   - [penlight](http://stevedonovan.github.io/Penlight/api/index.html)
   - [luagraphs](https://github.com/chen0040/lua-graph)
   - [checks](https://luarocks.org/modules/luarocks/checks)
     ([docs](https://github.com/SierraWireless/luasched/blob/master/c/checks.c))

## Inspiration

Luke, plus a bit of Ant, and my own frustrations working with CMake

## Plumbing

 - `Op`: A class representing an operation
   - `Op:run()` takes a table of inputs and returns a table of outputs.
   - `Op:describe()` returns a table listing those inputs and outputs.

 - `DAG`: A class representing a DAG.  An instance called `main` represents
   what will be generated.
   - `DAG.arg` holds any parameters passed from outside the DAG
     (see `subroutine` below).
   - `DAG:goal(<name>)`: creates a goal of the DAG.  Goals are names
     for sequences of operations, akin to top-level Makefile targets.
     A `hopen` file with no `main:goal()` calls will result in nothing
     happening when `hopen` is run.
     Returns an instance that can be used as if it were an operation.
     Any inputs passed into that instance are provided as outputs of the DAG.
   - `DAG:set_default(<goal>)`: make `<goal>` the default goal of this DAG
     (default target).
   - `DAG:connect(<op1>, <out-edge>, <in-edge>, <op2>)`:
     connects output `<out-edge>` of operation `<op1>` as input `<in-edge>` of
     operation `<op2>`.  No processing is done between output and input.
     - `<out-edge>` and `<in-edge>` can be anything usable as a table index,
       provided that table index appears in the corresponding operation's
       descriptor.
   - `DAG:connect(<op1>, <op2>)`: creates a dependency edge from `<op1>` to
     `<op2>`, indicating that `<op1>` must be run before `<op2>`.
     Does not transfer any data from `<op1>` to `<op2>`.

  - `Subroutine([name])`: An `Op` subclass representing a DAG.  `sub:run()`
    traverses that DAG.
    The new DAG `dag` is therefore similar to a subroutine, whence the name.
    Inputs to `op` are provided as `dag.arg`.  The outputs from all the goals
    of the DAG are aggregated and provided as the outputs of the DAG.
    *(TODO handle name conflicts between goals)*
    - `sub.dag`: The DAG.  You can use `sub.dag.arg`, `sub.dag:goal()`, ...
      as for any DAG.

## Implementation

Each DAG has a hidden "root" node.  All outputs have edges to the root node.
The traversal order is topological from the root node, but is not constrained
beyond that.  Generators can ask for the nodes in root-first or root-last
order.

The DAG is built backwards from the outputs toward their inputs,
although calls to `output` and `connect` can appear in any order in the `hopen`
file as long as everything is hooked in by the end of the file.

After the `hopen` file is processed, cycles are detected and reported as
errors.  *(TODO change this to support LaTeX multi-run files?)*  Then the DAG
is traversed, and each operation writes the necessary information to the
file being generated.

## License

[LGPL 3.0](LICENSE), or any later version, at your option.

