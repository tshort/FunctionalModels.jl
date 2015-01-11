
module Sims

import Base.ifelse,
       Base.hcat,
       Base.length,
       Base.getindex, 
       Base.setindex!,
       Base.show,
       Base.size,
       Base.vcat

## Types
export ModelType, UnknownCategory, Unknown, UnknownVariable, DefaultUnknown, DerUnknown, RefUnknown, Parameter,
       RefBranch, InitialEquation, ParameterEquation, Model, MExpr, Discrete, RefDiscrete, DiscreteVar, Event, LeftVar, StructuralEvent,
       EquationSet, SimFunctions, Sim, SimResult

## Specials
export MTime, @init, @unknown

## Methods
export Equation, @equations, is_unknown, der, delay, mexpr, value, compatible_values, reinit, ifelse, add_hook!,
       basetypeof, from_real, to_real,
       gplot, wplot,
       check, sim_verbose, 
       elaborate, create_sim, create_simstate, sim, sunsim, setup_sunsim, dasslsim, solve

## Model methods
export Branch, BoolEvent




## The v"0.4" stuff is commented out because of a bug in Base.@doc

## if VERSION < v"0.4.0-dev"
using Docile
## else
##     macro docstrings()
##         :(nothing)
##     end
## end
abstract DocTag
export DocTag
## macro doctag(ex)
##     :( @doc $ex -> type $(gensym()) <: DocTag end )
## end
## export @doctag, DocTag
        

include("main.jl")
include("elaboration.jl")
include("simcreation.jl")
include("utils.jl")
# solvers
include("dassl.jl")
include("sundials.jl")
include("sim.jl")


# load standard Sims libraries

include("../lib/Lib.jl")

# load standard Sims examples

include("../examples/Examples.jl")

end # module Sims


