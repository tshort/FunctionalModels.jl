
########################################
## Electrical library                 ##
########################################

"""
# Analog electrical models

This library of components is modeled after the
Modelica.Electrical.Analog library.

Voltage nodes with type `Voltage` are the main Unknown type used in
electrical circuits. `voltage` nodes can be single floating point
unknowns representing a single voltage node. A `Voltage` can also be
an array representing multiphase circuits or multiple node positions.
Lastly, `Voltage` unknowns can also be complex for use with
quasiphasor-type solutions.

The type `ElectricalNode` is a Union type that can be an Array, a
number, an expression, or an Unknown. This is used in model functions
to allow passing a `Voltage` node or a real value (like 0.0 for
ground).

**Example**

```julia
function ex_ChuaCircuit()
    @variables n1(t) n2(t) n3(t) = 4.0
    g = 0.0
    function NonlinearResistor(n1::ElectricalNode, n2::ElectricalNode; Ga, Gb, Ve)
        i = Current(compatible_values(n1, n2))
        v = Voltage(compatible_values(n1, n2))
        [
            Branch(n1, n2, v, i)
            i = IfElse.ifelse(v < -Ve, Gb .* (v + Ve) - Ga .* Ve,
                              IfElse.ifelse(v > Ve, Gb .* (v - Ve) + Ga*Ve, Ga*v))
        ]
    end
    [
        :r1 => Resistor(n1, g,  R = 12.5e-3) 
        :l1 => Inductor(n1, n2, L = 18.0)
        :r2 => Resistor(n2, n3, R = 1 / 0.565) 
        :c1 => Capacitor(n2, g, C = 100.0)
        :c2 => Capacitor(n3, g, C = 10.0)
        :r3 => NonlinearResistor(n3, g, Ga = -0.757576, Gb = -0.409091, Ve = 1.0)
    ]
end

```
"""
@comment 


using IfElse

########################################
## Basic
########################################
"""
## Basics
"""
@comment 

"""
The linear resistor connects the branch voltage `v` with the branch
current `i` by `i*R = v`. The Resistance `R` is allowed to be positive,
zero, or negative. 

```julia
Resistor(n1::ElectricalNode, n2::ElectricalNode; 
         R = 1.0, T = 293.15, T_ref = 300.15, alpha = 0.0)
Resistor(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort; 
         R = 1.0, T = 293.15, T_ref = 300.15, alpha = 0.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `R::Signal` : Resistance at temperature `T_ref` [ohms], default = 1.0 ohms
* `hp::HeatPort` : Heat port [K], optional                
* `T::HeatPort` : Fixed device temperature or HeatPort [K], default = `T_ref`
* `T_ref::Signal` : Reference temperature [K], default = 300.15K
* `alpha::Signal` : Temperature coefficient of resistance (`R_actual = R*(1 + alpha*(T_heatPort - T_ref))`) [1/K], default = 0.0

### Details

The resistance `R` is optionally temperature dependent according to
the following equation:

    R = R_ref*(1 + alpha*(hp.T - T_ref))
        
With the optional `hp` HeatPort argument, the power will be dissipated
into this HeatPort.

The resistance `R` can be a constant numeric value or an Unknown,
meaning it can vary with time. *Note*: it is recommended that the R
signal should not cross the zero value. Otherwise, depending on the
surrounding circuit, the probability of singularities is high.

This device is vectorizable using array inputs for one or both of
`n1` and `n2`.

### Example

```julia
function model()
    @variables n1
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 100.0)
        :r1   => Resistor(n1, g, R = 3.0, T = 330.0, alpha = 1.0)
    ]
end
```
"""
function Resistor(n1::ElectricalNode, n2::ElectricalNode; 
                  R::Signal, T = 300.15, T_ref = 300.15, alpha = 0.0)
    i = Current()
    v = Voltage(default_value(n1) - default_value(n2))
    [
        Branch(n1, n2, v, i)
        v ~ R .* (1 + alpha .* (T - T_ref)) .* i
    ]
end

function Resistor(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort; 
                         R::Signal, T_ref = 300.15, alpha = 0.0) 
    BranchHeatPort(n1, n2, hp, Resistor, R = R, T = hp, T_ref = T_ref, alpha = alpha)
end


