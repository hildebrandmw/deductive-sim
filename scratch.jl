@time n = Netlist("circuits/and.v")
@time simulate(n, [true, true])
@time output_values(n)

using DataStructues
@time x = readnetlist("circuits/paper_test.v")
length(x.nodes)

wrong_circuits = [1908, 2670, 3540, 7552]

@time n = Netlist("circuits/c2670.v");
length(n.faults)
list_faults(n)

reset_faults!(n)
@time simulate(n, [false, false, true], fault_simulation = false)
println(getoutputs(n))

for (i,b) in enumerate(n.fault_detected)
   if b
      println(n.faults[i])
   end
end
list_faults(n)

getnode(n, "c")




@time for i = 1:1000
   u = unique(sort(rand(1:10, 1000)))
   v = unique(sort(rand(1:1000, 1)))

   a = sort(union(u,v))
   sorted_union!(u,v)
   if a != u
      #println(a)
      #println(u)
      println("Bad")
      break
   end
end

u = unique(sort(rand(1:1000, 1000)))
v = unique(sort(rand(1:1000, 1000)))


@time union(u,v)
@time sorted_union!(u,v)



n.faults[1]
pwd()
generate_tests(300, pure = false)
clean_netlist_verification()
@time x = verify_netlist(
      "test-suite",
      fault_simulation  = false,
      fault_collapsing  = true,
      use_queuing       = false,
      check_results     = true,
   )
println(x)
@time test_faults()










# placeholder
