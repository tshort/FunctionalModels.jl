
module Tiller

using ....Sims
using ....Sims.Lib
using ModelingToolkit


"""
# Tiller examples

**From [Modelica by Example](http://mbe.modelica.university/)**

These examples are from the online book [Modelica by
Example](http://mbe.modelica.university/) by Michael M. Tiller. Michael
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
@comment 


include("speed-measurement.jl")
include("architecture.jl")


end # module