"""
The linear capacitor connects the branch voltage `v` with the branch
current `i` by `i = C * dv/dt`. 

```julia
Capacitor(n1::ElectricalNode, n2::ElectricalNode; C::Signal) 
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `C::Signal` : Capacitance [F]

### Details

`C` can be a constant numeric value or an Unknown, meaning it can vary
with time. If `C` is a constant, it may be positive, zero, or
negative. If `C` is a signal, it should be greater than zero.

This device is vectorizable using array inputs for one or both of `n1`
and `n2`.

### Example

```julia    
function model()
    @variables n1(t)
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 100.0)
        :r    => Resistor(n1, g, R = 3.0)
        :c    => Capacitor(n1, g, C = 1.0)
    ]
end
```
"""
function Capacitor(n1::ElectricalNode, n2::ElectricalNode; C::Signal) 
    i = Current()
    v = Voltage(default_value(n1) - default_value(n2))
    [
        Branch(n1, n2, v, i) 
        der(v) ~ i ./ C
    ]
end


"""
The linear inductor connects the branch voltage `v` with the branch
current `i` by `v = L * di/dt`. 

```julia
Inductor(n1::ElectricalNode, n2::ElectricalNode; L::Signal)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `L::Signal` : Inductance [H]

### Details

`L` can be a constant numeric value or an Unknown,
meaning it can vary with time. If `L` is a constant, it may be
positive, zero, or negative. If `L` is a signal, it should be
greater than zero.

This device is vectorizable using array inputs for one or both of
`n1` and `n2`

### Example

```julia
function model()
    @variables n1(t)
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 100.0)
        :r    => Resistor(n1, g, R = 3.0)
        :c    => Inductor(n1, g, L = 6.0)
    ]
end
```
"""
function Inductor(n1::ElectricalNode, n2::ElectricalNode; L::Signal) 
    i = Current()
    v = Voltage(default_value(n1) - default_value(n2))
    [
        Branch(n1, n2, v, i) 
        der(i) ~ v ./ L
    ]
end

"""
To be done...

SaturatingInductor as implemented in the Modelica Standard Library
depends on a Discrete value that is not fixed. This is not currently
supported. Only Unknowns can currently be solved during initial
conditions.

"""
function SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode;
                            Inom,
                            Lnom,
                            Linf = Lnom ./ 2,
                            Lzer = Lnom .* 2)
    @assert Lzer > Lnom
    @assert Linf < Lnom
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(default_value(n1) - default_value(n2), "v_s")
    @named psi = Unknown(vals)
    @named Lact = Unknown(default_value(Linf))
    ## Lact = Unknown(vals)
    # initial equation equivalent (uses John Myles White's Optim package):
    Ipar = optimize(Ipar -> ((Lnom - Linf) - (Lzer - Linf)*Ipar[1]/Inom*(pi/2-atan2(Ipar[1],Inom))) ^ 2, [Inom]).minimum[1]
    println("Ipar: ", Ipar)
    [
        Branch(n1, n2, v, i)
        (Lact - Linf) .* i ./ Ipar ~ (Lzer - Linf) .* atan2(i, Ipar)
        psi ~ Lact .* i
        der(psi) ~ v
    ]
end

function SaturatingInductor2(n1::ElectricalNode, n2::ElectricalNode;
                             a, b, c)
    i = Current()
    v = Voltage(default_value(n1) - default_value(n2))
    @named psi = Unknown()
    [
        Branch(n1, n2, v, i)
        psi ~ a * tanh(b * i) + c * i
        der(psi) ~ v
    ]
end

