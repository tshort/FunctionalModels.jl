
module Sims

using Reexport
@reexport using Reactive

import Base.ifelse,
       Base.hcat,
       Base.length,
       Base.getindex, 
       Base.setindex!,
       Base.show,
       Base.size,
       Base.vcat

## Types
export ModelType, UnknownCategory, Unknown, UnknownVariable, DefaultUnknown, DerUnknown, RefUnknown,
       UnknownConstraint, Normal, Negative, Positive, NonNegative, NonPositive,
       NegativeUnknown, PositiveUnknown, NonNegativeUnknown, NonPositiveUnknown,
       RefBranch, InitialEquation, Model, MExpr, Event, LeftVar, StructuralEvent,
       EquationSet, SimFunctions, Sim, SimState, SimResult

export UnknownReactive, Discrete, Parameter

## Specials
export MTime, @init, @unknown, @liftd
## Methods
export Equation, @equations, is_unknown, der, delay, mexpr, compatible_values, reinit, ifelse, pre,
       basetypeof, from_real, to_real,
       gplot, wplot,
       check, sim_verbose, 
       elaborate, create_sim, create_simstate, sim, sunsim, dasslsim, solve,
       initialize!

## Model methods
export Branch, BoolEvent




using Docile
@document
using Compat
import Compat.view
        

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


