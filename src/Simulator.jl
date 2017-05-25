module Simulator

#using SortedOpsBad
using SortedOps
using VerilogParser
using DataStructures
import Base: getindex, show, start, next, done, length, ==

export Netlist, simulate, getgate, getnode, getoutputs, num_inputs, num_outputs,
   list_faults, reset_faults!, Fault

################################################################################
##                            Define Subslices                                ##
################################################################################

#=
Gates and nodes will be stored in arrays. The subslice is how I will encode
adjacency information.

Each Gate will have a subslice for input and output nodes where the subsclice
is just a view of the Node array.

Nodes will be treated similarly.

By implementing the iterator framework, I can greatly clean up the code involved
in accessing these subarrays.
=#
"""
    SubSlice{T}

A `SubSlice` is like a `SubArray` in Julia, but more optimized for the purposes
at hand. The main assumption is that the `parent` array (of which the `parent`
field is a reference) will not change, thus iterations can be performed without
bounds checking. The `indices` field an array of indices of `parent` that this
SubSlice refers to.

Methods available for this type: `length`, `getindex`, and the basic iterator
framework.
"""
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

# Return element in parent array
getindex(a::SubSlice, i::Int64)           = a.parent[a.indices[i]]

# Iterator Framework
length(a::SubSlice)                       = length(a.indices)
start(a::SubSlice)                        = 1
@inbounds next(a::SubSlice, state::Int64) = a.parent[a.indices[state]], state+1
done(a::SubSlice, state::Int64)           = state > length(a.indices)


################################################################################
##                            Gate Logic Functions                            ##
################################################################################

#=
This will be the collection of methods for logic evaluation. Each gate will have
a field that contains a reference to one of these functions depending on the
type of the gate.

The main assumption is that an array (or rather, a subarray) of nodes
corresponding to the inputs of the gate will be passed to the equation function.
The return value is a single boolean value which is the logic output of the gate.
=#

eq_buf(nodes)::Bool =  nodes[1].value     # Return input
eq_not(nodes)::Bool = ~nodes[1].value     # Return negation of input

# Short circuit evaulation for efficiency.
function eq_and(nodes)::Bool
   for n in nodes
      n.value == false && return false
   end
   return true
end

# Just negate the result of the AND equation
 eq_nand(nodes)::Bool = ~eq_and(nodes)

# Short circuit evaluation for efficiency
 function eq_or(nodes)::Bool
   for n in nodes
      n.value == true && return true
   end
   return false
end

# Just negate the result of the OR equation
eq_nor(nodes) = ~eq_or(nodes)

# No way to make this super fast. Must iterate.
function eq_xor(nodes)
   val = false
   for n in nodes
      val = xor(val, n.value)
   end
   return val
end

# Negate output.
eq_xnor(nodes) = ~eq_xor(nodes)

#=
This guy is a dictionary to function reference. The type string of the gate
is provided and the correct logic function is returned. Very handy and clean
way of doing the function dispatch.
=#
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

################################################################################
##                         Fault Representation                               ##
################################################################################

"""
   Fault

Simple lightweight data type for representing faults. Field `node::String` is
the name of the node this fault is referencing. Field `stuck_at::Bool = true` if
represented fault is stuck-at-one, otherwise `stuck_at = false` for a
stuck-at-zero fault.
"""
struct Fault
   node     ::String
   stuck_at ::Bool
end
==(a::Fault, b::Fault) = a.node == b.node && a.stuck_at == b.stuck_at
show(f::Fault) = print(f.node, " stuck at ", f.stuck_at)


################################################################################
##                               Gate Data Type                               ##
################################################################################

#=
I have to parameterize this because the Gate type and Node type are circular.
=#

"""
    Gate{T}

Data Structure for a Gate.
"""
mutable struct Gate{T}
   # Name of the gate
   name        ::String

   # String describing the type of gate (and, or, nor etc.)
   typestring  ::String

   # Index in array of all gates in the desing
   index       ::Int64

   # Input and Output nodes
   inputs      ::SubSlice{T}
   outputs     ::SubSlice{T}

   # Function for gate logic evaulation
   eval        ::Function

   # Function for fault list propagation.
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
   # Incomplete constructor for building initial copy for the circular representation.
   Gate{T}(name::String) where T = new(name)
