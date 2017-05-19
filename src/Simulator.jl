module Simulator

using VerilogParser
using DataStructures
import Base: getindex, show, start, next, done, length, ==

export Netlist, simulate, getgate, getnode, getoutputs, num_inputs, num_outputs,
   list_faults, reset_faults!, Fault

###################################
## Like Subarrays, but different ##
###################################

struct SubSlice{T}
   parent   ::Vector{T}
   indices  ::Array{Int64,1}

   function SubSlice(
      parent::Vector{T},
      indices::Array{Int64,1}
      ) where T

      for i in indices
         checkbounds(Bool, parent, i) || error("Faulty Build")
      end

      return new{T}(parent, indices)
   end
end

length(a::SubSlice)                       = length(a.indices)
getindex(a::SubSlice, i::Int64)           = a.parent[a.indices[i]]
start(a::SubSlice)                        = 1
@inbounds next(a::SubSlice, state::Int64) = a.parent[a.indices[state]], state+1
done(a::SubSlice, state::Int64)           = state > length(a.indices)


#############################################
## Representation of Gate Equations in DNF ##
#############################################
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
==(a::Fault, b::Fault) = a.node == b.node && a.stuck_at == b.stuck_at

show(f::Fault) = print(f.node, " stuck at ", f.stuck_at)


####################
## Gate Data Type ##
####################
mutable struct Gate{T}
   name        ::String
   typestring  ::String
   index       ::Int64
   inputs      ::SubSlice{T}
   outputs     ::SubSlice{T}
   eval        ::Function
   propogate   ::Function

   function Gate{T}(
         name        ::String,
         typestring  ::String,
         index       ::Int64,
         inputs      ::SubSlice{T},
         outputs     ::SubSlice{T},
         eval        ::Function,
         propogate   ::Function,
      ) where T
      return new(name, typestring, index, inputs, outputs, eval, propogate)
   end
   Gate{T}(name::String) where T = new(name)
end

####################
## Node Data Type ##
####################
mutable struct Node
   name                 ::String
   value                ::Bool
   stuck_at_one         ::Int64
   stuck_at_zero        ::Int64
   source               ::SubSlice{Gate{Node}}
   sink                 ::SubSlice{Gate{Node}}
   fault_list           ::Set{Int}

   Node() = new()
   function Node(
      name     ::String,
      source   ::SubSlice{Gate{Node}},
      sink     ::SubSlice{Gate{Node}},
      )

      return new(
         name,
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
fc(g::Gate) = fault_dispatch[g.typestring](g)

fc_buf(g::Gate)   = fc_gate(g,  0,  0,  1,  1)
fc_and(g::Gate)   = fc_gate(g,  1,  0,  0,  1)
fc_nand(g::Gate)  = fc_gate(g,  1,  0,  1,  0)
fc_or(g::Gate)    = fc_gate(g,  0,  1,  1,  0)
fc_nor(g::Gate)   = fc_gate(g,  0,  1,  0,  1)
fc_fanout(g::Gate)= fc_gate(g,  1,  1,  0,  0)
fc_null(g::Gate) = return nothing

function fc_gate(g::Gate, in_sa1::Int64, in_sa0::Int64, out_sa1::Int64, out_sa0::Int64)
   for node in g.inputs
      in_sa1 >= 0 && (node.stuck_at_one  = in_sa1)
      in_sa0 >= 0 && (node.stuck_at_zero = in_sa0)
   end
   for node in g.outputs
      out_sa1 >= 0 && (node.stuck_at_one  = out_sa1)
      out_sa0 >= 0 && (node.stuck_at_zero = out_sa0)
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
   "xor"    => fc_null,
   "xnor"   => fc_null,
   "input"  => fc_null,
   "output" => fc_null,
   "fanout" => fc_fanout,
)




#######################
## Top Level Netlist ##
#######################
type Netlist
   name              ::String
   gates             ::Vector{Gate{Node}}
   gate_names        ::Dict{String, Int64}
   process_order     ::Vector{Int64}
   is_queued         ::Vector{Bool}
   nodes             ::Vector{Node}
   node_names        ::Dict{String, Int64}
   faults            ::Vector{Fault}
   fault_detected    ::Vector{Bool}
   fault_simulation  ::Bool
end

