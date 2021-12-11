using Sims, Sims.Lib
using ModelingToolkit, OrdinaryDiffEq

include("../examples/lib/heat_transfer.jl")

## m  = sim(Motor(), 7200.0)
tm    = sim(TwoMasses(), 1.0)