end

################################################################################
##                            Node Data Type                                  ##
################################################################################

"""
   Node

Data Structure for a Node
"""
mutable struct Node
   # Name of the node
   name                 ::String

   # Current logic value of the node
   value                ::Bool

   #=
   Indices of the SA1 and SA0 faults for this gate. These will be 0 if that
   particular fault is not being searched for, has been collapsed, or dropped.
   =#
   stuck_at_one         ::Int64
   stuck_at_zero        ::Int64

   # Adjacency information for source and sink gates
   source               ::SubSlice{Gate{Node}}
   sink                 ::SubSlice{Gate{Node}}

   # List of all faults that will cause a logic error at this node.
   fault_list           ::Vector{Int64}

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
         Int64[],
      )
   end
end

################################################################################
##                         Fault Collapsing Methods                           ##
################################################################################

#=
These are the fault collapsing methods. The assumption is that all faults in the
circuit are initialized to active. Each gate is assigned a "fc_" function
depending on the type. Then, each gate clears the equivalent/dominated faults
for each gate.

After faults have been collapsed, another routine will loop over all nodes in
the circuit and assign each fault an index.
=#

"""
   fc(g::Gate)

Perform fault-collapsing on gate `g`.
"""
fc(g::Gate) = fault_dispatch[g.typestring](g)

#=
Generic function describing which faults to deactivate. This makes the code
base a lot cleaner.
=#
function fc_clear(g::Gate, clear_in_1, clear_in_0, clear_out_1, clear_out_0)
   for node in g.inputs
      clear_in_1 && (node.stuck_at_one = 0)
      clear_in_0 && (node.stuck_at_zero = 0)
   end
   for node in g.outputs
      clear_out_1 && (node.stuck_at_one = 0)
      clear_out_0 && (node.stuck_at_zero = 0)
   end
   return nothing
end

fc_buf(g::Gate)   = fc_clear(g,  true,  true,  false,  false)
fc_and(g::Gate)   = fc_clear(g,  false,  true,  true,  false)
fc_nand(g::Gate)  = fc_clear(g,  false,  true,  false,  true)
fc_or(g::Gate)    = fc_clear(g,  true,  false,  false,  true)
fc_nor(g::Gate)   = fc_clear(g,  true,  false,  true,  false)
fc_fanout(g::Gate)= fc_clear(g,  false,  false,  false,  false)
fc_null(g::Gate) = return nothing

#=
Another dispatching dictionary.
=#
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


################################################################################
##                            Top Level Netlist                               ##
################################################################################
type Netlist
   # Name of the circuit
   name              ::String

   #############################

   # Vector of gates.
   gates             ::Vector{Gate{Node}}
   # LUT for gates. Given gate name, returns index in "gates"
   gate_names        ::Dict{String, Int64}

   # Vector of nodes.
   nodes             ::Vector{Node}
   # LUT for nodes. Given node name, returns index in "nodes"
   node_names        ::Dict{String, Int64}

   #############################

   # Vector of faults being tested in the circuit
   faults            ::Vector{Fault}
   # fault_detected[i] = true if faults[i] has been detected.
   fault_detected    ::Vector{Bool}

   #############################

   # Used for processing
   process_order     ::Vector{Int64}
   fifo              ::CircularDeque{Int64}
   is_queued         ::Vector{Bool}

   # Simulation state variables
   use_queuing       ::Bool
   fault_collapsing  ::Bool
   fault_simulation  ::Bool
end

