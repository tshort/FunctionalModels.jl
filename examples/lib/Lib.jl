module Lib

using ....Sims
using ....Sims.Lib


@comment """
# Sims.Lib

Examples using models from the Sims standard library (Sims.Lib).

Many of these are patterned after the examples in the Modelica
Standard Library.

These are available in **Sims.Examples.Lib**. Here is an example of use:

```julia
using Sims
m = Sims.Examples.Lib.ChuaCircuit()
z = sim(m, 5000.0)


plot(z)
```
"""

include("blocks.jl")
include("electrical.jl")
include("heat_transfer.jl")
include("powersystems.jl")
include("rotational.jl")


function runall()
    ## Electrical
    run_electrical_examples()
    
    ## Heat transfer
    ## m  = sim(Motor(), 7200.0)
    tm    = sim(TwoMasses(), 1.0)
    
    ## Power systems
    rlm   = sim(RLModel(), 0.2)
    ## pim   = sim(PiModel(), 0.02)
    ## mm    = sim(ModalModel(), 0.2)
    
    ## Rotational
    fst   = sim(First())
    
    ## Blocks
    pidc  = sim(PID_Controller(), tstop = 4.0, alg = false)
end

end # module

