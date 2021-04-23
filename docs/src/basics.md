# Documentation

This document provides a general introduction to Sims.

## Unknowns

Models consist of equations and unknown variables. The number of
equations should match the number of unknowns. In Sims, the function
`Unknown` is used to define unknown Symbolics.jl variables. 

Unknowns also contain a value. This is used for setting initial
values. Unknowns can be different types. 

The label string is used for labeling simulation outputs. Unlabeled
Unknowns are not included in results.

Here are several ways to define Unknowns:

```julia
x = Unknown()          # An initial value of 0.0 with an anonymous name.
y = Unknown(1.0, name = :y)  # An initial value of 1.0 and a name of `y`.
@named y = Unknown(1.0)       # Same.
@named z = Unknown([1.0, 0.0])  # An Unknown with array values.
```


In model equations, derivatives are specified with `der` or `D`:

```julia
   der(y) ~ 3
```

## Models

Here is a model of the Van Der Pol oscillator:

```julia
function Vanderpol()
    @named y = Unknown(1.0)   
    @named x = Unknown()       
    @named dx = Unknown(-1.0)       
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    [
        der(x) ~ dx
        der(x, -1.0) ~ (1 - y^2) * x - y
        der(y) ~ x
    ]
end
```

A device model is a function that returns a list of equations or other
devices that also return lists of equations. 

Models should normally be locally balanced, meaning the number of
unknowns matches the number of equations. It's pretty easy to match
unknowns and equations as shown below:

```julia
function Capacitor(n1, n2; C) 
    i = Current()              # Unknown #1
    v = Voltage()              # Unknown #2
    [
        Branch(n1, n2, v, i)      # Equation #1 - this returns n1 - n2 - v
        C * der(v) ~ i            # Equation #2
    ]
end
```

In the model above, the nodes `n1` and `n2` are also `Unknowns`, but they
are defined outside of this model.

Here is the top-level circuit definition. In this case, there are no
input parameters. The ground reference `g` is assigned zero volts.

```julia
function Circuit()
    @named n = ElectricalNode()
    @named n = ElectricalNode()
    @named n = ElectricalNode()
    g = 0.0  # a ground has zero volts; it's not an Unknown.
    [
        VSource(n1, g, V = 10.0, f = 60.0)
        Resistor(n1, n2, R = 10.0)
        Resistor(n2, g, R = 5.0)
        SeriesProbe(n2, n3, name = "Capcurrent")
        Capacitor(n3, g, C = 5.0e-3)
    ]
end
```

All of the equations returned in this list of equations are other
models with different parameters.

In this top-level model, three new Unknowns are introduced (`n1`, `n2`,
and `n2`). Because these are nodes, each `Unknown` node will also cause an
equation to be generated that sums the flows into the node to be zero.

In this model, the voltages `n1` and `n2` are labeled, so they will
appear in the output. A `SeriesProbe` is used to label the current
through the capacitor.


## Simulating a Model

Steps to building and simulating a model are straightforward.

```julia
v = Vanderpol()       # returns the hierarchical model
v_sys = system(v)     # returns the flattened model as a ModelingToolkit.ODEProblem
```

From here, all modeling and plotting is done with ModelingToolkit.

