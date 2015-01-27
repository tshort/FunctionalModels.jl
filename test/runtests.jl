using Sims
using Base.Test

println("== run all examples")
Sims.Examples.Basics.runexamples()
Sims.Examples.Lib.runexamples()
Sims.Examples.Neural.runexamples()


println("== run other tests")
include("simulations.jl")