# Constructor
function Netlist(file::String)
   netlist = readnetlist(file)

   netlist_name = netlist.name
   # Create Dummy Array for initialization
   gates = [Gate{Node}(i) for i in keys(netlist.gates)]
   gate_names = Dict(b.name=>a for (a,b) in enumerate(gates))

   process_order  = zeros(Int64, length(gates))
   is_queued      = zeros(Bool, length(gates))

   # Initialize Space
   nodes = [Node() for i = 1:length(netlist.nodes)]
   node_names = Dict{String, Int64}()

   for (i, name) in enumerate(netlist.nodes)
      # Get Sources
      sources  = SubSlice(gates, [gate_names[i] for i in netlist.node_sources[name]])
      sinks    = SubSlice(gates, [gate_names[i] for i in netlist.node_sinks[name]])

      nodes[i] = Node(name, sources, sinks)
      node_names[name] = i
   end

   for i = 1:length(gates)
      name = gates[i].name
      if haskey(netlist.gate_inputs, name)
         inputs = SubSlice(nodes, [node_names[i] for i in netlist.gate_inputs[name]])
      else
         inputs = SubSlice(nodes, Int64[])
      end

      if haskey(netlist.gate_outputs, name)
         outputs = SubSlice(nodes, [node_names[i] for i in netlist.gate_outputs[name]])
      else
         outputs = SubSlice(nodes, Int64[])
      end

      typestring = netlist.gates[name]
      eval = equation_dispatch[netlist.gates[name]]
      prop = fault_prop_dispatch[netlist.gates[name]]

      gates[i] = Gate{Node}(name, typestring, i, inputs, outputs, eval, prop)

      #fc(gates[i], netlist.gates[name])

   end
   faults            = Fault[]
   fault_detected    = Bool[]
   fault_simulation  = false

   n = Netlist(
      netlist_name,
      gates,
      gate_names,
      process_order,
      is_queued,
      nodes,
      node_names,
      faults,
      fault_detected,
      fault_simulation,
   )

   order_gates!(n)
   reset_faults!(n)

   return n
end

function list_faults(n::Netlist)
   for f in n.faults
      println(f)
   end
   return nothing
end

getgate(n::Netlist, name::String) = n.gates[n.gate_names[name]]
getnode(n::Netlist, name::String) = n.nodes[n.node_names[name]]
num_inputs(n::Netlist) = length(n.gates[n.gate_names["input"]].outputs)
num_outputs(n::Netlist) = length(n.gates[n.gate_names["output"]].inputs)

function clean_faults!(n::Netlist)
   output_gate = getgate(n, "output")

   for node in output_gate.inputs, f in node.fault_list
      # Check for null fault and continue if found
      f == 0 && continue

      # Process fault - Make as detected and remove from netlist
      if !n.fault_detected[f]
         n.fault_detected[f] = true
         fault = n.faults[f]
         faulty_node = getnode(n, fault.node)
         if fault.stuck_at
            faulty_node.stuck_at_one = 0
         else
            faulty_node.stuck_at_zero = 0
         end
      end

   end

   #=
   for node in n.nodes
      node.fault_list = Set{Int64}()
   end
   =#

   return nothing
end

function order_gates!(n::Netlist)
   index = 1

   initialized = Dict(i => false for i in keys(n.node_names))

   pq = CircularDeque{Int64}(length(n.gates))
   is_queued = zeros(Bool, length(n.gates))

   # Set inputs to zero
   input_gate_index  = n.gate_names["input"]
   input_gate        = n.gates[input_gate_index]

   push!(pq, input_gate_index)

   while !isempty(pq)
      g = shift!(pq)
      is_queued[g] = false
      # Check if gate can be processed
      can_process = true
      for node in n.gates[g].inputs
         if initialized[node.name] == false
            can_process = false
            break
         end
      end
      # Don't process gate yet
      can_process || continue

      n.process_order[index] = g
      index += 1

      for node in n.gates[g].outputs
         initialized[node.name] = true
         for gate in node.sink
            is_queued[gate.index] && continue
            push!(pq, gate.index)
            is_queued[gate.index] = true
         end
      end
   end

   return nothing
end

function reset_faults!(n::Netlist)
   for i in n.process_order
      gate = n.gates[i]
      fc(gate)
   end

   n.is_queued .= false

   # Collect and categorize faults
   faults = Fault[]
   for node in n.nodes
      if node.stuck_at_one != 0
         push!(faults, Fault(node.name, true))
         node.stuck_at_one = length(faults)
      end

      if node.stuck_at_zero != 0
         push!(faults, Fault(node.name, false))
         node.stuck_at_zero = length(faults)
      end

   end
   n.faults = faults
   n.fault_detected = zeros(Bool, length(faults))

   return nothing
end

