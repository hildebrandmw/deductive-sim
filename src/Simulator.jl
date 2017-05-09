module Simulator

using VerilogParser
using DataStructures
import Base: getindex, show

export Netlist, simulate, getgate, getoutputs, num_inputs, num_outputs,
   list_faults
#############################################
## Representation of Gate Equations in DNF ##
#############################################
function eval{T <: AbstractArray}(equation::String, nodes::T)::Bool
   return equation_dispatch[equation](nodes)
end

# DNF Conststructors
eq_buf(nodes) =  nodes[1].value
eq_not(nodes) = ~nodes[1].value

function eq_and(nodes)
   for n in nodes
      n.value == false && return false
   end
   return true
end
eq_nand(nodes) = ~eq_and(nodes)

function eq_or(nodes)
   for n in nodes
      n.value == true && return true
   end
   return false
end
eq_nor(nodes) = ~eq_or(nodes)

function eq_xor(nodes)
   val = false
   for n in nodes
      val = xor(val, n.value)
   end
   return val
end
eq_xnor(nodes) = ~eq_xor(nodes)

const equation_dispatch = Dict{String, Function}(
   "not"    => eq_not,
   "buf"    => eq_buf,
   "and"    => eq_and,
   "nand"   => eq_nand,
   "or"     => eq_or,
   "nor"    => eq_nor,
   "xor"    => eq_xor,
   "xnor"   => eq_xnor,
   "input"  => eq_buf,
   "output" => eq_buf,
   "fanout" => eq_buf,
)

##########################
## Fault Representation ##
##########################
struct Fault
   node     ::String
   stuck_at ::Bool
end

show(f::Fault) = print(f.node, " stuck at ", f.stuck_at)


####################
## Gate Data Type ##
####################
mutable struct Gate{T}
   name        ::String
   index       ::Int64
   inputs      ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false}
   outputs     ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false}
   eval        ::Function
   initialized ::Bool

   function Gate{T}(
         name        ::String,
         index       ::Int64,
         inputs      ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false},
         outputs     ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false},
         eval        ::Function,
      ) where T
      return new(name, index, inputs, outputs, eval, false)
   end
   Gate{T}(name::String) where T = new(name)
end

####################
## Node Data Type ##
####################
mutable struct Node
   name                 ::String
   initialized          ::Bool
   value                ::Bool
   stuck_at_one         ::Int64
   stuck_at_zero        ::Int64
   source               ::SubArray{Gate{Node},1,Array{Gate{Node},1},Tuple{Array{Int64,1}},false}
   sink                 ::SubArray{Gate{Node},1,Array{Gate{Node},1},Tuple{Array{Int64,1}},false}
   fault_list           ::Set{Int}

   Node() = new()
   function Node(
      name     ::String,
      source   ::SubArray{Gate{Node}},
      sink     ::SubArray{Gate{Node}},
      )

      return new(
         name,
         false,
         false,
         0,
         0,
         source,
         sink,
         Set{Int64}(),
      )
   end
end

## Fault Collapsing Methods
fc(g::Gate, gate_type::String) = fault_dispatch[gate_type](g)

fc_buf(g::Gate)   = fc_gate(g, 0, 0, 1, 1)
fc_and(g::Gate)   = fc_gate(g, 1, 0, 0, 1)
fc_nand(g::Gate)  = fc_gate(g, 1, 0, 1, 0)
fc_or(g::Gate)    = fc_gate(g, 0, 1, 1, 0)
fc_nor(g::Gate)   = fc_gate(g, 0, 1, 0, 1)
fc_xor(g::Gate)   = fc_gate(g, 1, 1, 1, 1)
fc_fanout(g::Gate)= fc_gate(g, 1, 1, 0, 0)
fc_io(g::Gate)    = return nothing

function fc_gate(g::Gate, in_sa1::Int64, in_sa0::Int64, out_sa1::Int64, out_sa0::Int64)
   for node in g.inputs
      node.stuck_at_one  = in_sa1 | node.stuck_at_one
      node.stuck_at_zero = in_sa0 | node.stuck_at_zero
   end
   for node in g.outputs
      node.stuck_at_one  = out_sa1 | node.stuck_at_one
      node.stuck_at_zero = out_sa0 | node.stuck_at_zero
   end
   return nothing
end

const fault_dispatch = Dict{String, Function}(
   "not"    => fc_buf,
   "buf"    => fc_buf,
   "and"    => fc_and,
   "nand"   => fc_nand,
   "or"     => fc_or,
   "nor"    => fc_nor,
   "xor"    => fc_xor,
   "xnor"   => fc_xor,
   "input"  => fc_io,
   "output" => fc_io,
   "fanout" => fc_fanout,
)

#################################
## Fault Propogation Operators ##
#################################
function fp_to_outputs(g::Gate, fl::Set{Int64})
   for n in g.outputs
      if n.value
         n.fault_list = union(fl, n.stuck_at_zero)
      else
         n.fault_list = union(fl, n.stuck_at_one)
      end
   end

   # Clear Input fault lists. We can do this because no fanout
   for n in g.inputs
      n.fault_list = Set{Int64}()
   end
   return nothing
