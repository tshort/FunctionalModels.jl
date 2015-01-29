using Sims
using Base.Test

println("== run all examples")
Sims.Examples.Basics.runall()
Sims.Examples.Lib.runall()
Sims.Examples.Neural.runall()
Sims.Examples.Tiller.runall()


println("== run other tests")
include("simulations.jl")
