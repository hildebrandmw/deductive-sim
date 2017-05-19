@time n = Netlist("circuits/and.v")
@time simulate(n, [true, true])
@time output_values(n)

using DataStructues
@time x = readnetlist("circuits/paper_test.v")
length(x.nodes)

wrong_circuits = [1908, 2670, 3540, 7552]

@time n = Netlist("circuits/mux.v");
length(n.faults)

reset_faults!(n)
@time simulate(n, [true, true, false], fault_simulation = true)

for (i,b) in enumerate(n.fault_detected)
   if b
      println(n.faults[i])
   end
end
list_faults(n)

getnode(n, "c")















n.faults[1]
pwd()
#generate_tests(300)
#clean_netlist_verification()
@time verify_netlist()
@time test_faults()



# placeholder