end

function fp(g::Gate,controlling_logic::Bool,critical_logic::Bool)
   union_list     = Set{Int64}()
   if g.outputs[1].value == critical_logic
      for n in g.inputs
         union!(union_list, n.fault_list)
      end
      return union_list
   end

   intersect_list = Set{Int64}()
   intersect_initialized = false

   for n in g.inputs
      if n.value != controlling_logic
         union!(union_list, n.fault_list)
      else
         if intersect_initialized
            intersect!(intersect_list, n.fault_list)
         else
            intersect_list = n.fault_list
            intersect_initialized = true
         end
      end
   end

   return fp_to_outputs(g, setdiff(intersect_list, union_list))
end

fp_and(g::Gate)   = fp(g, false, true)
fp_nand(g::Gate)  = fp(g, false, false)
fp_or(g::Gate)    = fp(g, true,  false)
fp_nor(g::Gate)   = fp(g, true,  true)

function fp_buf(g::Gate)
   fl = Set{Int64}()
   for n in g.inputs
      union!(fl, n.fault_list)
   end
   fp_to_outputs(g, fl)
   return nothing
end

function fp_output(g::Gate) = return nothing






#######################
## Top Level Netlist ##
#######################
type Netlist
   name        ::String
   gates       ::Vector{Gate{Node}}
   gate_names  ::Dict{String, Int64}
   nodes       ::Vector{Node}
   node_names  ::Dict{String, Int64}
   faults      ::Vector{Fault}
end

# Constructor
function Netlist(file::String)
   netlist = readnetlist(file)

   netlist_name = netlist.name
   # Create Dummy Array for initialization
   gates = [Gate{Node}(i) for i in keys(netlist.gates)]
   gate_names = Dict(b.name=>a for (a,b) in enumerate(gates))

   # Initialize Space
   nodes = [Node() for i = 1:length(netlist.nodes)]
   node_names = Dict{String, Int64}()

   for (i, name) in enumerate(netlist.nodes)
      # Get Sources
      sources = view(gates, [gate_names[i] for i in netlist.node_sources[name]])
      sinks   = view(gates, [gate_names[i] for i in netlist.node_sinks[name]])

      nodes[i] = Node(name, sources, sinks)
      node_names[name] = i
   end

   for i = 1:length(gates)
      name = gates[i].name
      if haskey(netlist.gate_inputs, name)
         inputs = view(nodes, [node_names[i] for i in netlist.gate_inputs[name]])
      else
         inputs = view(nodes, Int64[])
      end

      if haskey(netlist.gate_outputs, name)
         outputs = view(nodes, [node_names[i] for i in netlist.gate_outputs[name]])
      else
         outputs = view(nodes, Int64[])
      end

      eval = equation_dispatch[netlist.gates[name]]
      gates[i] = Gate{Node}(name, i, inputs, outputs, eval)

      fc(gates[i], netlist.gates[name])
   end

   # Collect and categorize faults
   faults = Fault[]
   for node in nodes
      if node.stuck_at_one != 0
         push!(faults, Fault(node.name, true))
         node.stuck_at_one = length(faults)
      end

      if node.stuck_at_zero != 0
         push!(faults, Fault(node.name, false))
         node.stuck_at_zero = length(faults)
      end
   end

   return Netlist(
      netlist_name,
      gates,
      gate_names,
      nodes,
      node_names,
      faults
   )
end

function list_faults(n::Netlist)
   for f in n.faults
      println(f)
   end
   return nothing
end

getgate(n::Netlist, name::String) = n.gates[n.gate_names[name]]
num_inputs(n::Netlist) = length(n.gates[n.gate_names["input"]].outputs)
num_outputs(n::Netlist) = length(n.gates[n.gate_names["output"]].inputs)

function simulate(n::Netlist, values::Vector{Bool}, pq)

   # Get Input Gate
   input_gate = n.gates[n.gate_names["input"]]

   # Iterate through output nodes of the gate, setting values
   # THis assumes values are in order!
   for (value, node) in zip(values, input_gate.outputs)
      setnode!(pq, node, value)
   end

   while length(pq) != 0
      # Get Gate
      gate = n.gates[shift!(pq)]
      processgate!(pq, gate)
   end

   return n
end

function processgate!(pq, g::Gate)
   # Make sure all inputs are initialized
   if !g.initialized
      for node in g.inputs
         node.initialized == false && return nothing
      end
      g.initialized = true
   end

   # Process Gate
   output_value = g.eval(g.inputs)
   for i in g.outputs
      setnode!(pq, i, output_value)
   end
   return nothing
end

function setnode!(pq, n::Node, value::Bool)
   if n.initialized && n.value == value
      return nothing
   end

   n.value = value
   n.initialized = true

   for gate in n.sink
      push!(pq, gate.index)
   end
   return nothing
end

getoutputs(n::Netlist) = [node.value for node in getgate(n, "output").inputs]

end