using Sims, Sims.Lib
using ModelingToolkit, OrdinaryDiffEq

include("../examples/tiller/speed-measurement.jl")

tstop = 5.0
so   = sim(SecondOrderSystem, tstop)
sosl = sim(SecondOrderSystemUsingSimsLib, tstop, Tsit5())
# sh   = sim(SampleAndHold, tstop, Tsit5())
# im   = sim(IntervalMeasure, tstop)
# pc   = sim(PulseCounting, tstop)

include("../examples/tiller/architecture.jl")

fs   = sim(FlatSystem, tstop, Tsit5())
bs   = sim(BaseSystem, tstop, Tsit5())
v1   = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01)),  tstop, Tsit5())
v1a  = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.036)),  tstop, Tsit5())
# v2   = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
#                       Controller = PIDController(yMax=15, Td=0.1, k=20, Ti=0.1),
#                       Actuator = LimitedActuator(delayTime=0.005, uMax=10)), tstop, Tsit5())
# v2a  = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
#                       Controller = PIDController(yMax=50, Td=0.01, k=4, Ti=0.07),
#                       Actuator = LimitedActuator(delayTime=0.005, uMax=10)), tstop, Tsit5())

#= 
@variables in1ₓangvelocity(t) in1ₓangvelocity(t)
plot(fs, vars = [in1ₓangvelocity, in1ₓangvelocity])
=#