function SaturatingInductor3(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    i = Current()
    v = Voltage(default_value(n1) - default_value(n2))
    @named psi = Unknown()
    [
        Branch(n1, n2, v, i)
        i ~ a * sinh(b * psi) - c * psi
        der(psi) ~ v
    ]
end

function SaturatingInductor4(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    i = Current()
    v = Voltage(default_value(n1) - default_value(n2))
    @named psi = Unknown()
    [
        Branch(n1, n2, v, i)
        psi ~ a * sign(i) * abs(i) ^ b + c * i
        der(psi) ~ v
    ]
end

"""
The transformer is a two port. The left port voltage `v1`, left port
current `i1`, right port voltage `v2` and right port current `i2` are
connected by the following relation:

    | v1 |         | L1   M  |  | i1' |
    |    |    =    |         |  |     |
    | v2 |         | M    L2 |  | i2' |

`L1`, `L2`, and `M` are the primary, secondary, and coupling inductances
respectively.

```julia
Transformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode; 
            L1 = 1.0, L2 = 1.0, M = 1.0)
```
### Arguments

* `p1::ElectricalNode` : Positive electrical node of the left port (potential `p1 > n1` for positive voltage drop v1) [V]
* `n1::ElectricalNode` : Negative electrical node of the left port [V]
* `p2::ElectricalNode` : Positive electrical node of the right port (potential `p2 > n2` for positive voltage drop v2) [V]
* `n2::ElectricalNode` : Negative electrical node of the right port [V]

### Keyword/Optional Arguments

* `L1::Signal` : Primary inductance [H]
* `L2::Signal` : Secondary inductance [H]
* `M::Signal`  : Coupling inductance [H]
"""
function Transformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode; 
                     L1, L2 = L1, M = L1)
    v1 = Voltage(default_value(p1) - default_value(n1))
    i1 = Current()
    v2 = Voltage()
    i2 = Current()
    di1 = Unknown()
    di2 = Unknown()
    [
        Branch(p1, n1, v1, i1)
        Branch(p2, n2, v2, i2)
        der(i1) ~ di1
        der(i2) ~ di2
        L1 .* di1 + M  .* di2 ~ v1
        M  .* di1 + L2 .* di2 ~ v2
    ]
end

"""
EMF transforms electrical energy into rotational mechanical energy. It
is used as basic building block of an electrical motor. The mechanical
connector `flange` can be connected to elements of the rotational
library. 

```julia
EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange,
    support_flange = 0.0, k = 1.0)
EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange;
    support_flange = 0.0, k = 1.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `flange::Flange` : Rotational shaft

### Keyword/Optional Arguments

* `support_flange` : Support/housing of the EMF shaft 
* `k` : Transformation coefficient [N.m/A] 
"""
function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange;
             support_flange::Flange = 0.0, k = 1.0)
    i = Current()
    v = Voltage()
    phi = Angle()
    tau = Torque()
    w = AngularVelocity()
    [
        Branch(n1, n2, i, v)
        Branch(flange, support_flange, phi, tau)
        der(phi) ~ w
        v ~ k * w
        tau ~ -k * i
    ]
end



########################################
## Ideal
########################################
"""
## Ideal
"""
@comment


"""
This is an ideal switch which is **open** (off), if it is reversed
biased (voltage drop less than 0) **closed** (on), if it is conducting
(`current > 0`). This is the behaviour if all parameters are exactly
zero. Note, there are circuits, where this ideal description with zero
resistance and zero cinductance is not possible. In order to prevent
singularities during switching, the opened diode has a small
conductance `Gon` and the closed diode has a low resistance `Roff`
which is default.

The parameter `Vknee` which is the forward threshold voltage, allows
to displace the knee point along the `Gon`-characteristic until `v =
Vknee`. 

```julia
IdealDiode(n1::ElectricalNode, n2::ElectricalNode; 
           Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `Vknee` : Forward threshold voltage [V], default = 0.0
* `Ron` : Closed diode resistance [Ohm], default = 1.E-5
* `Goff` : Opened diode conductance [S], default = 1.E-5

"""
function IdealDiode(n1::ElectricalNode, n2::ElectricalNode; 
                    Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    i = Current()
    v = Voltage()
    s = Unknown()  # dummy variable
    [
        Branch(n1, n2, v, i)
        Event(s ~ 0.0)
        v ~ s .* IfElse.ifelse(s < 0.0, 1.0, Ron) + Vknee
        i ~ s .* IfElse.ifelse(s < 0.0, Goff, 1.0) + Goff .* Vknee
    ]
end

"""
This is an ideal thyristor model which is **open** (off), if the
voltage drop is less than 0 or `fire` is false **closed** (on), if the
voltage drop is greater or equal 0 and `fire` is true.

This is the behaviour if all parameters are exactly zero. Note, there
are circuits, where this ideal description with zero resistance and
zero cinductance is not possible. In order to prevent singularities
during switching, the opened thyristor has a small conductance `Goff`
and the closed thyristor has a low resistance `Ron` which is default.

The parameter `Vknee` which is the forward threshold voltage, allows to
displace the knee point along the `Goff`-characteristic until `v =
Vknee`. 

```julia
IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire; 
               Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `fire` : Discrete bool variable indicating firing of the thyristor

### Keyword/Optional Arguments

* `Vknee` : Forward threshold voltage [V], default = 0.0
* `Ron` : Closed thyristor resistance [Ohm], default = 1.E-5
* `Goff` : Opened thyristor conductance [S], default = 1.E-5
"""
function IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire; 
                        Vknee, Ron = 1e-5, Goff = 1e-5)
    fire = Parameter(fire)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    spositive = Discrete(default_value(s) > 0.0)
    ## off = @map !spositive | (off & !fire) # on/off state of each switch
    off = map(x -> x[1],
              foldp((off, spositive, fire) -> (!spositive | (off[1] & !fire), spositive, fire),
                    (true, default_value(spositive), default_value(fire)), spositive, fire))
    [
        Branch(n1, n2, v, i)
        BoolEvent(spositive, s)
        v ~ s .* IfElse.ifelse(off, 1.0, Ron) + Vknee
        i ~ s .* IfElse.ifelse(off, Goff, 1.0) + Goff .* Vknee
    ]
