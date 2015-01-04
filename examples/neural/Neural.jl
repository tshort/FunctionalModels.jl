module Neural

using ....Sims
using ....Sims.Lib
using Docile

@doc """
# Neural models

Examples using neural models.

These are available in **Sims.Examples.Neural**.
""" -> type DocNeural <: DocTag end

include("hh.jl")

function runexamples()
    ## THESE SHOULD PROBABLY BE SHRUNK
    hh   = HodgkinHuxley()  # returns the hierarchical model
    hh_f = elaborate(hh)    # returns the flattened model
    hh_s = create_sim(hh_f) # returns a "Sim" ready for simulation
    
    # runs the simulation and returns
    # the result as an array plus column headings
    tf = 500.0
    dt = 0.025
    
    hh_ptr = setup_sunsim (hh_s, 1e-6, 1e-6)
    
    @time hh_yout = sunsim(hh_ptr, tf, int(tf/dt))
end 

end # module

