
module Tiller

using ....FunctionalModels
using ....FunctionalModels.Lib
using ModelingToolkit


"""
# Tiller examples

**From [Modelica by Example](http://mbe.modelica.university/)**

These examples are from the online book [Modelica by
Example](http://mbe.modelica.university/) by Michael M. Tiller. Michael
explains modeling and simulations very well, and it's easy to compare
FunctionalModels.jl results to those online.

These are available in **FunctionalModels.Examples.Tiller**. Here is an example of
use:

```julia
using FunctionalModels
m = FunctionalModels.Examples.Tiller.SecondOrderSystem()
y = dasslsim(m, tstop = 5.0)


plot(y)
```
"""
@comment 


include("speed-measurement.jl")
include("architecture.jl")


end # module