end


"""
This is an ideal GTO thyristor model which is **open** (off), if the
voltage drop is less than 0 or `fire` is false **closed** (on), if the
voltage drop is greater or equal 0 and `fire` is true.

This is the behaviour if all parameters are exactly zero.  Note, there
are circuits, where this ideal description with zero resistance and
zero cinductance is not possible. In order to prevent singularities
during switching, the opened thyristor has a small conductance `Goff`
and the closed thyristor has a low resistance `Ron` which is default.

The parameter `Vknee` which is the forward threshold voltage, allows
to displace the knee point along the `Goff`-characteristic until `v =
Vknee`.

```julia
IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire; 
                  Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `fire` : Discrete bool variable indicating firing of the thyristor

### Keyword/Optional Arguments

* `Vknee` : Forward threshold voltage [V], default = 0.0
* `Ron` : Closed thyristor resistance [Ohm], default = 1.E-5
* `Goff` : Opened thyristor conductance [S], default = 1.E-5
"""
# function IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire, 
#                            Vknee, Ron = 1e-5, Goff = 1e-5)
#     vals = compatible_values(n1, n2) 
#     i = Current(vals)
#     v = Voltage(vals)
#     s = Unknown(vals)  # dummy variable
#     snegative = Discrete(default_value(s) < 0.0)  
#     off = @liftd :snegative | !:fire
#     [
#         Branch(n1, n2, v, i)
#         BoolEvent(snegative, -s)
#         v = s .* IfElse.ifelse(off, 1.0, Ron) + Vknee
#         i = s .* IfElse.ifelse(off, Goff, 1.0) + Goff .* Vknee
#     ]
# end
# function IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire; 
#                            Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
#     IdealGTOThyristor(n1, n2, fire, Vknee, Ron, Goff)
# end

  
"""
The ideal OpAmp is a two-port device. The left port is fixed to `v1=0` and
`i1=0` (nullator). At the right port, both any voltage `v2` and any
current `i2` are possible (norator).

The ideal OpAmp with three pins is of exactly the same behaviour as the
ideal OpAmp with four pins. Only the negative output pin is left out.
Both the input voltage and current are fixed to zero (nullator). At the
output pin both any voltage `v2` and any current `i2` are possible.

```julia
IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode)
IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode)
```
### Arguments

* `p1::ElectricalNode` : Positive electrical node of the left port (potential `p1 > n1` for positive voltage drop v1) [V]
* `n1::ElectricalNode` : Negative electrical node of the left port [V]
* `p2::ElectricalNode` : Positive electrical node of the right port (potential `p2 > n2` for positive voltage drop v2) [V]
* `n2::ElectricalNode` : Negative electrical node of the right port [V], defaults to 0.0 V
"""
function IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode)
    i = Current(compatible_values(p2, n2))
    v = Voltage(compatible_values(p2, n2))
    [
        p1 ~ n1      # voltages at the input are equal
                     # currents at the input are zero, so leave out
        Branch(p2, n2, v, i) # at the output, make the currents equal
    ]
end
function IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode)
    i = Current(compatible_values(p2))
    [
        p1 ~ n1
        RefBranch(p2, i)
    ]
end

"""
The ideal opening switch has a positive pin `p` and a negative pin `n`. The
switching behaviour is controlled by the input signal `control`. If
control is true, pin p is not connected with negative pin n. Otherwise,
pin p is connected with negative pin n.

In order to prevent singularities during switching, the opened switch
has a (very low) conductance `Goff` and the closed switch has a (very low)
resistance `Ron`. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.

```julia
IdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                   Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `control` : true => switch open, false => n1-n2 connected

### Keyword/Optional Arguments

* `Ron` : Closed switch resistance [Ohm], default = 1.E-5
* `Goff` : Opened switch conductance [S], default = 1.E-5
"""
function IdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                            Ron, Goff = 1e-5)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    [
        Branch(n1, n2, v, i)
        v ~ s .* IfElse.ifelse(control, 1.0, Ron)
        i ~ s .* IfElse.ifelse(control, Goff, 1.0)
    ]
