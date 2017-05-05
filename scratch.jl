@time n = Netlist("circuits/and.v")
@time simulate(n, [true, true])
@time output_values(n)

@time x = readnetlist("test/netlist-verification/circuits/c17.v")
@time n = Netlist("test/netlist-verification/circuits/c17.v")

@time simulate(n, [true, true, true, true, true])
println(output_values(n))

@time generate_tests(10000)

clean_netlist_verification()

@time verify_netlist()
