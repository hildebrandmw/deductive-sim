@time n = Netlist("circuits/and.v")
@time simulate(n, [true, true])
@time output_values(n)

using DataStructues
@time x = readnetlist("circuits/c17.v")

@time n = Netlist("circuits/c17.v")
pq = CircularDeque{Int64}(2 * length(n.gates))
@time simulate(n, [true, true, true, true, true], pq)
println(getoutputs(n))

generate_tests(500)
clean_netlist_verification()
@time verify_netlist()
