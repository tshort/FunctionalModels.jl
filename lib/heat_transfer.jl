

########################################
## Heat transfer models               ##
########################################

@comment """
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
"""


########################################
## Basic
########################################
@comment """
## Basics
"""


"""
Lumped thermal element storing heat

```julia
HeatCapacitor(hp::HeatPort, C::Signal)
```

### Arguments

* `hp::HeatPort` : heat port [K]
* `C::Signal` : heat capacity of the element [J/K]

### Details

This is a generic model for the heat capacity of a material. No
specific geometry is assumed beyond a total volume with uniform
temperature for the entire volume. Furthermore, it is assumed that the
heat capacity is constant (indepedent of temperature).

This component may be used for complicated geometries where the heat
capacity C is determined my measurements. If the component consists
mainly of one type of material, the mass m of the component may be
measured or calculated and multiplied with the specific heat capacity
cp of the component material to compute C:

```
   C = cp*m.
   Typical values for cp at 20 degC in J/(kg.K):
      aluminium   896
      concrete    840
      copper      383
      iron        452
      silver      235
      steel       420 ... 500 (V2A)
      wood       2500
```

NOTE: The Modelica Standard Library has an argument Tstart for the
starting temperature [K]. You really can't used that here as in
Modelica. You need to define the starting temperature at the top level
for the HeatPort you define.

"""
function HeatCapacitor(hp::HeatPort; C::Signal)
    Q_flow = HeatFlow(compatible_values(hp))
    [
        RefBranch(hp, Q_flow)
        der(hp) ~ Q_flow ./ C
    ]
end


"""
Lumped thermal element transporting heat without storing it

```julia
ThermalConductor(port_a::HeatPort, port_b::HeatPort, G::Signal)
```

### Arguments

* `port_a::HeatPort` : heat port [K]
* `port_b::HeatPort` : heat port [K]
* `G::Signal` : Constant thermal conductance of material [W/K]

### Details

This is a model for transport of heat without storing it. It may be
used for complicated geometries where the thermal conductance G (=
inverse of thermal resistance) is determined by measurements and is
assumed to be constant over the range of operations. If the component
consists mainly of one type of material and a regular geometry, it may
be calculated, e.g., with one of the following equations:

Conductance for a box geometry under the assumption that heat flows along the box length:

```
        G = k*A/L
        k: Thermal conductivity (material constant)
        A: Area of box
        L: Length of box
```

Conductance for a cylindrical geometry under the assumption that heat flows from the inside to the outside radius of the cylinder:

```
    G = 2*pi*k*L/log(r_out/r_in)
    pi   : Modelica.Constants.pi
    k    : Thermal conductivity (material constant)
    L    : Length of cylinder
    log  : Modelica.Math.log;
    r_out: Outer radius of cylinder
    r_in : Inner radius of cylinder
```

Typical values for k at 20 degC in W/(m.K):

```
      aluminium   220
      concrete      1
      copper      384
      iron         74
      silver      407
      steel        45 .. 15 (V2A)
      wood         0.1 ... 0.2
```

"""
function ThermalConductor(port_a::HeatPort, port_b::HeatPort; G::Signal)
    dT = Temperature(default_value(port_a) - default_value(port_b))
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    [
        Branch(port_a, port_b, dT, Q_flow)
        Q_flow ~ G .* dT
    ]
end


