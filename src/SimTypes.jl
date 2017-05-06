module SimTypes

using VerilogParser
using DataStructures
import Base: getindex, show

export Netlist, simulate, getgate, getoutputs, num_inputs, num_outputs
#############################################
## Representation of Gate Equations in DNF ##
#############################################
function eval{T <: AbstractArray}(equation::String, nodes::T)::Bool
   return equation_dispatch[equation](nodes)
end

# DNF Conststructors
eq_buf(nodes) = nodes[1].value
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
      val $= n.value
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
   "output" => eq_buf
)

##########################
## Fault Representation ##
##########################
immutable Fault
   node     ::String
   stuck_at ::Bool
end

####################
## Gate Data Type ##
####################
type Gate{T}
   name        ::String
   index       ::Int64
   inputs      ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false}
   outputs     ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false}
   eval        ::Function
   initialized ::Bool

   function Gate(
         name        ::String,
         index       ::Int64,
         inputs      ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false},
         outputs     ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false},
         eval        ::Function,
      )
      return new(name, index, inputs, outputs, eval, false)
   end
   Gate(name::String) = new(name)
end

####################
## Node Data Type ##
####################
type Node
   name                 ::String
   initialized          ::Bool
   value                ::Bool
   yields_stuck_at_one  ::Bool
   yields_stuck_at_zero ::Bool
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
         false,
         false,
         source,
         sink,
         Set{Int64}(),
      )
   end
end

#######################
## Top Level Netlist ##
#######################
type Netlist
   name        ::String
   gates       ::Vector{Gate{Node}}
   gate_names  ::Dict{String, Int64}
   nodes       ::Vector{Node}
   node_names  ::Dict{String, Int64}
   #faults      ::Vector{Fault}
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
   end

   return Netlist(
      netlist_name,
      gates,
      gate_names,
      nodes,
      node_names,
   )
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
