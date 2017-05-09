@time n = Netlist("circuits/and.v")
@time simulate(n, [true, true])
@time output_values(n)

using DataStructues
@time x = readnetlist("circuits/paper_test.v")
length(x.nodes)
@time n = Netlist("circuits/paper_test.v");
list_faults(n)
n.faults

length(n.faults)
pq = CircularDeque{Int64}(2 * length(n.gates))
@time simulate(n, [true, true, true, true, true], pq)
println(getoutputs(n))

generate_tests(1000)
clean_netlist_verification()
@time verify_netlist()
