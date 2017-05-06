module VerilogParser

export NetlistStrings, readnetlist
immutable NetlistStrings
   name        ::String
   nodes       ::Set{String}
   gates       ::Dict{String, String}
   node_sources::Dict{String, Set{String}}
   node_sinks  ::Dict{String, Set{String}}
   gate_inputs ::Dict{String, Vector{String}}
   gate_outputs::Dict{String, Vector{String}}
end
const recognized_gates = Set([
   "input",
   "output",
   "not",
   "buf",
   "nand",
   "and",
   "or",
   "nor",
   "xor",
   "xnor"])

function update_dict!{K,T}(d::Dict{K, T}, k, v...)
   # Initialize if key does not exist in dictionary
   if haskey(d, k)
      push!(d[k], v[1])
   else
      d[k] = T([v[1]])
   end

   # No more need to test, just push
   for i = 2:length(v)
      push!(d[k], v[i])
   end

   return nothing
end

function process_multiline!(nets, I, state)
   while true
      (ln, state) = next(I, state)
      ln = strip(ln)
      length(ln) == 0 && continue

      new_nets = map(strip, split(ln[1:end-1], ","))

      append!(nets, new_nets)
      if ln[end] == ';'
         break
      end
   end
   return nothing
end

function readnetlist(file::String)
   f = open(file, "r")

   name = match(r"(?<=/)[^/]*(?=\.v)", file).match
   nodes  = Set{String}()
   gates = Dict{String, String}()

   node_sources = Dict{String, Set{String}}()
   node_sinks   = Dict{String, Set{String}}()

   gate_inputs  = Dict{String, Vector{String}}()
   gate_outputs = Dict{String, Vector{String}}()

   multiline = false

   # Do some iterator schenanigans
   I = eachline(f)
   state = start(I)
   while !done(I, state)
      (ln, state) = next(I, state)
      # Remove leading and trailing whitespace
      ln = strip(ln)

      # Skip line if just whitespace
      length(ln) == 0 && continue

      # Get first keyword
      keyword_match = match(r"^\w*\b", ln)
      typeof(keyword_match) == Void && continue

      keyword = keyword_match.match

      if in(keyword, recognized_gates)

         if keyword == "input"
            # Grab chunk of text after input and before last delimiter
            net_string = strip(ln[length("input")+1:end-1])
            nets = map(strip, split(net_string, ","))

            if ln[end] == ','
               state = process_multiline!(nets, I, state)
            end

            # Create input gate in gate strings
            gates["input"] = "input"
            update_dict!(gate_outputs, "input", nets...)

            # Set sources for all input nodes
            for n in nets
               update_dict!(node_sources, n,"input")
            end
         elseif keyword == "output"
            net_string = strip(ln[length("output")+1:end-1])
            nets = map(strip, split(net_string, ","))

            if ln[end] == ','
               process_multiline!(nets, I, state)
            end

            gates["output"] = "output"
            update_dict!(gate_inputs, "output", nets...)

            # Set sink for all output nodes
            for n in nets
               update_dict!(node_sinks, n, "output")
            end
         else
            instance_id = match(r"(?<=\s)\w*(?=(\s|\())", ln).match
            net_string = match(r"(?<=\().*(?=\))", ln).match

            nets = map(strip, split(net_string, ","))

            gates[instance_id] = keyword

            update_dict!(gate_outputs, instance_id, nets[1])
            update_dict!(gate_inputs, instance_id, nets[2:end]...)

            update_dict!(node_sources, nets[1], instance_id)
            for i = 2:length(nets)
               update_dict!(node_sinks, nets[i], instance_id)
            end
         end
         push!(nodes, nets...)
      end
   end
   close(f)

   return NetlistStrings(
      name,
      nodes,
      gates,
      node_sources,
      node_sinks,
      gate_inputs,
      gate_outputs,
   )


end


end
