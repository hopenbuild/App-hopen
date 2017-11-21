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
--- These are the vertices stored in the graph.

local Node = class()
Node._name = 'Node'

-- Initialize a node with an operation
function Node:_init(op)
    self.op = op
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

    self._graph = graph.create(0, true)     -- true => directed

    -- Create the root node
    self._root = Node(false)            -- false => no operation
    self._graph:addVertexIfNotExists(self._root)
    self._nodes_by_op = {}              -- map operations to nodes

end

--- Internal functions ------------------------

--- Add a Node for op and return it
function DAG:_addNode(op)
    local node = Node(op)
    self._graph:addVertexIfNotExists(node)
    self._nodes_by_op[op] = node
    return node
end

--- Find an edge from v to w
function DAG:_findEdge(v,w)
    local adj_v = self._graph:adj(v)
    for i = 0, adj_v:size()-1 do
        local edge = adj_v.get(i)
        if edge:other(v) == w then
            return edge
        end
    end
    return false
end

function DAG:goal(name)
    checks('string')
    local g = Goal(name)

    local node = self:_addNode(g)
    self._graph:addEdge(self._root, node)  -- Edge FROM self._root to node.
    return g
end

function DAG:set_default(goal)
    if not goal then
        self.default_goal = false
    else
        local node = self._nodes_by_op[goal]
        assert(node, 'Call goal() before set_default(goal)')
        assert(self._graph.vertexList:contains(node), 'Unknown node for goal')
        self.default_goal = goal
    end
end

function DAG:connect(from_op, out_edge, in_edge, to_op)
    if in_edge == nil and to_op == nil then
        -- two-arg: dependency edge, but no data transfer
        local from = from_op
        local to_op = out_edge

        -- go from an operation to its node, if any
        local from_node = self._nodes_by_op[from]
        local to_node = self._nodes_by_op[to]

        -- Add vertices if necessary
        if not from_node then
            from_node = self:_addNode(from_op)
        end
        if not to_node then
            to_node = self:_addNode(to_op)
        end

        -- Add edge from #to to #from (edges run away from the sink)
        self._graph:addEdge(to_op, from_op)
    else
        -- four-arg: dependency edge and data transfer
        self:connect(from_op, to_op)   -- make the edge

        -- Associate the edge with a data transfer

        local from_node = self._nodes_by_op[from_op]
        local to_node = self._nodes_by_op[to_op]
        local edge = self:_findEdge(from_node, to_node)
        assert(edge, 'Could not find edge')

        -- TODO add or populate a table associated with #edge that will
        -- hold injected operations, then fill that table with data transfers.
    end
end

function DAG:traverse(goal)
    self.results = {}
    -- TODO get topo-sort
    -- TODO DFS from #goal, or the root.
    -- TODO walk the topo-sort in reverse order, visiting nodes the DFS saw.
end

function DAG:inject(op1, op2, is_after)
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
