```@meta
CurrentModule = Sims.Lib
```
```@contents
Pages = ["types.md"]
Depth = 5
```

# The Sims standard library

These components are available with **Sims.Lib**.

Normal usage is:

```julia
using Sims
using Sims.Lib

# modeling...
```

Library components include models for:

* Electrical circuits
* Power system circuits
* Heat transfer
* Rotational mechanics

Most of the components mimic those in the Modelica Standard Library.

The main types for Unknowns and signals defined in Sims.Lib include:

|                     | Flow/through variable | Node/across variable | Node helper type |
| ------------------- | --------------------- | -------------------- | ---------------- |
| Electrical systems  | `Current`             | `Voltage`            | `ElectricalNode` |
| Heat transfer       | `HeatFlow`            | `Temperature`        | `HeatPort`       |
| Mechanical rotation | `Torque`              | `Angle`              | `Flange`         |


Each of the node-type variables have a helper type for quantities that
can be Unknowns or objects.  For example, the type `ElectricalNode` is
a Union type that can be a `Voltage` or a number. `ElectricalNode` is
often used as the type for arguments to model functions to allow
passing a `Voltage` node or a real value (like 0.0 for ground).

The type `Signal` is also often used for a quantity that can be an
Unknown or a concrete value.

Most of the types and functions support Unknowns holding array values,
and some support complex values.

## Basic types

### NumberOrUnknown
```@docs
NumberOrUnknown
```
### Signal
```@docs
Signal
```
## Electrical types

### UVoltage
```@docs
UVoltage
```
### UCurrent
```@docs
UCurrent
```
### ElectricalNode
```@docs
ElectricalNode
```
### Voltage
```@docs
Voltage
```
### Current
```@docs
Current
```
## Thermal types

### UHeatPort
```@docs
UHeatPort
```
### UTemperature
```@docs
UTemperature
```
### UHeatFlow
```@docs
UHeatFlow
```
### HeatPort
```@docs
HeatPort
```
### HeatFlow
```@docs
HeatFlow
```
### Temperature
```@docs
Temperature
```
## Rotational types

### UAngle
```@docs
UAngle
```
### UTorque
```@docs
UTorque
```
### Angle
```@docs
Angle
```
### Torque
```@docs
Torque
```
### UAngularVelocity
```@docs
UAngularVelocity
```
### AngularVelocity
```@docs
AngularVelocity
```
### UAngularAcceleration
```@docs
UAngularAcceleration
```
### AngularAcceleration
```@docs
AngularAcceleration
```
### Flange
```@docs
Flange
```
