"""
# The Sims standard library

---

**NOTE**: Many of these components are unfinished or broken. These are mainly components that require events and support of discrete systems.

---


These components are available with **Sims.Lib**.

Normal usage is:

```julia
using Sims
using Sims.Lib

# modeling...
```

Library components include models for:

* Electrical circuits
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
@comment



########################################
## Types
########################################


""" `Signal` is an alias for `Any` used to indicate a signal value or variable. """
const Signal = Any
""" `ElectricalNode` is an alias for `Any` used to indicate a node voltage value or variable. """
const ElectricalNode = Any
""" `HeatPort` is an alias for `Any` used to indicate a value or variable for a temperature port. """
const HeatPort = Any
""" `Flange` is an alias for `Any` used to indicate a value or variable for a flange port (an angle). """
const Flange = Any
# """ `Discrete` is an alias for `Any` used to indicate a value or variable that is Discrete. """
# const Discrete = Any

""" `Current(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:i`. """
Current(x = 0.0; name = :i) = Unknown(x, name = name)
""" `Voltage(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:v`. """
Voltage(x = 0.0; name = :v) = Unknown(x, name = name)
""" `HeatFlow(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:hf`. """
HeatFlow(x = 0.0; name = :hf) = Unknown(x, name = name)
""" `Temperature(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:T`. """
Temperature(x = 0.0; name = :T) = Unknown(x, name = name)
""" `Torque(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:torque`. """
Torque(x = 0.0; name = :torque) = Unknown(x, name = name)
""" `Angle(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:angle`. """
Angle(x = 0.0; name = :angle) = Unknown(x, name = name)
""" `AngularVelocity(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:angvelocity`. """
AngularVelocity(x = 0.0; name = :angvelocity) = Unknown(x, name = name)
""" `AngularAcceleration(x = 0.0; name = :i)` creates an `Unknown` with a default name of `:angacceleration`. """
AngularAcceleration(x = 0.0; name = :angacceleration) = Unknown(x, name = name)
