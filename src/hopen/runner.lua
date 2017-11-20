-- hopen runner.lua: Main executable for hopen.
-- When loaded, returns a function to call to start the show.

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
local core = require 'hopen.core'
local lapp = require 'pl.lapp'

--- The main function.
--- @param args The command-line arguments (default _G.arg)
return function(args)
    -- Collect arguments ----------------------------------------------------

    local arg = args or _G.arg
    local parsed = lapp(helptext, arg)
    -- Copy remaining args to goals, since in lapp, things after `--` will not be
    -- included in goals.
    for i=1,#parsed do
        table.insert(parsed.goals, parsed[i])
        parsed[i] = nil
    end

    -- ----------------------------------------------------------------------
    print_r(parsed)
    if parsed.version then
        print("hopen version " .. HOPEN_VER)
        return
    end

    print "hopen isn't here yet!"
end --main function

