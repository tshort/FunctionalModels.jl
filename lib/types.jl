
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

Current(x = 0.0; name = :i) = Unknown(x, name = name)
Voltage(x = 0.0; name = :v) = Unknown(x, name = name)
HeatFlow(x = 0.0; name = :hf) = Unknown(x, name = name)
Temperature(x = 0.0; name = :T) = Unknown(x, name = name)
Torque(x = 0.0; name = :torque) = Unknown(x, name = name)
Angle(x = 0.0; name = :angle) = Unknown(x, name = name)
AngularVelocity(x = 0.0; name = :angvelocity) = Unknown(x, name = name)
AngularAcceleration(x = 0.0; name = :angacceleration) = Unknown(x, name = name)
