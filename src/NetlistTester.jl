#=
The goal of this module is to verify that the circuit being simulated in the
julia implementation is correct.

It will generate a list of random input test vectors for each circuit.

A suite of verilog testbenches will be executed and the resulting output will
be stored in another folder.

This module will then be responsible for simulating the Julia implementation
over the input vectors and ensuring that the outputs match the Modelsim results
=#
module NetlistTester

using Simulator
using DataStructures

export verify_netlist

function generate_tests(max_vectors::Int64)
   # Creage makefile for automating testing
   makefile = open("test/netlist-verification/Makefile", "w")

   nc_command = "ncverilog +sv +access+rw +nctimescale+1ns/1ns"
   println(makefile, "run:")

   for (root,~,files) in walkdir("circuits"), file in files
      if file[end-1:end] == ".v"
         source_file = joinpath(root, file)
         dest_file = joinpath("test/netlist-verification/circuits", file)
         # Copy circuit into testing sub-directory
         cp(source_file, dest_file, remove_destination = true)

         # Create neslist
         n = Netlist(source_file)

         # Generate Input Vectors
         num_vectors = generate_random_inputs(n, max_vectors)

         # Generate Testbench
         generate_testbench(n, num_vectors)

         # Make entry in makefile
         circuit_name = " circuits/"* n.name * ".v"
         testbench_name = " testbenches/" * n.name * "_tb.v"
         nc = nc_command * testbench_name * circuit_name
         println(makefile, "\t", nc)
         println(makdefule, "\trm -rf INCA_libs")
      end
   end

   close(makefile)
   return nothing
end


function generate_random_inputs(n::Netlist, max_vectors::Int64)
   circuit = n.name
   f = open("test/netlist-verification/input_vectors/" * circuit * ".txt", "w")
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
         k = rand(1:length(seed))
         seed[k] = ~seed[k]
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

   f = open("test/netlist-verification/testbenches/" * testbench_name * ".v", "w")

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
   for (root, ~, files) in walkdir("test/netlist-verification"), file in files
      println(joinpath(root, file))
      rm(joinpath(root, file))
   end

   INCA_dir = "test/netlist-verification/INCA_libs"
   if isdir(INCA_dir)
      rm(INCA_dir, recursive = true)
   end
end

tf(c::Char) = (c == '1') ? true : false

function verify_netlist()
   for (root, ~, files) in walkdir("test/netlist-verification/circuits"), file in files
      source_file = joinpath(root, file)
      n = Netlist(source_file)

      infile = open("test/netlist-verification/input_vectors/" * n.name * ".txt", "r")
      outfile = open("test/netlist-verification/output_vectors/" * n.name * ".txt", "r")
      println("")
      println("Testing: ", n.name)
      passed = true

      for (istring, ostring) in zip(eachline(infile), eachline(outfile))
         input =  [tf(c) for c in strip(istring)[end:-1:1]]
         output = [tf(c) for c in strip(ostring)[end:-1:1]]

         simulate(n, input)
         generated_output = getoutputs(n)

         if output != generated_output
            println("Circuit failed for: ", input)
            passed = false
            break
         end
      end

      passed && println("Circuit passed simulation test.")

      close(infile)
      close(outfile)
   end
end


end#module