"""
Lumped thermal element for heat convection

```julia
Convection(port_a::HeatPort, port_b::HeatPort; Gc::Signal)
```

### Arguments

* `port_a::HeatPort` : heat port [K]
* `port_b::HeatPort` : heat port [K]
* `Gc::Signal` : convective thermal conductance [W/K]

### Details

This is a model of linear heat convection, e.g., the heat transfer
between a plate and the surrounding air. It may be used for
complicated solid geometries and fluid flow over the solid by
determining the convective thermal conductance Gc by measurements. The
basic constitutive equation for convection is

```
   Q_flow = Gc*(solidT - fluidT)
   Q_flow: Heat flow rate from connector 'solid' (e.g. a plate)
      to connector 'fluid' (e.g. the surrounding air)
```

Gc is an input signal to the component, since Gc is nearly never
constant in practice. For example, Gc may be a function of the speed
of a cooling fan. For simple situations, Gc may be calculated
according to

```
   Gc = A*h
   A: Convection area (e.g. perimeter*length of a box)
   h: Heat transfer coefficient
```

where the heat transfer coefficient h is calculated from properties of
the fluid flowing over the solid. Examples:

**Machines cooled by air** (empirical, very rough approximation according
to R. Fischer: Elektrische Maschinen, 10th edition, Hanser-Verlag
1999, p. 378):

```
    h = 7.8*v^0.78 [W/(m2.K)] (forced convection)
      = 12         [W/(m2.K)] (free convection)
    where
      v: Air velocity in [m/s]
```

**Laminar** flow with constant velocity of a fluid along a **flat
plate** where the heat flow rate from the plate to the fluid (=
solid.Q_flow) is kept constant (according to J.P.Holman: Heat
Transfer, 8th edition, McGraw-Hill, 1997, p.270):

```
   h  = Nu*k/x;
   Nu = 0.453*Re^(1/2)*Pr^(1/3);
   where
      h  : Heat transfer coefficient
      Nu : = h*x/k       (Nusselt number)
      Re : = v*x*rho/mue (Reynolds number)
      Pr : = cp*mue/k    (Prandtl number)
      v  : Absolute velocity of fluid
      x  : distance from leading edge of flat plate
      rho: density of fluid (material constant
      mue: dynamic viscosity of fluid (material constant)
      cp : specific heat capacity of fluid (material constant)
      k  : thermal conductivity of fluid (material constant)
   and the equation for h holds, provided
      Re < 5e5 and 0.6 < Pr < 50
```

"""
function Convection(port_a::HeatPort, port_b::HeatPort; Gc::Signal)
    dT = Temperature(default_value(port_a) - default_value(port_b))
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    [
        Branch(port_a, port_b, dT, Q_flow)
        Q_flow ~ Gc .* dT
    ]
end


"""

```julia
BodyRadiation(port_a::HeatPort, port_b::HeatPort, Gr::Signal)
```

### Arguments

* `port_a::HeatPort` : heat port [K]
* `port_b::HeatPort` : heat port [K]
* `Gr::Signal` : net radiation conductance between two surfaces [m2]


### Details

This is a model describing the thermal radiation, i.e.,
electromagnetic radiation emitted between two bodies as a result of
their temperatures. The following constitutive equation is used:

```
    Q_flow = Gr*sigma*(port_a^4 - port_b.4)
```

where Gr is the radiation conductance and sigma is the
Stefan-Boltzmann constant. Gr may be determined by measurements and is
assumed to be constant over the range of operations.

For simple cases, Gr may be analytically computed. The analytical
equations use epsilon, the emission value of a body which is in the
range 0..1. Epsilon=1, if the body absorbs all radiation (= black
body). Epsilon=0, if the body reflects all radiation and does not
absorb any.

```
   Typical values for epsilon:
   aluminium, polished    0.04
   copper, polished       0.04
   gold, polished         0.02
   paper                  0.09
   rubber                 0.95
   silver, polished       0.02
   wood                   0.85..0.9
```

**Analytical Equations for Gr**

**Small convex object in large enclosure (e.g., a hot machine in a room):**

```
    Gr = e*A
    where
       e: Emission value of object (0..1)
       A: Surface area of object where radiation
          heat transfer takes place
```

**Two parallel plates:**

```
    Gr = A/(1/e1 + 1/e2 - 1)
    where
       e1: Emission value of plate1 (0..1)
       e2: Emission value of plate2 (0..1)
       A : Area of plate1 (= area of plate2)
```

**Two long cylinders in each other, where radiation takes place from the
inner to the outer cylinder):**

```
    Gr = 2*pi*r1*L/(1/e1 + (1/e2 - 1)*(r1/r2))
    where
       pi: = Modelica.Constants.pi
       r1: Radius of inner cylinder
       r2: Radius of outer cylinder
       L : Length of the two cylinders
       e1: Emission value of inner cylinder (0..1)
       e2: Emission value of outer cylinder (0..1)
```

"""
function BodyRadiation(port_a::HeatPort, port_b::HeatPort; Gr::Signal)
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    sigma = 5.67037321e-8
    [
        RefBranch(port_a, Q_flow)
        RefBranch(port_b, -Q_flow)
        Q_flow ~ sigma .* Gr .* (port_a .^ 4 - port_b .^ 4)
    ]
end