# Constructor
function Netlist(
      file::String;
      fault_collapsing::Bool = true
      )

   # Parse Verilog
   netlist = readnetlist(file)
   netlist_name = netlist.name

   # Create Dummy Array for initialization
   gates = [Gate{Node}(i) for i in keys(netlist.gates)]
   gate_names = Dict(b.name=>a for (a,b) in enumerate(gates))

   # Initialize arrays for the processing order and queue LUT
   process_order  = zeros(Int64, length(gates))
   is_queued      = zeros(Bool, length(gates))

   # Initialize Space
   nodes = [Node() for i = 1:length(netlist.nodes)]
   node_names = Dict{String, Int64}()

   # Build Nodes
   for (i, name) in enumerate(netlist.nodes)
      # Get Sources and sinks. Build adjacency lists
      sources  = SubSlice(gates, [gate_names[i] for i in netlist.node_sources[name]])
      sinks    = SubSlice(gates, [gate_names[i] for i in netlist.node_sinks[name]])

      # Assign to node array and update tracking dictionary
      nodes[i] = Node(name, sources, sinks)
      node_names[name] = i
   end

   # Build Gates
   for i = 1:length(gates)
      name = gates[i].name

      # Input gate will not have inputs. Must control for this condition.
      if haskey(netlist.gate_inputs, name)
         inputs = SubSlice(nodes, [node_names[i] for i in netlist.gate_inputs[name]])
      else
         inputs = SubSlice(nodes, Int64[])
      end

      # Output gate will have no outputs. Must control for this condition.
      if haskey(netlist.gate_outputs, name)
         outputs = SubSlice(nodes, [node_names[i] for i in netlist.gate_outputs[name]])
      else
         outputs = SubSlice(nodes, Int64[])
      end

      # Get type of gate, evaluation function, and fault propagation function
      typestring = netlist.gates[name]
      eval = equation_dispatch[netlist.gates[name]]
      prop = fault_prop_dispatch[netlist.gates[name]]

      # Build Gate
      gates[i] = Gate{Node}(name, typestring, i, inputs, outputs, eval, prop)
   end

   # Initialize misc fields
   fifo              = CircularDeque{Int64}(length(gates))
   faults            = Fault[]
   fault_detected    = Bool[]
   fault_collapsing  = fault_collapsing
   fault_simulation  = false
   use_queuing       = false

   # Build initial data struture
   n = Netlist(
      netlist_name,
      gates,
      gate_names,
      nodes,
      node_names,
      faults,
      fault_detected,

      process_order,
      fifo,
      is_queued,
      use_queuing,
      fault_collapsing,
      fault_simulation,
   )

   # Determine Processing Order
   order_gates!(n)

   # Clear all detected faults and clean up distributed fault trackers.
   reset_faults!(n)

   return n
end

"""
    list_faults(n::Netlist)

List all active faults in netlist `n`.
"""
function list_faults(n::Netlist)
   for f in n.faults
      println(f)
   end
   return nothing
end

"""
   getgate(n::Netlist, name::String)

Return `Gate` from `n` with name `name`.
"""
getgate(n::Netlist, name::String) = n.gates[n.gate_names[name]]

"""
   getnode(n::Netlist, name::String)

Return `Node` from `n` with name `name`.
"""
getnode(n::Netlist, name::String) = n.nodes[n.node_names[name]]

"""
   num_inputs(n::Netlist)

Return number of inputs for netlist `n`.
"""
num_inputs(n::Netlist) = length(n.gates[n.gate_names["input"]].outputs)

"""
   num_outputs(n::Netlist)

Return number of outputs for netlist `n`.
"""
num_outputs(n::Netlist) = length(n.gates[n.gate_names["output"]].inputs)

"""
    clean_faults(n::Netlist)

Find all faults in `n` that have been detected for input test vector. Mark those
faults as found in `faults_detected`. Drop all of those faults in `n` to
improve efficiency for subsequent runs.
"""
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

         if fault.stuck_at == true
            faulty_node.stuck_at_one = 0
         else
            faulty_node.stuck_at_zero = 0
         end
      end
   end
   return nothing
end

"""
    order_gates!(n::Netlist)

Given netlist `n`, modify the field `process_order` to be an ordering of indices
for the gates in `n` so that `process_order` may be traversed and the gate
corresponding to the current index in `process_order` may be analyzed with
the correct operation of the circuit maintained.
"""
function order_gates!(n::Netlist)

   index = 1
   initialized = Dict(i => false for i in keys(n.node_names))

   fifo = n.fifo

   # Assign and clear "is_queued" vector
   is_queued = n.is_queued
   is_queued .= false

   # Set inputs to zero
   input_gate_index  = n.gate_names["input"]
   input_gate        = n.gates[input_gate_index]

   push!(fifo, input_gate_index)

   # Last gate has no outputs, so this will terminate
   while !isempty(fifo)

      g = shift!(fifo)
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

      # Add indes "g" to the process order, increment index
      n.process_order[index] = g
      index += 1

      # Evaluate the gate, unless its the input gate
      if g != input_gate_index
         output_value = n.gates[g].eval(n.gates[g].inputs)
      else
         output_value = 0
      end

      # Iterate through output nodes to discover new gates.
      for node in n.gates[g].outputs
         node.value = output_value
         initialized[node.name] = true
         for gate in node.sink
            is_queued[gate.index] && continue
            push!(fifo, gate.index)
            is_queued[gate.index] = true
         end
      end
   end

   return nothing
