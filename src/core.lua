-- core.lua: Core types for hopen
-- cxw 2017

require 'pl.strict'
require 'checks'

local class = require 'pl.class'
local graph = require 'luagraphs.data.graph'

--- Generator interface -------------------------------------------------
-- Generators must implement this.

local IGenerator = class()
IGenerator._name = 'IGenerator'

function IGenerator:_init(name)
    self.name = name
    self:init()         -- abstract --- must be implemented in child classes
end

--- Op ------------------------------------------------------------------
local Op = class()
Op._name = 'Op'

-- Default member functions
function Op:run(inputs)
    return {}
end

function Op:describe()
    return {['in']=true, ['out']=false}  -- any inputs; no outputs
end

--- Goal ----------------------------------------------------------------
local Goal = class(Op)
Goal._name = 'Goal'

function Goal:_init(name)
    self.name = name
end

--- DAG node ------------------------------------------------------------
local Node = class()
Node._name = 'Node'

-- Initialize a node with an operation and a vertex number
function Node:_init(op, v)
    self.op = op
    self.v = v
end

function Node:run(inputs)
    if self.op then
        return self.op:run(inputs)
    else
        return {}   -- TODO change?
    end
end

--- DAG -----------------------------------------------------------------
-- Note: Edges are from the root back towards the inputs of the process.
-- This way we can easily pull out the subtree for a particular goal using
-- DFS and run only that goal by only running nodes reached in the DFS as
-- we walk through the topo-sorted vertices.
-- Edges from the root do require that the topo-sort results
-- have to be reversed in order before running the DAG.
-- TODO someday support multi-core-friendly topo-sort, so nodes can run in
-- parallel until they block each other.

local DAG = class()
DAG._name = 'DAG'

function DAG:_init(...)
    self.arg = {...}
    self.default_goal = false
    self.results = false

    self._graph = graph.create(1, true) -- initially, one node (node # 0)
    self._root = Node(false, 0)
    self._nodes = {[0] = self._root}      -- map vertex numbers to nodes.
    self._nodes_by_op = {}              -- map operations to nodes

end

function DAG:goal(name)
    checks('string')
    local g = Goal(name)
    local node = Node(g, -1)    -- TODO add vertex to graph
    self._graph:addEdge(0, -1)  -- TODO add vnum.  Edge FROM self._root (0).
    self._nodes[-1] = node      -- TODO add vnum
    self._nodes_by_op[g] = node
    return g
end

function DAG:set_default(goal)
    self.default_goal = goal or false
end

function DAG:connect(from_op, out_edge, in_edge, to_op)
    if in_edge == nil and to_op == nil then
        -- two-arg: dependency edge, but no data transfer
        local from = from_op
        local to = out_edge
        -- go from an operation to its node, if any
        from = self._nodes_by_op[from]
        to = self._nodes_by_op[to]
        -- Add vertices if necessary
        if not from then
            -- TODO add vertex
            from = Node(from, xx)
        end
        --TODO add edge for `to` if necessary

        -- Add edge from _to_ to _from_.
        self._graph:addEdge(-2,-2)  -- TODO get numbers for from, to
    else
        -- four-arg: dependency edge and data transfer
        self:connect(from_top, to_op)   -- make the edge
        -- TODO associate the edge with a data transfer
    end
end

function DAG:traverse(goal)
    self.results = {}
    -- TODO get topo-sort
    -- TODO DFS from #goal, or the root.
    -- TODO walk the topo-sort in reverse order, visiting nodes the DFS saw.
end

--- Subroutine ----------------------------------------------------------
local Subroutine = class(Op)
Subroutine._name = 'Subroutine'

function Subroutine:_init(name)
    self:super()
    name = name or 'Anonymous'
    self.dag = DAG()
end

function Subroutine:run(inputs)
    self.dag.arg = inputs or {}
    self.dag:traverse()
    return self.dag.results
end

-------------------------------------------------------------------------
return {Op = Op,
        DAG = DAG,
        Subroutine = Subroutine}

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro: --
