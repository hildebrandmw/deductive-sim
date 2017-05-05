module SimTypes

using VerilogParser
using DataStructures
import Base: getindex, show

export Netlist, simulate, getgate, getoutputs
#############################################
## Representation of Gate Equations in DNF ##
#############################################
immutable Literal
   index    ::Int
   inverted ::Bool
end

immutable DNF
   dnf   ::Vector{Vector{Literal}}
end

function eval(dnf::DNF, logic::Vector{Bool})
   or_value = false
   for c in clauses(dnf)
      and_value = true
      for i in literals(c)
         and_value &= logic[i.index] $ i.inverted
      end
      or_value |= and_value
      or_value && return true
   end
   return false
end

function eval{T <: AbstractArray}(dnf::DNF, nodes::T)
   or_value = false
   for c in clauses(dnf)
      and_value = true
      for i in literals(c)
         and_value &= nodes[i.index].value $ i.inverted
      end
      or_value |= and_value
      or_value && return true
   end
   return false
end

# DNF Conststructors
function dnf_buf(n)
   L = [Literal(1, false)]
   dnf = DNF([L])
   return dnf
end

function dnf_not(n)
   L = [Literal(1, true)]
   dnf = DNF([L])
   return dnf
end

function dnf_and(n)
   clause = [Literal(i, false) for i = 1:n]
   dnf = DNF([clause])
   return dnf
end

function dnf_nand(n)
   clauses = [[Literal(i, true)] for i = 1:n]
   dnf = DNF(clauses)
   return dnf
end

function dnf_or(n)
   clauses = [[Literal(i, false)] for i = 1:n]
   dnf = DNF(clauses)
   return dnf
end

function dnf_nor(n)
   clause = [Literal(i, true) for i = 1:n]
   dnf = DNF([clause])
   return dnf
end

function dnf_input(n)
   return DNF([[Literal(0, false)]])
end

function dnf_output(n)
   return DNF([[Literal(1, false)]])
end

const dnf_assignment = Dict{String, Function}(
   "not"    => dnf_not,
   "buf"    => dnf_buf,
   "and"    => dnf_and,
   "nand"   => dnf_nand,
   "or"     => dnf_or,
   "nor"    => dnf_nor,
   "input"  => dnf_input,
   "output" => dnf_output
)

function assign_dnf(s::String, n::Integer)::DNF
   return dnf_assignment[s](n)
end

clauses(dnf::DNF) = dnf.dnf
literals(disjunction::Vector{Literal}) = disjunction

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
   equation    ::DNF
   initialized ::Bool
   needs_update::Bool


   function Gate(
         name        ::String,
         index       ::Int64,
         inputs      ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false},
         outputs     ::SubArray{T,1,Array{T,1},Tuple{Array{Int64,1}},false},
         equation    ::DNF,
      )
      return new(name, index, inputs, outputs, equation, false, true)
   end
   Gate(name::String) = new(name)
end

function show(g::Gate)
   print("Gate: ", g.name, ". Inputs:")
   for i in g.inputs
      print(" ",i.name)
   end
   print(". Outputs: ")
   for i in g.outputs
      print(" ",i.name)
   end
   println("")
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

getindex(a::SubArray{Node}, l::Literal) = a[l.index]


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

      dnf = assign_dnf(netlist.gates[name], length(inputs))
      gates[i] = Gate{Node}(name, i, inputs, outputs, dnf)
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

function simulate(n::Netlist, values::Array{Bool}, pq)

   # Get Input Gate
   input_gate = n.gates[n.gate_names["input"]]

   # Iterate through output nodes of the gate, setting values
   # THis assumes values are in order!
   for (value, node) in zip(values, input_gate.outputs)
      setnode!(pq, node, value)
   end

   while length(pq) != 0
      # Get Gate
      @inbounds gate = n.gates[shift!(pq)]
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

   g.needs_update || return nothing

   # Process Gate
   output_value = eval(g.equation, g.inputs)

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
      gate.needs_update = true
   end
   return nothing
end

function getoutputs(n::Netlist)
   # Get Output Gate
   output_gate = n.gates[n.gate_names["output"]]
   return [node.value for node in output_gate.inputs]
end

### Methods
function propogate(dnf::DNF, nodes::SubArray{Node})
   faults = Set{Int64}()

   or_intersection_list       = Set{Int64}()
   or_union_list              = Set{Int64}()
   or_controlling_set_empty   = true

   # Process Clauses
   for c in clauses(dnf)
      and_intersection_list = Set{Int64}()
      and_union_list        = Set{Int64}()
      and_controlling_set_empty  = true
      logic_for_and              = true

      # Process each literal in the clause
      for l in literals(c)
         node = nodes[l]
         logic_for_and &= (node.value $ l.inverted)
         if length(node.fault_list) == 0
            if !node.value
               and_intersection_list = Set{Int64}()
               and_controlling_set_empty = false
            end
         else
            if node.value
               add_union_list = node.fault_list
            else
               intersect!(add_intersection_list, node.fault_list)
               and_controlling_set_empty = false
            end
         end
      end


      if and_controlling_set_empty
         temp_fault_list = add_union_list
      else
         setdiff!(add_intersection_list, add_union_list)
         temp_fault_list = add_intersection_list
      end

      if logic_for_and
         intersect!(or_intersection_list, temp_fault_list)
         or_controlling_set_empty = false
      else
         or_union_list = temp_fault_list
      end
   end

   return or_controlling_set_empty ? or_union_list : setdiff(or_intersection_list, or_union_list)
end


end
