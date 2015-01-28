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

function runall()
    hh   = HodgkinHuxley()  # returns the hierarchical model
    tf = 500.0
    dt = 0.025
    y = sunsim(hh, tstop = tf, Nsteps = int(tf/dt), reltol = 1e-6, abstol = 1e-6)
    
end 

end # module

