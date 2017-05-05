using NetlistTester

function benchmark()
    # Any setup code goes here.

    # Run once, to force compilation.
    println("======================= First run:")
    srand(666)
    @profile @time verify_netlist()

    # Run a second time, with profiling.
    println("\n\n======================= Second run:")
    srand(666)
    Profile.init(delay=0.01)
    Profile.clear()
    Profile.clear_malloc_data()
    @profile @time verify_netlist()

    # Write profile results to profile.bin.
    f = open("profile.bin", "w")
    Profile.print(f)
    close(f)
end
