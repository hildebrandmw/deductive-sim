#=
The goal of this module is to verify that the circuit being simulated in the
julia implementation is correct.

It will generate a list of random input test vectors for each circuit.

A suite of verilog testbenches will be executed and the resulting output will
be stored in another folder.

This module will then be responsible for simulating the Julia implementation
over the input vectors and ensuring that the outputs match the Modelsim results
=#
module Tester

using Simulator
using DataStructures

export verify_netlist

function generate_tests(max_vectors::Int64; pure = false)
   # Creage makefile for automating testing
   makefile = open("test/test-suite/Makefile", "w")

   nc_command = "ncverilog +sv +access+rw +nctimescale+1ns/1ns"
   println(makefile, "run:")

   for (root,~,files) in walkdir("circuits"), file in files
      if file[end-1:end] == ".v"
         source_file = joinpath(root, file)
         dest_file = joinpath("test/test-suite/circuits", file)

         # Copy circuit into testing sub-directory
         cp(source_file, dest_file, remove_destination = true)

         # Create neslist
         n = Netlist(source_file)

         # Generate Input Vectors
         num_vectors = generate_random_inputs(n, max_vectors, pure)

         # Generate Testbench
         generate_testbench(n, num_vectors)

         # Make entry in makefile
         circuit_name   = " circuits/"* n.name * ".v"
         testbench_name = " testbenches/" * n.name * "_tb.v"
         nc = nc_command * testbench_name * circuit_name
         println(makefile, "\t", nc)
         println(makefile, "\trm -rf INCA_libs")
      end
   end

   close(makefile)
   return nothing
end


function generate_random_inputs(n::Netlist, max_vectors::Int64, pure::Bool)
   circuit = n.name
   f = open("test/test-suite/input_vectors/" * circuit * ".txt", "w")
   num_inputs = length(getgate(n, "input").outputs)
   if num_inputs < log2(max_vectors)
      num_vectors = 2 ^ num_inputs
      for i = 0:2^num_inputs-1
         println(f, bin(i, num_inputs))
      end
   else
      num_vectors = max_vectors
      seed = rand(Bool, num_inputs)
      for i = 1:max_vectors
         println(f, join([j ? "0": "1" for j = seed]))
         if pure
            seed = rand(Bool, num_inputs)
         else
            k = rand(1:length(seed))
            seed[k] = ~seed[k]
         end
      end
   end
   close(f)
   return num_vectors
end

function generate_testbench(n::Netlist, num_vectors::Int64)
   circuit = n.name
   testbench_name = circuit * "_tb"

   inputs      = getgate(n, "input").outputs
   outputs     = getgate(n, "output").inputs
   num_inputs  = length(inputs)
   num_outputs = length(outputs)

   f = open("test/test-suite/testbenches/" * testbench_name * ".v", "w")

   println(f, "module " * testbench_name * "();")
   println(f, "parameter INPUT_WIDTH = ", num_inputs, ";")
   println(f, "parameter OUTPUT_WIDTH = ", num_outputs, ";")
   println(f, "parameter NUMBER_OF_TESTS = ", num_vectors, ";")
   println(f, "string INPUT_FILE = \"input_vectors/", circuit, ".txt\";")
   println(f, "string OUTPUT_FILE = \"output_vectors/", circuit, ".txt\";")
   println(f, "")
   println(f, "reg   [INPUT_WIDTH-1:0] in;")
   println(f, "wire  [OUTPUT_WIDTH-1:0] out;")
   println(f, "")
   println(f, "reg [INPUT_WIDTH-1:0] memory [NUMBER_OF_TESTS-1:0];")
   println(f, "integer i,f;")
   println(f, "")

   # Module Instantiation
   print(f, circuit, " UUT (")
   for i = 0:num_inputs-1
      print(f, ".", inputs[i+1].name, "(in[", i, "]), ")
      if mod(i, 4) == 3
         print(f, "\n")
      end
   end

   for i = 0:num_outputs-1
      print(f, ".", outputs[i+1].name, "(out[",  i, "])")
      i == num_outputs-1 ? print(f, ");\n") : print(f, ", ")
      if mod(i, 4) == 3
         print(f, "\n")
      end
   end

   print(f,
   "initial begin
   \$readmemb(INPUT_FILE, memory);

   f = \$fopen(OUTPUT_FILE);

   for (i = 0; i < NUMBER_OF_TESTS; i = i+1) begin
      in = memory[i];
      #1;
      \$fdisplay(f, \"%b\", out);
   end
   \$fclose(f);
   \$finish;
end

endmodule")

   close(f)
end

function clean_netlist_verification()
   println("Removing the following files:")
   for (root, ~, files) in walkdir("test/test-suite"), file in files
      println(joinpath(root, file))
      rm(joinpath(root, file))
   end

   INCA_dir = "test/test-suite/INCA_libs"
   if isdir(INCA_dir)
      rm(INCA_dir, recursive = true)
   end
end

tf(c::Char) = (c == '1') ? true : false

function verify_netlist(
   directory::String;
   fault_simulation  = true,
   fault_collapsing  = true,
   use_queuing       = false,
   check_results     = true,
   )

   number_of_faults_found = Float64[]
   for (root, ~, files) in walkdir(joinpath("test",directory, "circuits")), file in files
      #file == "mux.v" || continue
      source_file = joinpath(root, file)
      n = Netlist(source_file, fault_collapsing = fault_collapsing)

      infile = open(joinpath("test",directory, "input_vectors", n.name * ".txt"), "r")
      outfile = open(joinpath("test",directory, "output_vectors", n.name * ".txt"), "r")


      input_vectors = Vector{Vector{Bool}}()
      output_vectors = Vector{Vector{Bool}}()
      initialized = false
      for (istring, ostring) in zip(eachline(infile), eachline(outfile))
         if !initialized
            num_inputs = length(istring)
            num_outputs = length(ostring)
            initialized = true
         end
         push!(input_vectors, [tf(c) for c in strip(istring)[end:-1:1]])
         push!(output_vectors, [tf(c) for c in strip(ostring)[end:-1:1]])
      end

      println("")
      println("Testing: ", n.name)
      println("Number of Faults: ", length(n.faults))
      println("Number of Vectors: ", length(input_vectors))
      passed = true
      # Create Test Vectors
      gates_processed = 0
      ~, t, ~  = @timed for i = 1:length(input_vectors)
         input =  input_vectors[i]
         output = output_vectors[i]

         ~, gp = simulate(n, input,
            fault_simulation  = fault_simulation,
            use_queuing      = use_queuing,
         )

         gates_processed += gp

         if check_results
            generated_output = getoutputs(n)


            if output != generated_output
               println("Circuit failed for: ", input)
               passed = false
               break
            end
         end
      end
      println("Fault Coverage: ", sum(n.fault_detected) / length(n.faults))
      println("Gates Processed per second: ", gates_processed/t)
      push!(number_of_faults_found, sum(n.fault_detected) / length(n.faults))

      passed && check_results && println("Circuit passed simulation test.")

      close(infile)
      close(outfile)

   end
   return number_of_faults_found
end




end#module