end
  
"""
The ideal closing switch has a positive node `n1` and a negative node `n2`. The
switching behaviour is controlled by input signal `control`. If `control` is
true, `n1` and `n2` are connected. 

In order to prevent singularities during switching, the opened switch
has a (very low) conductance `Goff` and the closed switch has a (very low)
resistance `Ron`. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.

```julia
IdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                   Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `control` : true => n1 & n2 connected, false => switch open

### Keyword/Optional Arguments

* `Ron` : Closed switch resistance [Ohm], default = 1.E-5
* `Goff` : Opened switch conductance [S], default = 1.E-5
"""
function IdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                            Ron,  Goff = 1e-5)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    [
        Branch(n1, n2, v, i)
        ## DiscreteEvent(control)
        v ~ s .* IfElse.ifelse(control, Ron, 1.0)
        i ~ s .* IfElse.ifelse(control, 1.0, Goff)
    ]
end
  
"""
This ideal opening switch has a positive node `n1` and a negative node `n2`. The
switching behaviour is controlled by the voltage `control`. If `control` is
greater than `level`, `n1` and `n2` are not connected (open switch). 
If `control` is less than `level`, the switch is closed.

In order to prevent singularities during switching, the opened switch
has a (very low) conductance `Goff` and the closed switch has a (very low)
resistance `Ron`. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.

```
ControlledIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                   level, Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `control` : Control voltage [V]

### Keyword/Optional Arguments

* `level` : Switching voltage [V]
* `Ron` : Closed switch resistance [Ohm], default = 1.E-5
* `Goff` : Opened switch conductance [S], default = 1.E-5
"""
function ControlledIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                                      level,  Ron = 1e-5,  Goff = 1e-5)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    [
        Branch(n1, n2, v, i)
        Event(control ~ level)  # switch opens when control goes below level
        v ~ s .* IfElse.ifelse(control > level, 1.0, Ron)
        i ~ s .* IfElse.ifelse(control > level, Goff, 1.0)
    ]
end
                                      

"""
This ideal opening switch has a positive node `n1` and a negative node `n2`. The
switching behaviour is controlled by the voltage `control`. If `control` is
greater than `level`, `n1` and `n2` are connected (closed switch). 
If `control` is less than `level`, the switch is open.

In order to prevent singularities during switching, the opened switch
has a (very low) conductance `Goff` and the closed switch has a (very low)
resistance `Ron`. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.

```
ControlledIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                   level, Ron = 1e-5, Goff = 1e-5)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `control` : Control voltage [V]

### Keyword/Optional Arguments

* `level` : Switching voltage [V]
* `Ron` : Closed switch resistance [Ohm], default = 1.E-5
* `Goff` : Opened switch conductance [S], default = 1.E-5
"""
function ControlledIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control;
                                      level,  Ron = 1e-5,  Goff = 1e-5)
    ControlledIdealOpeningSwitch(n1, n2, control = level, level = control, Ron = Ron, Goff = Goff) # note that level and control are swapped
end