function simulate(
   n           ::Netlist,
   values      ::Vector{Bool};
   fault_simulation::Bool = false)

   # Get Input Gate
   input_gate_index = n.gate_names["input"]
   input_gate = n.gates[input_gate_index]

   # Iterate through output nodes of the gate, setting values
   # THis assumes values are in order!

   if length(values) == length(input_gate.outputs)
      for i = 1:length(values)
         setnode!(n, input_gate.outputs[i], values[i])
      end
   else
      error("Wrong Number of Inputs")
   end

   n.fault_simulation = fault_simulation

   if fault_simulation
      initialize_fault_lists(input_gate.outputs)
   end

   for gate_index in n.process_order

      n.is_queued[gate_index] || continue

      # Get Gate
      gate = n.gates[gate_index]
      n.is_queued[gate_index] = false

      processgate!(n, gate)
   end

   clean_faults!(n)

   return n
end

function processgate!(n::Netlist, g::Gate)

   # Process Gate
   output_value = g.eval(g.inputs)
   for i in g.outputs
      setnode!(n, i, output_value)
   end
   # Perform fault propogation
   n.fault_simulation && g.propogate(n, g)

   return nothing
end

function setnode!(netlist::Netlist, n::Node, value::Bool)

   n.value = value

   for gate in n.sink
      netlist.is_queued[gate.index] = true
   end
   return nothing
end

getoutputs(n::Netlist) = [node.value for node in getgate(n, "output").inputs]


#################################
## Fault Propogation Operators ##
#################################
function initialize_fault_lists(nodes)
   for n in nodes
      if n.value
         n.fault_list = Set([n.stuck_at_zero])
      else
         n.fault_list = Set([n.stuck_at_one])
      end
   end
   return nothing
end

function fp_to_outputs(n::Netlist, g::Gate, fl::Set{Int64})
   for node in g.outputs
      if node.value
         new_fault_list = union(fl, Set([node.stuck_at_zero]))
      else
         new_fault_list = union(fl, Set([node.stuck_at_one]))
      end
      if new_fault_list != node.fault_list
         node.fault_list = new_fault_list
         for sink in node.sink
            if !n.is_queued[sink.index]
               push!(n.pq, sink.index)
               n.is_queued[sink.index] = true
            end
         end
      end
   end
   return nothing
end

function fp(net::Netlist, g::Gate,controlling_logic::Bool,critical_logic::Bool)
   union_list     = Set{Int64}()
   if g.outputs[1].value == critical_logic
      for n in g.inputs
         union!(union_list, n.fault_list)
      end
      fp_to_outputs(net, g, union_list)
      return nothing
   end

   intersect_list = Set{Int64}()
   intersect_initialized = false

   for n in g.inputs
      if n.value != controlling_logic
         union!(union_list, n.fault_list)
      else
         if intersect_initialized
            intersect_list = intersect(intersect_list, n.fault_list)
         else
            intersect_list = n.fault_list
            intersect_initialized = true
         end
      end
   end

   fp_to_outputs(net, g, setdiff(intersect_list, union_list))

   return nothing
end

fp_and(n::Netlist, g::Gate)   = fp(n, g, false, true)
fp_nand(n::Netlist, g::Gate)  = fp(n, g, false, false)
fp_or(n::Netlist, g::Gate)    = fp(n, g, true,  false)
fp_nor(n::Netlist, g::Gate)   = fp(n, g, true,  true)

function fp_buf(net::Netlist, g::Gate)
   fl = Set{Int64}()
   for n in g.inputs
      union!(fl, n.fault_list)
   end
   fp_to_outputs(net, g, fl)
   return nothing
end

fp_output(n::Netlist, g::Gate) = return nothing
fp_input(n::Netlist, g::Gate) = fp_to_outputs(n, g, Set{Int64}())
fp_fanout(n::Netlist, g::Gate) = fp_to_outputs(n, g, g.inputs[1].fault_list)

function fp_xor(n::Netlist, g::Gate)
   fl1 = g.inputs[1].fault_list
   fl2 = g.inputs[2].fault_list
   fl = setdiff(union(fl1, fl2), intersect(fl1, fl2))
   fp_to_outputs(n, g, fl)
   return nothing
end

const fault_prop_dispatch = Dict{String, Function}(
   "not"    => fp_buf,
   "buf"    => fp_buf,
   "and"    => fp_and,
   "nand"   => fp_nand,
   "or"     => fp_or,
   "nor"    => fp_nor,
   "xor"    => fp_xor,
   "xnor"   => fp_xor,
   "input"  => fp_input,
   "output" => fp_output,
   "fanout" => fp_fanout,
)

end
