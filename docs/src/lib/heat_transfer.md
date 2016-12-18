```@meta
CurrentModule = Sims.Lib
```
```@contents
Pages = ["heat_transfer.md"]
Depth = 5
```

# Heat transfer models

Library of 1-dimensional heat transfer with lumped elements

These components are modeled after the Modelica.Thermal.HeatTransfer
library.

This package contains components to model 1-dimensional heat transfer
with lumped elements. This allows especially to model heat transfer in
machines provided the parameters of the lumped elements, such as the
heat capacity of a part, can be determined by measurements (due to the
complex geometries and many materials used in machines, calculating
the lumped element parameters from some basic analytic formulas is
usually not possible).

Note, that all temperatures of this package, including initial
conditions, are given in Kelvin.

## Basics

### HeatCapacitor
```@docs
HeatCapacitor
```
### ThermalConductor
```@docs
ThermalConductor
```
### Convection
```@docs
Convection
```
### BodyRadiation
```@docs
BodyRadiation
```
### ThermalCollector
```@docs
ThermalCollector
```
## Sources

### FixedTemperature
```@docs
FixedTemperature
```
### PrescribedTemperature
```@docs
PrescribedTemperature
```
### FixedHeatFlow
```@docs
FixedHeatFlow
```
### PrescribedHeatFlow
```@docs
PrescribedHeatFlow
```
