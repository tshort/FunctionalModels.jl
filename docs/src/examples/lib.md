```@meta
CurrentModule = Sims.Examples.Lib
```
```@contents
Pages = ["lib.md"]
Depth = 5
```

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

# Blocks

### PID_Controller
```@docs
PID_Controller
```
# Electrical

### CauerLowPassAnalog
```@docs
CauerLowPassAnalog
```
### CauerLowPassOPV
```@docs
CauerLowPassOPV
```
### CauerLowPassOPV2
```@docs
CauerLowPassOPV2
```
### CharacteristicIdealDiodes
```@docs
CharacteristicIdealDiodes
```
### ChuaCircuit
```@docs
ChuaCircuit
```
### HeatingResistor
```@docs
HeatingResistor
```
### HeatingRectifier
```@docs
HeatingRectifier
```
### Rectifier
```@docs
Rectifier
```
### ShowSaturatingInductor
```@docs
ShowSaturatingInductor
```
### ShowVariableResistor
```@docs
ShowVariableResistor
```
### ControlledSwitchWithArc
```@docs
ControlledSwitchWithArc
```
### CharacteristicThyristors
```@docs
CharacteristicThyristors
```
# Heat transfer

### TwoMasses
```@docs
TwoMasses
```
### Motor
```@docs
Motor
```
# Power systems

### RLModel
```@docs
RLModel
```
### PiModel
```@docs
PiModel
```
### ModalModel
```@docs
ModalModel
```
# Rotational

### First
```@docs
First
```
