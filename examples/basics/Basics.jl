module Basics

using ....Sims
using ....Sims.Lib
using Docile


@doc """
# Examples using basic models

These are available in **Sims.Examples.Basics**.

Here is an example of use:

```julia
using Sims
m = Sims.Examples.Basics.ChuaCircuit()
v    = sim(Vanderpol(), 50.0)

using Winston
wplot(z)
```
""" -> type DocExBasics <: DocTag end


include("breaking_pendulum.jl")
include("breaking_pendulum_in_box.jl")
include("dc_motor_w_shaft.jl")
include("half_wave_rectifiers.jl")
include("initial_conditions.jl")
include("vanderpol.jl")
include("vanderpol_with_events.jl")

function runexamples()
    bp   = sim(BreakingPendulum(), 6.0)
    bpb  = sim(BreakingPendulumInBox(), 5.0)
    dmws = sim(DcMotorWithShaft(), 4.0)
    hwr  = sim(HalfWaveRectifier(), 0.1)
    shwr = sim(StructuralHalfWaveRectifier(), 0.1)
    v    = sim(Vanderpol(), 50.0)
    vwe  = sim(VanderpolWithEvents(), 10.0)
    ic   = solve(InitialCondition())
    mic  = solve(MkinInitialCondition())
end 

end # module

