



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
|---------------------|-----------------------|----------------------|------------------|
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





## NumberOrUnknown{T}




## Union(Unknown{T}, AbstractArray{T, N}, RefUnknown{T}, Number, MExpr)

`NumberOrUnknown{T}` is a typealias for
`Union(AbstractArray, Number, MExpr, RefUnknown{T}, Unknown{T})`.

Can be an Unknown, an AbstractArray, a Number, or an MExpr. Useful
where an object can be either an Unknown of a particular type or a
real value, especially for use as a type in a model argument. It may
be parameterized by an UnknownCategory, like NumberOrUnknown{UVoltage}
(the definition of an ElectricalNode).

[Sims/src/../lib/types.jl:65](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L65)




## Signal




## Union(AbstractArray{T, N}, Unknown{DefaultUnknown}, Number, RefUnknown{DefaultUnknown}, MExpr)

`Signal` is a typealias for `NumberOrUnknown{DefaultUnknown}`.

Can be an Unknown, an AbstractArray, a Number, or an MExpr.

[Sims/src/../lib/types.jl:77](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L77)




# Electrical types




## UVoltage

An UnknownCategory for electrical potential in volts.

[Sims/src/../lib/types.jl:90](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L90)



## UCurrent

An UnknownCategory for electrical current in amperes.

[Sims/src/../lib/types.jl:95](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L95)




## ElectricalNode




## Union(AbstractArray{T, N}, RefUnknown{UVoltage}, Unknown{UVoltage}, Number, MExpr)

`ElectricalNode` is a typealias for `NumberOrUnknown{UVoltage}`.

An electrical node, either a Voltage (an Unknown) or a real value. Can
include arrays or complex values. Used commonly as a model arguments
for nodes. This allows nodes to be Unknowns or fixed values (like a
ground that's zero volts).

[Sims/src/../lib/types.jl:110](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L110)




## Voltage




## Unknown{UVoltage}

`Voltage` is a typealias for `Unknown{UVoltage}`.

Electrical potential with units of volts. Used as nodes and potential
differences between nodes.

Often used with `ElectricalNode` as a model argument.

[Sims/src/../lib/types.jl:124](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L124)




## Current




## Unknown{UCurrent}

`Current` is a typealias for `Unknown{UCurrent}`.

Electrical current with units of amperes. A flow variable.

[Sims/src/../lib/types.jl:135](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L135)




# Thermal types




## UHeatPort

An UnknownCategory for temperature in kelvin.

[Sims/src/../lib/types.jl:149](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L149)



## UTemperature

An UnknownCategory for temperature in kelvin.

[Sims/src/../lib/types.jl:155](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L155)



## UHeatFlow

An UnknownCategory for heat flow rate in watts.

[Sims/src/../lib/types.jl:161](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L161)




## HeatPort




## Union(Unknown{UHeatPort}, AbstractArray{T, N}, RefUnknown{UHeatPort}, Number, MExpr)

`HeatPort` is a typealias for `NumberOrUnknown{UHeatPort}`.

A thermal node, either a Temperature (an Unknown) or a real value. Can
include arrays. Used commonly as a model arguments for nodes. This
allows nodes to be Unknowns or fixed values.

[Sims/src/../lib/types.jl:175](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L175)




## HeatFlow




## Unknown{UHeatFlow}

`HeatFlow` is a typealias for `Unknown{UHeatFlow}`.

Heat flow rate in units of watts.

[Sims/src/../lib/types.jl:186](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L186)




## Temperature




## Unknown{UHeatPort}

`Temperature` is a typealias for `Unknown{UHeatPort}`.

A thermal potential, a Temperature (an Unknown) in units of kelvin.

[Sims/src/../lib/types.jl:197](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L197)




# Rotational types




## UAngle

An UnknownCategory for rotational angle in radians.

[Sims/src/../lib/types.jl:212](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L212)



## UTorque

An UnknownCategory for torque in newton-meters.

[Sims/src/../lib/types.jl:217](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L217)




## Angle




## Unknown{UAngle}

`Angle` is a typealias for `Unknown{UAngle}`.

The angle in radians.

[Sims/src/../lib/types.jl:228](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L228)




## Torque




## Unknown{UTorque}

`Torque` is a typealias for `Unknown{UTorque}`.

The torque in newton-meters.

[Sims/src/../lib/types.jl:239](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L239)



## UAngularVelocity

An UnknownCategory for angular velocity in radians/sec.

[Sims/src/../lib/types.jl:244](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L244)




## AngularVelocity




## Unknown{UAngularVelocity}

`AngularVelocity` is a typealias for `Unknown{UAngularVelocity}`.

The angular velocity in radians/sec.

[Sims/src/../lib/types.jl:255](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L255)



## UAngularAcceleration

An UnknownCategory for angular acceleration in radians/sec^2.

[Sims/src/../lib/types.jl:260](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L260)




## AngularAccelleration




## Unknown{UAngularAcceleration}

`AngularAcceleration` is a typealias for `Unknown{UAngularAcceleration}`.

The angular acceleration in radians/sec^2.

[Sims/src/../lib/types.jl:272](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L272)




## Flange




## Union(AbstractArray{T, N}, Unknown{UAngle}, Number, MExpr, RefUnknown{UAngle})

`Flange` is a typealias for `NumberOrUnknown{UAngle}`.

A rotational node, either an Angle (an Unknown) or a real value in
radians. Can include arrays. Used commonly as a model arguments for
nodes. This allows nodes to be Unknowns or fixed values.  

[Sims/src/../lib/types.jl:286](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/../lib/types.jl#L286)

