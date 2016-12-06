```@meta
CurrentModule = Sims.Examples.Basics
```
```@contents
Pages = ["basics.md"]
Depth = 5
```

# Examples using basic models

These are available in **Sims.Examples.Basics**.

Here is an example of use:

```julia
using Sims
m = Sims.Examples.Basics.Vanderpol()
v = sim(m, 50.0)


plot(v)
```

### BreakingPendulum
```@docs
BreakingPendulum
```
### BreakingPendulumInBox
```@docs
BreakingPendulumInBox
```
### DcMotorWithShaft
```@docs
DcMotorWithShaft
```
### HalfWaveRectifier
```@docs
HalfWaveRectifier
```
### StructuralHalfWaveRectifier
```@docs
StructuralHalfWaveRectifier
```
### InitialCondition
```@docs
InitialCondition
```
### MkinInitialCondition
```@docs
MkinInitialCondition
```
### Vanderpol
```@docs
Vanderpol
```
### VanderpolWithEvents
```@docs
VanderpolWithEvents
```
### VanderpolWithParameter
```@docs
VanderpolWithParameter
```