end

"""
    reset_faults!(n::Netlist)

Set all faults in circuit to active. If `n.fault_collapsing = true`, perform
local fault collapsing.

Iterate through each node in the list and assign each active fault a unique
index.

Modify `n.faults` to be consistent.
"""
function reset_faults!(n::Netlist)

   # Mark all faults as active
   for node in n.nodes
      node.stuck_at_one    = 1
      node.stuck_at_zero   = 1
   end

   # Perform fault collapsing if set
   if n.fault_collapsing
      for i in n.process_order
         gate = n.gates[i]
         fc(gate)
      end
   end

   # Clear queue for safety
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

   # Reassign fault array in netlist
   n.faults = faults

   # Mark all faults as not detected.
   n.fault_detected = zeros(Bool, length(faults))

   return nothing
end

"""
    simulate(n::Netlist, values::Vector{Bool}; use_queuing = false, fault_simulation = false)

Simulate netlist `n` for input vector `values`. Input `values` must be the
same length as the number of inputs for `n`. It is assumed that `values` will
be input in the same order as the input nodes in `n`.

Netlist `n` contains fields that will change the way the netlist is simulated.
This can be overwritten using the keyword arguments.

`use_queueing` if `true` will use the queue-based ordering for gates. Otherwise
the fixed-order will be used.

`fault_simulation` if `true` will perform fault simulation. Otherwise the
simulator will run in pure logic mode
"""
function simulate(
   n                 ::Netlist,
   values            ::Vector{Bool};
   use_queuing       ::Bool = false,
   fault_simulation  ::Bool = false,
   )

   # Update field parameters
   n.fault_simulation   = fault_simulation
   n.use_queuing        = use_queuing

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

   # Initialize fault lists on input nodes
   if fault_simulation
      initialize_fault_lists(input_gate.outputs)
   end

   # Tracker for statistic purposes.
   gates_processed = 0

   # Select between queueing and fixed order processing
   if n.use_queuing
      while !isempty(n.fifo)
         gates_processed += 1
         gate_index = shift!(n.fifo)
         n.is_queued[gate_index] = false

         # Get Gate
         gate = n.gates[gate_index]
         processgate!(n, gate)
      end
   else
      for gate_index in n.process_order
         # Skip if there's nothing to update
         n.is_queued[gate_index] || continue
         gates_processed += 1

         # Get Gate
         gate = n.gates[gate_index]
         n.is_queued[gate_index] = false

         processgate!(n, gate)
      end
   end

   # Clean up netlist
   clean_faults!(n)

   return n, gates_processed
end

"""
    processgate!(n::Netlist, g::Gate)

Perform a logic simulation on gate `g`. If `n.fault_simulation = true`, also
perform fault propagation.
"""
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

"""
    setnode!(netlist::Netlist, n::Node, value::Bool)

Set node `n` to `value`. If `n.value = value`, nothing happens. Otherwise, all
sinks of `n` will be marked for processing.
"""
function setnode!(netlist::Netlist, n::Node, value::Bool)
   # If there's not change, exit early
   n.value == value && return nothing

   # Update logic value of n
   n.value = value

   # Mark all sink gates for processing
   if netlist.use_queuing
      for gate in n.sink
         if netlist.is_queued[gate.index] == false
            netlist.is_queued[gate.index] = true
            push!(netlist.fifo, gate.index)
         end
      end
   else
      for gate in n.sink
         netlist.is_queued[gate.index] = true
      end
   end
   return nothing
end