"""
This model is an extension to the `IdealOpeningSwitch`.

The basic model interupts the current through the switch in an
infinitesimal time span. If an inductive circuit is connected, the
voltage across the switch is limited only by numerics. In order to give
a better idea for the voltage across the switch, a simple arc model is
added:

When the Boolean input `control` signals to open the switch, a voltage
across the opened switch is impressed. This voltage starts with `V0`
(simulating the voltage drop of the arc roots), then rising with slope
`dVdt` (simulating the rising voltage of an extending arc) until a
maximum voltage `Vmax` is reached.


         | voltage
    Vmax |      +-----
         |     /
         |    /
    V0   |   +
         |   |
         +---+-------- time

This arc voltage tends to lower the current following through the
switch; it depends on the connected circuit, when the arc is quenched.
Once the arc is quenched, i.e., the current flowing through the switch
gets zero, the equation for the off-state is activated `i=Goff*v`.

When the Boolean input `control` signals to close the switch again,
the switch is closed immediately, i.e., the equation for the on-state is
activated `v=Ron*i`.

Please note: In an AC circuit, at least the arc quenches when the next
natural zero-crossing of the current occurs. In a DC circuit, the arc
will not quench if the arc voltage is not sufficient that a
zero-crossing of the current occurs.

This model is the same as ControlledOpenerWithArc, but the switch
is closed when `control > level`. 

```julia
ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control;
                        level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `control::Signal` : `control > level` the switch is opened, otherwise closed

### Keyword/Optional Arguments

* `level` : Switch level [V], default = 0.5
* `Ron` : Closed switch resistance [Ohm], default = 1.E-5
* `Goff` : Opened switch conductance [S], default = 1.E-5
* `V0` : Initial arc voltage [V], default = 30.0
* `dVdt` : Arc voltage slope [V/s], default = 10e3
* `Vmax` : Max. arc voltage [V], default = 60.0
"""
# MSL equations:
#   control.i = 0;
#   0 = p.i + n.i;
#   i = p.i;
#   p.v - n.v = v;
#   when edge(off) then
#     tSwitch=time;
#   end when;
#   quenched=off and (abs(i)<=abs(v)*Goff or pre(quenched));
#   if on then
#     v=Ron*i;
#   else
#     if quenched then
#       i=Goff*v;
#     else
#       v=min(Vmax, V0 + dVdt*(time - tSwitch))*sign(i);
#     end if;
#   end if;
#  LossPower = v*i;
# function ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control;
#                                  level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
#     ControlledOpenerWithArc(n1, n2, control, level, Ron, Goff, V0, dVdt, Vmax)
# end
# function ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control,
#                                  level,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
#     i = Current()
#     v = Voltage(default_value(n1) - default_value(n2))
#     on = Discrete(false)  # on/off state of switch
#     off = @liftd !:on
#     quenched = Discrete(true)  # whether the arc is quenched or not
#     tSwitch = Discrete(0.0)  # time of last open initiation
#     [
#         Branch(n1, n2, v, i)
#         Event(level - control,
#               reinit(on, true),
#               [
#                   reinit(on, false)
#                   reinit(quenched, false)
#                   reinit(tSwitch, t)
#               ])
#         Event(i,
#               [
#                   reinit(i, 0.0)
#                   ifelse(!quenched & off, reinit(quenched, true))
#               ],
#               [
#                   reinit(i, 0.0)
#                   ifelse(!quenched & off, reinit(quenched, true))
#               ])
#         ifelse(on,
#                v - Ron .* i,
#                ifelse(quenched,
#                       i - Goff .* v,
#                       v - min(Vmax, V0 + dVdt .* (t - tSwitch))) .* sign(i))
#     ]
# end
# function ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control;
#                                  level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
#     ControlledOpenerWithArc(n1, n2, control, level, Ron, Goff, V0, dVdt, Vmax)
# end

"""
This model is the same as ControlledOpenerWithArc, but the switch
is closed when `control > level`. 

```julia
ControlledCloserWithArc(n1::ElectricalNode, n2::ElectricalNode, control;
                        level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `control::Signal` : `control > level` the switch is closed, otherwise open

### Keyword/Optional Arguments

* `level` : Switch level [V], default = 0.5
* `Ron` : Closed switch resistance [Ohm], default = 1.E-5
* `Goff` : Opened switch conductance [S], default = 1.E-5
* `V0` : Initial arc voltage [V], default = 30.0
* `dVdt` : Arc voltage slope [V/s], default = 10e3
* `Vmax` : Max. arc voltage [V], default = 60.0
"""
# function ControlledCloserWithArc(n1::ElectricalNode, n2::ElectricalNode, control,
#                                  level,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
#     ControlledOpenerWithArc(n1, n2, level, control, Ron, Goff, V0, dVdt, Vmax)
# end
# function ControlledCloserWithArc(n1::ElectricalNode, n2::ElectricalNode, control;
#                                  level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
#     ControlledCloserWithArc(n1, n2, control, level, Ron, Goff, V0, dVdt, Vmax)
# end


    
########################################
## Semiconductors
########################################
"""
## Semiconductors
"""
@comment 


"""
The simple diode is a one port. It consists of the diode itself and an
parallel ohmic resistance `R`. The diode formula is:

    i  =  ids * ( e^(v/vt) - 1 )

If the exponent `v/vt` reaches the limit `maxex`, the diode
characterisic is linearly continued to avoid overflow.

```julia
Diode(n1::ElectricalNode, n2::ElectricalNode; 
      Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)
Diode(n1::ElectricalNode, n2::ElectricalNode; hp::HeatPort;
      Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `hp::HeatPort` : Heat port [K]                

### Keyword/Optional Arguments

* `Ids` : Saturation current [A], default = 1.e-6
* `Vt` : Voltage equivalent of temperature (kT/qn) [V], default = 0.04
* `Maxexp` : Max. exponent for linear continuation, default = 15.0
* `R` : Parallel ohmic resistance [Ohm], default = 1.e8
"""
function Diode(n1::ElectricalNode, n2::ElectricalNode; 
               Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        i ~ IfElse.ifelse(v ./ Vt > Maxexp,
                          Ids .* exp(Maxexp) .* (1 + v ./ Vt - Maxexp) - 1 + v ./ R,
                          Ids .* (exp(v ./ Vt) - 1) + v ./ R)
    ]