"""
This is a model to collect the heat flows from m heatports to one
single heatport.

```julia
ThermalCollector(port_a::HeatPort, port_b::HeatPort)
```

### Arguments

* `port_a::HeatPort` : heat port [K]
* `port_b::HeatPort` : heat port [K]

"""
function ThermalCollector(port_a::HeatPort, port_b::HeatPort)
    # This ends up being a short circuit.
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    [
        Branch(port_a, port_b, 0.0, Q_flow)
    ]
end



########################################
## Sources
########################################

@comment """
## Sources
"""


"""
Fixed temperature boundary condition in Kelvin

This model defines a fixed temperature T at its port in Kelvin, i.e.,
it defines a fixed temperature as a boundary condition.

(Note that despite the name, the temperature can be fixed or
variable. FixedTemperature and PrescribedTemperature are identical;
naming is for Modelica compatibility.)

```julia
FixedTemperature(port::HeatPort, T::Signal)
```

### Arguments

* `port::HeatPort` : heat port [K]
* `T::Signal` : temperature at port [K]

"""
function FixedTemperature(port::HeatPort; T::Signal)
    Q_flow = HeatFlow(compatible_values(port, T))
    [
        Branch(port, T, 0.0, Q_flow)
    ]
end

"""
Variable temperature boundary condition in Kelvin

This model represents a variable temperature boundary condition. The
temperature in [K] is given as input signal T to the model. The effect
is that an instance of this model acts as an infinite reservoir able
to absorb or generate as much energy as required to keep the
temperature at the specified value.

(Note that despite the name, the temperature can be fixed or
variable. FixedTemperature and PrescribedTemperature are identical;
naming is for Modelica compatibility.)

```julia
PrescribedTemperature(port::HeatPort, T::Signal)
```

### Arguments

* `port::HeatPort` : heat port [K]
* `T::Signal` : temperature at port [K]

"""
const PrescribedTemperature = FixedTemperature


"""
Fixed heat flow boundary condition

This model allows a specified amount of heat flow rate to be
"injected" into a thermal system at a given port. The constant amount
of heat flow rate Q_flow is given as a parameter. The heat flows into
the component to which the component FixedHeatFlow is connected, if
parameter Q_flow is positive.

If parameter alpha is > 0, the heat flow is mulitplied by (1 +
alpha*(port - T_ref)) in order to simulate temperature dependent
losses (which are given an reference temperature T_ref).

(Note that despite the name, the heat flow can be fixed or
variable.)

```julia
FixedHeatFlow(port::HeatPort, Q_flow::Signal, T_ref::Signal = 293.15, alpha::Signal = 0.0)
FixedHeatFlow(port::HeatPort, Q_flow::Signal; T_ref::Signal = 293.15, alpha::Signal = 0.0)
```

### Arguments

* `port::HeatPort` : heat port [K]
* `Q_flow::Signal` : heat flow [W]

### Keyword/Optional Arguments

* `T_ref::Signal` : reference temperature [K]
* `alpha::Signal` : temperature coefficient of heat flow rate [1/K]

"""
function FixedHeatFlow(port::HeatPort; Q_flow::Signal, T_ref::Signal = 293.15, alpha::Signal = 0.0)
    Q_flow = HeatFlow(compatible_values(port, T))
    [
        RefBranch(port, Q_flow .* alpha .* (port - T_ref))
    ]
end
    
"""
Prescribed heat flow boundary condition

This model allows a specified amount of heat flow rate to be
"injected" into a thermal system at a given port. The constant amount
of heat flow rate Q_flow is given as a parameter. The heat flows into
the component to which the component PrescribedHeatFlow is connected,
if parameter Q_flow is positive.

If parameter alpha is > 0, the heat flow is mulitplied by (1 +
alpha*(port - T_ref)) in order to simulate temperature dependent
losses (which are given an reference temperature T_ref).

(Note that despite the name, the heat flow can be fixed or
variable.)

```julia
PrescribedHeatFlow(port::HeatPort, Q_flow::Signal, T_ref::Signal = 293.15, alpha::Signal = 0.0)
PrescribedHeatFlow(port::HeatPort, Q_flow::Signal; T_ref::Signal = 293.15, alpha::Signal = 0.0)
```

### Arguments

* `port::HeatPort` : heat port [K]
* `Q_flow::Signal` : heat flow [W]

### Keyword/Optional Arguments

* `T_ref::Signal` : reference temperature [K]
* `alpha::Signal` : temperature coefficient of heat flow rate [1/K]

"""
const PrescribedHeatFlow = FixedHeatFlow


