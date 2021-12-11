using FunctionalModels, FunctionalModels.Lib
using ModelingToolkit, OrdinaryDiffEq

include("../examples/lib/rotational.jl")

fst   = sim(First(), 1.0)