"""
    getoutputs(n::Netlist)

Return `Vector{Bool}` corresponding to the ordered output values of netlist `n`.
"""
getoutputs(n::Netlist) = [node.value for node in getgate(n, "output").inputs]


################################################################################
##                         Fault Propogation Operators                        ##
################################################################################

"""
    initialize_fault_lists(nodes)

Given a collection of `nodes`, set `node.fault_list` equal to the singleton
stuck at one or stuck at zero fault for that node depending on the logic
value of the node.
"""
function initialize_fault_lists(nodes)
   for n in nodes
      if n.value
         n.fault_list = [n.stuck_at_zero]
      else
         n.fault_list = [n.stuck_at_one]
      end
   end
   return nothing
end

"""
    fp_to_outputs(n::Netlist, g::Gate, fl::Vector{Int})

Fault Propagate fault list `fl` to the outputs of gate `g`.
"""
function fp_to_outputs(n::Netlist, g::Gate, fl::Vector{Int64})
   for node in g.outputs

      # Get index for the output fault to be added
      new_fault = node.value ? node.stuck_at_zero : node.stuck_at_one

      # If this fault is not being looked for, don't worry about it.
      if length(new_fault) == 0
         new_fault_list = fl
      else
         new_fault_list = sorted_union(fl, [new_fault])
      end

      # Only update if this is different.
      if new_fault_list != node.fault_list

         # Assign new fault list
         node.fault_list = new_fault_list

         # Mark all sink gates for processing
         for sink in node.sink
            if n.use_queuing
               if !n.is_queued[sink.index]
                  push!(n.fifo, sink.index)
                  n.is_queued[sink.index] = true
               end
            else
               n.is_queued[sink.index] = true
            end
         end
      end

   end
   return nothing
end

"""
   fp(net::Netlist, g::Gate, controlling_logic::Bool, critical_logic::Bool)

Perform fault propagation on gate `g`. Must set `controlling_logic` value for
the gate the the `critical_logic` value for the gate, which is similar to
the inversion value for the gate.
"""
function fp(net::Netlist, g::Gate,controlling_logic::Bool,critical_logic::Bool)
   union_list     = Int64[]

   #=
   If the controlling set is empty, then the output of the gate will be
   at the critical_logic value. Thus, fault list will be the union of the
   fault lists of the inptus
   =#
   if g.outputs[1].value == critical_logic
      for n in g.inputs
         union_list = sorted_union(union_list, n.fault_list)
      end
      fp_to_outputs(net, g, union_list)
      return nothing
   end

   #=
   Otherwise, we have to do some messing around with the inputs
   =#
   intersect_list = Int64[]
   intersect_initialized = false

   for n in g.inputs
      if n.value != controlling_logic
         union_list = sorted_union(union_list, n.fault_list)
      else
         if intersect_initialized
            intersect_list = sorted_intersect(intersect_list, n.fault_list)
         else
            intersect_list = n.fault_list
            intersect_initialized = true
         end
      end
   end

   fp_to_outputs(net, g, sorted_setdiff(intersect_list, union_list))

   return nothing
end

fp_and(n::Netlist, g::Gate)   = fp(n, g, false, true)
fp_nand(n::Netlist, g::Gate)  = fp(n, g, false, false)
fp_or(n::Netlist, g::Gate)    = fp(n, g, true,  false)
fp_nor(n::Netlist, g::Gate)   = fp(n, g, true,  true)

function fp_buf(net::Netlist, g::Gate)
   fl = Int64[]
   for n in g.inputs
      fl = sorted_union(fl, n.fault_list)
   end
   fp_to_outputs(net, g, fl)
   return nothing
end

fp_output(n::Netlist, g::Gate) = return nothing
fp_input(n::Netlist, g::Gate) = fp_to_outputs(n, g, Int64[])
fp_fanout(n::Netlist, g::Gate) = fp_to_outputs(n, g, g.inputs[1].fault_list)

function fp_xor(n::Netlist, g::Gate)
   fl1 = g.inputs[1].fault_list
   fl2 = g.inputs[2].fault_list
   fl = sorted_setdiff(sorted_union(fl1, fl2), sorted_intersect(fl1, fl2))
   fp_to_outputs(n, g, fl)
   return nothing
end

#=
Final dispatch structure.
=#
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
