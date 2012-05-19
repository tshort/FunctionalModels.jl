

# Basic Documentation

Documentation is limited as Sims is in its early stages (like Julia).
The [examples](../examples) are probably the best place to start.

The basics are described here.

## Unknowns

Models consist of equations and unknown variables. The number of
equations should match the number of unknowns. In Sims, the type
Unknown is used to define unknown variables. Without the constructor
parts, the definition of Unknown is:

```jl
type Unknown{T<:UnknownCategory} <: UnknownVariable
    sym::Symbol
    value         # holds initial values (and type info)
    label::String 
end
```

Unknowns can be grouped into categories. That's what the T is for in
the definition above. One can define different types of Unknowns
(electrical vs. mechanical for example). The default is
DefaultUnknown. Unknowns also contain a value. This is used for
setting initial values, and these values are updated if there is a
structural change in the model. Unknowns can be different types.
Eventually, all Unknowns are converted to Float64s in an array for
simulation. Currently, Sim supports Unknowns of type Float64,
Complex128, and arrays of either of these. Adding support for other
structures is not hard as long as they can be converted to Float64's.

The label string is used for labeling simulation outputs. Unlabeled
Unknowns are not included in results.

Here are several ways to define Unknowns

```jl
x = Unknown()          # An initial value of 0.0 with no labeling.
y = Unknown(1.0, "y")  # An initial value of 1.0 and a label of "y" on outputs.
z = Unknown([1.0, 0.0], "vector")  # An Unknown with array values.
V = Unknown{Voltage}(10.0, "Output voltage")  # An Unknown of type Voltage
```

Here are ways to create new Unknown types:

```jl
# Untyped Unknowns:
Angle = AngularVelocity = AngularAcceleration = Torque = RotationalNode = Unknown

# Typed Unknowns:
type UVoltage <: UnknownCategory
end
type UCurrent <: UnknownCategory
end
typealias ElectricalNode Unknown{UVoltage}
typealias Voltage Unknown{UVoltage}
typealias Current Unknown{UCurrent}
```
In model equations, derivatives are specified with der:

```jl
   der(y)
```

Derivatives of Unknowns are an object of type DerUnknown. DerUnknown
objects contain an initial value, and a pointer to the Unknown object
it references. Initial values are most commonly entered as the second
parameter to the der function:

```jl
   der(y, 3.0) - (x+1)   #  The derivative of y starts with the value 3.0
```

## Models

Here is a model of the Van Der Pol oscillator:

```jl
function Vanderpol()
    y = Unknown(1.0, "y")   
    x = Unknown("x")       
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(x, -1.0) - ((1 - y^2) * x - y)   # == 0 is assumed
     der(y) - x
     }
end
```

A device model is a function that returns a list of equations or other
devices that also return lists of equations. The equations each are
assumed equal to zero. In Julia, this is the best we can do, because
there isn't an equality operator (== doesn't fit the bill, either).

Models should normally be locally balanced, meaning the number of
unknowns matches the number of equations. It's pretty easy to match
unknowns and equations as shown below:

```jl
function Capacitor(n1, n2, C::Real) 
    i = Current()              # Unknown #1
    v = Voltage()              # Unknown #2
    {
     Branch(n1, n2, v, i)      # Equation #1 - this returns n1 - n2 - v
     C * der(v) - i            # Equation #2
     }
end
```

In the model above, the nodes n1 and n2 are also Unknowns, but they
are defined outside of this model.


Here is the top-level circuit definition. In this case, there are no
input parameters. The ground reference "g" is assigned zero volts.

```jl
function Circuit()
    n1 = ElectricalNode("Source voltage")   # The string indicates labeling for plots
    n2 = ElectricalNode("Output voltage")
    n3 = ElectricalNode()
    g = 0.0  # a ground has zero volts; it's not an Unknown.
    {
     VSource(n1, g, 10.0, 60.0)
     Resistor(n1, n2, 10.0)
     Resistor(n2, g, 5.0)
     SeriesProbe(n2, n3, "Capacitor current")
     Capacitor(n3, g, 5.0e-3)
     }
end
```

All of the equations returned in this list of equations are other
models with different parameters.

In this top-level model, three new Unknowns are introduced (n1, n2,
and n2). Because these are nodes, each Unknown node will also cause
an equation to be generated that sums the flows into the node to be
zero.

In this model, the voltages n1 and n2 are labeled, so they will
appear in the output. A SeriesProbe is used to label the current
through the capacitor.


## Simulating a Model

Steps to building and simulating a model are straightforward.

```jl
v = Vanderpol()       # returns the hierarchical model
v_f = elaborate(v)    # returns the flattened model
v_s = create_sim(v_f) # returns a "Sim" ready for simulation
v_yout = sim(v_s, 10.0) # run the simulation to 10 seconds and return
                        # the result as an array plus column headings
```

Simulations can also be run directly from a hierarchical model:

```jl
v_yout = sim(v, 10.0) 
```

Right now, there are really no options available for simulation
parameters.

## Simulation Output

The result of a "sim" run is an object with components "y" and
"colnames". "y" is a two-dimensional array with time slices along
rows and variables along columns. The first column is simulation
time. The remaining columns are for each unknown in the model
including derivatives. "colnames" contains the names of each of
the columns in "y" after the time column.

## Discrete Modeling

Sims provides basic support for hybrid modeling.



