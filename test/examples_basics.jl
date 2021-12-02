using Sims, Sims.Lib
using ModelingToolkit, OrdinaryDiffEq
const t = Sims.t
const D = Sims.D

include("../examples/basics/dc_motor_w_shaft.jl")
dmws = sim(DcMotorWithShaft, 4.0)

## BROKEN
# include("../examples/basics/half_wave_rectifiers.jl")
# hwr  = sim(HalfWaveRectifier, 0.1)

include("../examples/basics/vanderpol.jl")
v    = sim(Vanderpol, 50.0)

## BROKEN
# include("../examples/basics/vanderpol_with_events.jl")
# vwe  = sim(VanderpolWithEvents, 10.0)

include("../examples/basics/vanderpol_with_parameter.jl")
vwp  = sim(VanderpolWithParameter(1.2), 10.0)

