
@comment """
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
"""


########################################
## Types
########################################

@doc """
`NumberOrUnknown{T,C}` is a typealias for
`Union(AbstractArray, Number, MExpr, RefUnknown{T}, Unknown{T,C})`.

Can be an Unknown, an AbstractArray, a Number, or an MExpr. Useful
where an object can be either an Unknown of a particular type or a
real value, especially for use as a type in a model argument. It may
be parameterized by an UnknownCategory, like NumberOrUnknown{UVoltage}
(the definition of an ElectricalNode).
""" ->
typealias NumberOrUnknown{T,C} Union(AbstractArray, Number, MExpr,
                                     RefUnknown{T}, Unknown{T,C})

@doc """
`Signal` is a typealias for `NumberOrUnknown{DefaultUnknown}`.

Can be an Unknown, an AbstractArray, a Number, or an MExpr.
""" ->
typealias Signal NumberOrUnknown{DefaultUnknown,Normal}
## typealias Signal Any

############################################
# Main electrical types
############################################
@comment """
# Electrical types
"""

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
`ElectricalNode` is a typealias for `NumberOrUnknown{UVoltage,Normal}`.

An electrical node, either a Voltage (an Unknown) or a real value. Can
include arrays or complex values. Used commonly as a model arguments
for nodes. This allows nodes to be Unknowns or fixed values (like a
ground that's zero volts).
""" ->
typealias ElectricalNode NumberOrUnknown{UVoltage,Normal}

@doc """
`Voltage` is a typealias for `Unknown{UVoltage,Normal}`.

Electrical potential with units of volts. Used as nodes and potential
differences between nodes.

Often used with `ElectricalNode` as a model argument.
""" ->
typealias Voltage Unknown{UVoltage,Normal}

@doc """
`Current` is a typealias for `Unknown{UCurrent,Normal}`.

Electrical current with units of amperes. A flow variable.
""" ->
typealias Current Unknown{UCurrent,Normal}


############################################
# Main thermal types
############################################
@comment """
# Thermal types
"""

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

@comment """
## HeatPort
"""

@doc """
`HeatPort` is a typealias for `NumberOrUnknown{UHeatPort,Normal}`.

A thermal node, either a Temperature (an Unknown) or a real value. Can
include arrays. Used commonly as a model arguments for nodes. This
allows nodes to be Unknowns or fixed values.
""" ->
typealias HeatPort NumberOrUnknown{UHeatPort,Normal}

@doc """
`HeatFlow` is a typealias for `Unknown{UHeatFlow,Normal}`.

Heat flow rate in units of watts.
""" ->
typealias HeatFlow Unknown{UHeatFlow,Normal}

@doc """
`Temperature` is a typealias for `Unknown{UHeatPort,Normal}`.

A thermal potential, a Temperature (an Unknown) in units of kelvin.
""" ->
typealias Temperature Unknown{UHeatPort,Normal}



############################################
# Main mechanical types
############################################
@comment """
# Rotational types
"""

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
`Angle` is a typealias for `Unknown{UAngle,Normal}`.

The angle in radians.
""" ->
typealias Angle Unknown{UAngle,Normal}

@doc """
`Torque` is a typealias for `Unknown{UTorque,Normal}`.

The torque in newton-meters.
""" ->
typealias Torque Unknown{UTorque,Normal}

@doc """
An UnknownCategory for angular velocity in radians/sec.
""" ->
type UAngularVelocity <: UnknownCategory; end

@doc """
`AngularVelocity` is a typealias for `Unknown{UAngularVelocity,Normal}`.

The angular velocity in radians/sec.
""" ->
typealias AngularVelocity Unknown{UAngularVelocity,Normal}

@doc """
An UnknownCategory for angular acceleration in radians/sec^2.
""" ->
type UAngularAcceleration <: UnknownCategory; end


@doc """
`AngularAcceleration` is a typealias for `Unknown{UAngularAcceleration,Normal}`.

The angular acceleration in radians/sec^2.
""" ->
typealias AngularAcceleration Unknown{UAngularAcceleration,Normal}

# Mechanical node:

@doc """
`Flange` is a typealias for `NumberOrUnknown{UAngle,Normal}`.

A rotational node, either an Angle (an Unknown) or a real value in
radians. Can include arrays. Used commonly as a model argument for
nodes. This allows nodes to be Unknowns or fixed values.  
""" ->
typealias Flange NumberOrUnknown{UAngle,Normal}

