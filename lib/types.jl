
@doc """
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
""" -> type DocTypes <: DocTag end


########################################
## Types
########################################

@doc """
## NumberOrUnknown{T}
""" -> type DocT1 <: DocTag end

@doc """
`NumberOrUnknown{T}` is a typealias for
`Union(AbstractArray, Number, MExpr, RefUnknown{T}, Unknown{T})`.

Can be an Unknown, an AbstractArray, a Number, or an MExpr. Useful
where an object can be either an Unknown of a particular type or a
real value, especially for use as a type in a model argument. It may
be parameterized by an UnknownCategory, like NumberOrUnknown{UVoltage}
(the definition of an ElectricalNode).
""" ->
typealias NumberOrUnknown{T} Union(AbstractArray, Number, MExpr,
                                   RefUnknown{T}, Unknown{T})

@doc """
## Signal
""" -> type DocT2 <: DocTag end

@doc """
`Signal` is a typealias for `NumberOrUnknown{DefaultUnknown}`.

Can be an Unknown, an AbstractArray, a Number, or an MExpr.
""" ->
typealias Signal NumberOrUnknown{DefaultUnknown}
## typealias Signal Any

############################################
# Main electrical types
############################################
@doc """
# Electrical types
""" -> type DocElT <: DocTag end

@doc """
An UnknownCategory for electrical potential in volts.
""" ->
type UVoltage <: UnknownCategory
end
@doc """
An UnknownCategory for electrical current in amperes.
""" ->
type UCurrent <: UnknownCategory
end

@doc """
## ElectricalNode
""" -> type DocT3 <: DocTag end

@doc """
`ElectricalNode` is a typealias for `NumberOrUnknown{UVoltage}`.

An electrical node, either a Voltage (an Unknown) or a real value. Can
include arrays or complex values. Used commonly as a model arguments
for nodes. This allows nodes to be Unknowns or fixed values (like a
ground that's zero volts).
""" ->
typealias ElectricalNode NumberOrUnknown{UVoltage}

@doc """
## Voltage
""" -> type DocT4 <: DocTag end

@doc """
`Voltage` is a typealias for `Unknown{UVoltage}`.

Electrical potential with units of volts. Used as nodes and potential
differences between nodes.

Often used with `ElectricalNode` as a model argument.
""" ->
typealias Voltage Unknown{UVoltage}

@doc """
## Current
""" -> type DocT5 <: DocTag end

@doc """
`Current` is a typealias for `Unknown{UCurrent}`.

Electrical current with units of amperes. A flow variable.
""" ->
typealias Current Unknown{UCurrent}


############################################
# Main thermal types
############################################
@doc """
# Thermal types
""" -> type DocThT <: DocTag end

## Thermal
@doc """
An UnknownCategory for temperature in kelvin.
""" ->
type UHeatPort <: UnknownCategory
end

@doc """
An UnknownCategory for temperature in kelvin.
""" ->
type UTemperature <: UnknownCategory
end

@doc """
An UnknownCategory for heat flow rate in watts.
""" ->
type UHeatFlow <: UnknownCategory
end

@doc """
## HeatPort
""" -> type DocT6 <: DocTag end

@doc """
`HeatPort` is a typealias for `NumberOrUnknown{UHeatPort}`.

A thermal node, either a Temperature (an Unknown) or a real value. Can
include arrays. Used commonly as a model arguments for nodes. This
allows nodes to be Unknowns or fixed values.
""" ->
typealias HeatPort NumberOrUnknown{UHeatPort}

@doc """
## HeatFlow
""" -> type DocT7 <: DocTag end

@doc """
`HeatFlow` is a typealias for `Unknown{UHeatFlow}`.

Heat flow rate in units of watts.
""" ->
typealias HeatFlow Unknown{UHeatFlow}

@doc """
## Temperature
""" -> type DocT8 <: DocTag end

@doc """
`Temperature` is a typealias for `Unknown{UHeatPort}`.

A thermal potential, a Temperature (an Unknown) in units of kelvin.
""" ->
typealias Temperature Unknown{UHeatPort}



############################################
# Main mechanical types
############################################
@doc """
# Rotational types
""" -> type DocRoT <: DocTag end

## Mechanical rotation
@doc """
An UnknownCategory for rotational angle in radians.
""" ->
type UAngle <: UnknownCategory; end

@doc """
An UnknownCategory for torque in newton-meters.
""" ->
type UTorque <: UnknownCategory; end

@doc """
## Angle
""" -> type DocM1 <: DocTag end

@doc """
`Angle` is a typealias for `Unknown{UAngle}`.

The angle in radians.
""" ->
typealias Angle Unknown{UAngle}

@doc """
## Torque
""" -> type DocM2 <: DocTag end

@doc """
`Torque` is a typealias for `Unknown{UTorque}`.

The torque in newton-meters.
""" ->
typealias Torque Unknown{UTorque}

@doc """
An UnknownCategory for angular velocity in radians/sec.
""" ->
type UAngularVelocity <: UnknownCategory; end

@doc """
## AngularVelocity
""" -> type DocM3 <: DocTag end

@doc """
`AngularVelocity` is a typealias for `Unknown{UAngularVelocity}`.

The angular velocity in radians/sec.
""" ->
typealias AngularVelocity Unknown{UAngularVelocity}

@doc """
An UnknownCategory for angular acceleration in radians/sec^2.
""" ->
type UAngularAcceleration <: UnknownCategory; end


@doc """
## AngularAccelleration
""" -> type DocM4 <: DocTag end

@doc """
`AngularAcceleration` is a typealias for `Unknown{UAngularAcceleration}`.

The angular acceleration in radians/sec^2.
""" ->
typealias AngularAcceleration Unknown{UAngularAcceleration}

# Mechanical node:
@doc """
## Flange
""" -> type DocM5 <: DocTag end

@doc """
`Flange` is a typealias for `NumberOrUnknown{UAngle}`.

A rotational node, either an Angle (an Unknown) or a real value in
radians. Can include arrays. Used commonly as a model arguments for
nodes. This allows nodes to be Unknowns or fixed values.  
""" ->
typealias Flange NumberOrUnknown{UAngle}

