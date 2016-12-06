
module Tiller

using ....Sims
using ....Sims.Lib


@comment """
# Tiller examples

**From [Modelica by Example](http://book.xogeny.com/)**

These examples are from the online book [Modelica by
Example](http://book.xogeny.com/) by Michael M. Tiller. Michael
explains modeling and simulations very well, and it's easy to compare
Sims.jl results to those online.

These are available in **Sims.Examples.Tiller**. Here is an example of
use:

```julia
using Sims
m = Sims.Examples.Tiller.SecondOrderSystem()
y = dasslsim(m, tstop = 5.0)


plot(y)
```
"""

include("speed-measurement.jl")
include("architecture.jl")


function runall()
    tstop = 5.0
    so   = sim(SecondOrderSystem(), tstop)
    sosl = sim(SecondOrderSystemUsingSimsLib(), tstop)
    sh   = sim(SampleAndHold(), tstop)
    im   = sim(IntervalMeasure(), tstop)
    pc   = sim(PulseCounting(), tstop)

    fs   = sim(FlatSystem(), tstop = tstop, alg = false)
    bs   = sim(BaseSystem(), tstop = tstop, alg = false)
    v1   = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01)), tstop = tstop, alg = false)
    v1a  = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.036)), tstop = tstop, alg = false)
    v2   = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                          Controller = PIDController(yMax=15, Td=0.1, k=20, Ti=0.1),
                          Actuator = LimitedActuator(delayTime=0.005, uMax=10)), tstop = tstop, alg = false)
    v2a  = sim(BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                          Controller = PIDController(yMax=50, Td=0.01, k=4, Ti=0.07),
                          Actuator = LimitedActuator(delayTime=0.005, uMax=10)), tstop = tstop, alg = false)
end

end # module
