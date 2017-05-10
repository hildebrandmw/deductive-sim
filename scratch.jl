@time n = Netlist("circuits/and.v")
@time simulate(n, [true, true])
@time output_values(n)

using DataStructues
@time x = readnetlist("circuits/paper_test.v")
length(x.nodes)


@time n = Netlist("circuits/test_and.v");
list_faults(n)
@time simulate(n, [true, false])
getnode(n, "N3")


pwd()
generate_tests(5000)
clean_netlist_verification()
@time verify_netlist()
