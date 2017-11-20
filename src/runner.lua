#!/usr/bin/env lua
-- hopen src/runner.lua: Main executable for hopen

-- Constants ----------------------------------------------------------------

local HOPEN_VER = '0.0.1'

local helptext = [[
hopen: Task runner and build system.  By cxw, 2017.
    -n, --dry-run   Show what operations would be run, but don't run them
    -v, --verbose   Extra debug output
    --version       Show the version information

    <goals...> (optional string)
                    Goals to build.  If omitted, all goals will be run.
]]

-- Imports ------------------------------------------------------------------
local print_r = require 'print_r'   -- DEBUG
local core = require 'core'
local lapp = require 'pl.lapp'

-- Collect arguments --------------------------------------------------------

local args = lapp(helptext)
-- Copy remaining args to goals, since in lapp, things after `--` will not be
-- included in goals.
for i=1,#args do
    table.insert(args.goals, args[i])
    args[i] = nil
end

-- --------------------------------------------------------------------------
print_r(args)
if args.version then
    print("hopen version " .. HOPEN_VER)
    return
end

print "hopen isn't here yet!"

