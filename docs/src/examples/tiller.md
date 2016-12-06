```@meta
CurrentModule = Sims.Examples.Tiller
```
```@contents
Pages = ["tiller.md"]
Depth = 5
```

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

# Architectures

These examples from the following sections from the [Architectures
chapter](http://book.xogeny.com/components/architectures/):

* [Sensor Comparison](http://book.xogeny.com/components/architectures/sensor_comparison/)
* [Architecture Driven Approach](http://book.xogeny.com/components/architectures/sensor_comparison_ad/)

In [Modelica by Example](http://book.xogeny.com/), Tiller shows how
components can be connected together in a reusable fashion. This is
also possible in Sims.jl. Because Sims.jl is functional, the approach
is different than Modelica's object-oriented approach. The functional
approach is generally cleaner.

### FlatSystem
```@docs
FlatSystem
```
### BasicPlant
```@docs
BasicPlant
```
### IdealSensor
```@docs
IdealSensor
```
### SampleHoldSensor
```@docs
SampleHoldSensor
```
### IdealActuator
```@docs
IdealActuator
```
### LimitedActuator
```@docs
LimitedActuator
```
### ProportionalController
```@docs
ProportionalController
```
### PIDController
```@docs
PIDController
```
### BaseSystem
```@docs
BaseSystem
```
### Variant1
```@docs
Variant1
```
### Variant2
```@docs
Variant2
```
### Variant2a
```@docs
Variant2a
```
# Examples of speed measurement

These examples show several ways of measuring speed on a rotational
system. They are based on Michael's section on [Speed
Measurement](http://book.xogeny.com/behavior/discrete/measuring/). These
examples include use of Discrete variables and Events.

The system is based on the following plant:

![diagram](http://book.xogeny.com/_images/PlantWithPulseCounter.svg)


### SecondOrderSystem
```@docs
SecondOrderSystem
```
### SecondOrderSystemUsingSimsLib
```@docs
SecondOrderSystemUsingSimsLib
```
### SampleAndHold
```@docs
SampleAndHold
```
### IntervalMeasure
```@docs
IntervalMeasure
```
### PulseCounting
```@docs
PulseCounting
```