end

# Diode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort, args...) =
#     BranchHeatPort(n1, n2, hp, Diode, args...)
# Diode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort; args...) =
#     BranchHeatPort(n1, n2, hp, Diode, args...)

"""
TBD
"""
function ZDiode(n1::ElectricalNode, n2::ElectricalNode;
                Ids,  Vt = 0.04,  Maxexp = 30.0,  R = 1e8,  Bv = 5.1, Ibv = 0.7,  Nbv = 0.74)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    [
        Branch(n1, n2, v, i)
        i ~ IfElse.ifelse(v ./ Vt > Maxexp,
                          Ids .* exp(Maxexp) .* (1 + v ./ Vt - Maxexp) - 1 + v ./ R,
                          IfElse.ifelse((v + Bv) < -Maxexp .* (Nbv .* Vt),
                                        -Ids - Ibv .* exp(Maxexp) .* (1 - (v+Bv) ./ (Nbv .* Vt) - Maxexp) + v ./ R,
                                        Ids .* (exp(v ./ Vt)-1) - Ibv .* exp(-(v + Bv)/(Nbv .* Vt)) + v ./ R))
    ]
end



"""
The simple diode is an electrical one port, where a heat port is added,
which is defined in the Thermal library. It consists of the
diode itself and an parallel ohmic resistance `R`. The diode formula is:

    i  =  ids * ( e^(v/vt_t) - 1 )

where `vt_t` depends on the temperature of the heat port:

    vt_t = k*temp/q

If the exponent `v/vt_t` reaches the limit `maxex`, the diode
characterisic is linearly continued to avoid overflow. The thermal
power is calculated by `i*v`.

```julia
HeatingDiode(n1::ElectricalNode, n2::ElectricalNode; 
             T = 293.15,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `T` : Heat port [K], default = 293.15
* `Ids` : Saturation current [A], default = 1.e-6
* `Maxexp` : Max. exponent for linear continuation, default = 15.0
* `R` : Parallel ohmic resistance [Ohm], default = 1.e8
* `EG` : Activation energy, default = 1.11
* `N` : Emmission coefficient, default = 1.0
* `TNOM` : Parameter measurement temperature [K], default = 300.15
* `XTI` : Temperature exponent of saturation current, default = 3.0
"""
# function HeatingDiode(n1::ElectricalNode, n2::ElectricalNode, 
#                       T,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)
#     vals = compatible_values(n1, n2)
#     i = Current(vals)
#     v = Voltage(vals)
#     powerloss = Unknown(default_value(i) * default_value(v))
#     vt_t = Unknown(1.0)
#     aux = Unknown()
#     auxp = Unknown()
#     id = Unknown()
#     k = 1.380662e-23  # Boltzmann's constant, J/K
#     q = 1.6021892e-19 # Electron charge, As
#     exlin(x, maxexp) = ifelse(x > maxexp, exp(maxexp)*(1 + x - maxexp), exp(x))
#     [
#         Branch(n1, n2, v, i)
#         if isa(T, Temperature)
#             [
#                 RefBranch(T, -powerloss)
#                 powerloss - i * v
#             ] 
#         end
#         vt_t ~ k * T / q
#         id ~ exlin(v / (N * vt_t), Maxexp) - 1
#         aux * N * vt_t ~ (T / TNOM - 1) * EG 
#         auxp ~ exp(aux)
#         i ~ Ids * id * (T / TNOM) ^ (XTI / N) * auxp + v / R
#     ]
# end
# function HeatingDiode(n1::ElectricalNode, n2::ElectricalNode; 
#                       T = 293.15,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)
#     HeatingDiode(n1, n2, T, Ids, Maxexp, R, EG, N, TNOM, XTI)                  
# end



########################################
## Sources
########################################
"""
## Sources
"""
@comment 


