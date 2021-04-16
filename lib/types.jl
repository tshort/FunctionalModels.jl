
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
| ------------------- | --------------------- | -------------------- | ---------------- |
| Electrical systems  | `Current`             | `Voltage`            | `ElectricalNode` |
| Heat transfer       | `HeatFlow`            | `Temperature`        | `HeatPort`       |
| Mechanical rotation | `Torque`              | `Angle`              | `Flange`         |

ModelingToolkit does not have variable types, so `Signal`, `ElectricalNode`, `HeatPort`, and
`Flange` are all aliases of `Any`, mainly to help with documentation of models.

`Current`, `Voltage`, `HeatFlow`, `Temperature`, `Torque`, and `Angle` are all helper functions 
that create variables with `gensym`.

"""


########################################
## Types
########################################

@comment """
## Basic types
"""

const Signal = Any
const ElectricalNode = Any
const HeatPort = Any
const Flange = Any
const Discrete = Any

Current(x = 0.0) = Unknown(x, :i)
Voltage(x = 0.0) = Unknown(x, :v)
HeatFlow(x = 0.0) = Unknown(x, :hf)
Temperature(x = 0.0) = Unknown(x, :T)
Torque(x = 0.0) = Unknown(x, :torque)
Angle(x = 0.0) = Unknown(x, :angle)
AngularVelocity(x = 0.0) = Unknown(x, :angvelocity)
AngularAcceleration(x = 0.0) = Unknown(x, :angacceleration)
