module Basics

using ....Sims
using ....Sims.Lib


"""
# Examples using basic models

These are available in **Sims.Examples.Basics**.

Here is an example of use:

```julia
using Sims
m = Sims.Examples.Basics.Vanderpol()
v = sim(m, 50.0)


plot(v)
```
"""
@comment 

# include("breaking_pendulum.jl")
# include("breaking_pendulum_in_box.jl")
include("dc_motor_w_shaft.jl")
# include("half_wave_rectifiers.jl")
# include("initial_conditions.jl")
include("vanderpol.jl")
# include("vanderpol_with_events.jl")
# include("vanderpol_with_parameter.jl")
# include("concentration.jl")
# include("concentration_with_constraints.jl")
# include("dde.jl")

# function runall()
#     bp   = sim(BreakingPendulum(), 6.0)
#     bpb  = sim(BreakingPendulumInBox(), 5.0)
#     dmws = sim(DcMotorWithShaft(), 4.0)
#     hwr  = sim(HalfWaveRectifier(), 0.1)
#     shwr = sim(StructuralHalfWaveRectifier(), tstop = 0.1, alg = false)
#     v    = sim(Vanderpol(), 50.0)
#     vwe  = sim(VanderpolWithEvents(), 10.0)
    
#     mu = Parameter(1.0)
#     ss = create_simstate(VanderpolWithParameter(mu))
#     vwp1 = sim(ss, 10.0)
#     reinit(mu, 1.5)
#     vwp2 = sim(ss, 10.0)
#     reinit(mu, 1.0)
#     vwp3 = sim(ss, 10.0) # should be the same as vwp1
    
#     # conc   = sim(Concentration(), 10.0)
#     # sconc  = sim(SimpleConcentration(), 10.0)
#     # concc  = sim(ConcentrationWithConstraints(), 10.0)
#     # sconcc = sim(SimpleConcentrationWithConstraints(), 10.0)
#     # dde    = sim(DDE(tau=15.0), tstop=250.0, alg=true)
    
#     ic   = solve(InitialCondition())
#     # mic  = solve(MkinInitialCondition())
# end 

end # module