"""
The signal voltage source is a parameterless converter of real valued
signals into a source voltage.

This voltage source may be vectorized.

```julia
SignalVoltage(n1::ElectricalNode, n2::ElectricalNode; V::Signal)  
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `V::Signal` : Voltage between n1 and n2 (= n1 - n2) as an input signal
"""
function SignalVoltage(n1::ElectricalNode, n2::ElectricalNode; V::Signal)  
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i) 
        v ~ V
    ]
end

"""
A sinusoidal voltage source. An offset parameter is introduced,
which is added to the value calculated by the blocks source. The
startTime parameter allows to shift the blocks source behavior on the
time axis.

This voltage source may be vectorized.

```julia
SineVoltage(n1::ElectricalNode, n2::ElectricalNode; 
            V = 1.0,  f = 1.0,  ang = 0.0,  offset = 0.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `V` : Amplitude of sine wave [V], default = 1.0
* `phase` : Phase of sine wave [rad], default = 0.0
* `freqHz` : Frequency of sine wave [Hz], default = 1.0
* `offset` : Voltage offset [V], default = 0.0
* `startTime` : Time offset [s], default = 0.0
"""
function SineVoltage(n1::ElectricalNode, n2::ElectricalNode; 
                     V = 1.0,  f = 1.0,  ang = 0.0,  offset = 0.0)
    SignalVoltage(n1, n2, V = V .* sin(2pi .* f .* t + ang) + offset)
end


"""
A step voltage source. An event is introduced at the transition.
Probably cannot be vectorized.

```julia
StepVoltage(n1::ElectricalNode, n2::ElectricalNode; 
            V = 1.0,  start = 0.0,  offset = 0.0)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]

### Keyword/Optional Arguments

* `V` : Height of step [V], default = 1.0
* `offset` : Voltage offset [V], default = 0.0
* `startTime` : Time offset [s], default = 0.0
"""
function StepVoltage(n1::ElectricalNode, n2::ElectricalNode; 
                     V = 1.0,  start = 0.0,  offset = 0.0)
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i) 
        v ~ IfElse.ifelse(t > start, V + offset, offset)
        # Event(t - start,
        #       [reinit(v_mag, offset + V)],        # positive crossing
        #       [reinit(v_mag, offset)])            # negative crossing
    ]
end
    

"""
The signal current source is a parameterless converter of real valued
signals into a current voltage.

This current source may be vectorized.

```julia
SignalCurrent(n1::ElectricalNode, n2::ElectricalNode; I::Signal)  
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `I::Signal` : Current flowing from n1 to n2 as an input signal
"""
function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode; 
                       I::Signal)  
    [
        RefBranch(n1, I) 
        RefBranch(n2, -I) 
    ]
end


########################################
## Utilities
########################################
"""
## Utilities
"""
@comment 


"""
Connect a series current probe between two nodes. This is
vectorizable.

```julia
SeriesProbe(n1, n2; name::AbstractString)
```

### Arguments

* `n1` : Positive node
* `n2` : Negative node
* `name::AbstractString` : The name of the probe

### Example

```julia
function model()
    @named n1 = Voltage()
    @named n2 = Voltage()
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 100.0)
        :i => SeriesProbe(n1, n2, "current")
        :r => Resistor(n2, g, R = 2.0)
    ]
end
```
"""
function SeriesProbe(n1, n2; name) 
    i = Unknown(name)
    [Branch(n1, n2, compatible_values(n1, n2), i)]
end


"""
Wrap argument `model` with a heat port that captures the power
generated by the electrical device. This is vectorizable.

```julia
BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
               model::Function, args...)
```

### Arguments

* `n1::ElectricalNode` : Positive electrical node [V]
* `n2::ElectricalNode` : Negative electrical node [V]
* `hp::HeatPort` : Heat port [K]                
* `model::Function` : Model to wrap
* `args...` : Arguments passed to `model`  

### Examples

Here's an example of a definition defining a Resistor that uses a heat
port (a Temperature) in terms of another model:

```julia
function ResistorWithHeating(n1::ElectricalNode, n2::ElectricalNode, R::Signal, hp::Temperature; T_ref::Signal, alpha::Signal) 
    BranchHeatPort(n1, n2, hp, Resistor, R .* (1 + alpha .* (hp - T_ref)))
end
```
"""
function BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
                        model::Function, args...; kwargs...)
    i = Current()
    v = Voltage()
    n = Voltage()
    PowerLoss = HeatFlow()
    hp => [
        PowerLoss ~ sum(v .* i)
        RefBranch(hp, -PowerLoss)
        v ~ n1 - n2
        Branch(n1, n, 0.0, i)
        model(n, n2, args...; kwargs...)
    ]
end

