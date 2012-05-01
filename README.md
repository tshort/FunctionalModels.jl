

Julia Sims
==========
Introduction
------------

Sims is the beginnings of a Julia package to support
equation-based modeling for simulations. Sims is like a lite
version of Modelica or Simscape from Mathworks.

[Julia](http://julialang.org) is a fast, Matlab-like language that is well suited to
modeling and simulations.


Background
----------

This file is an experiment in doing non-causal modeling in Julia.
The idea behind non-causal modeling is that the user develops models
based on components which are described by a set of equations. A
tool can then transform the equations and solve the differential
algebraic equations. Non-causal models tend to match their physical
counterparts in terms of their specification and implementation.

Causal modeling is where all signals have an input and an output,
and the flow of information is clear. Simulink is the
highest-profile example.

The highest profile noncausal modeling tools are in the Modelica
(www.modelica.org) family. The MathWorks also has Simscape that uses
Matlab notation. Modelica is an object-oriented, open language with
multiple implementations. It is a large, complex, powerful language
with an extensive standard library of components.

This implementation follows the work of David Broman:

  http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf
  
  http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
  
  http://www.ida.liu.se/~davbr/

The DASSL solver is used to solve the implicit DAE's generated.
    
Basic example
-------------

Sims defines a basic symbolic class used for unknown variables in
the model. As unknown variables are evaluated, expressions (of
type MExpr) are built up.

    .jl
    julia> a = Unknown()
    ##1243

    julia> a * (a + 1)
    MExpr(*(##1243,+(##1243,1)))

In a simulation, the unknowns are to be solved based on a set of
equations. Equations are built from device models. 

A device model is a function that returns a list of equations or
other devices that also return lists of equations. The equations
each are assumed equal to zero. So,

``` .jl
der(y) = x + 1
```

Should be entered as:

``` .jl
der(y) - (x+1)
```

der indicates a derivative.

The Van Der Pol oscillator is a simple problem with two equations
and two unknowns:

``` .jl
function Vanderpol()
    y = Unknown(1.0)   # The 1.0 is the initial value.
    x = Unknown()      # The initial value is zero if not given.
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately.
    {
     # The -1.0 in der(x, -1.0) is the initial value for the derivative 
     der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed
     der(y) - x
     }
end

y = sim(Vanderpol(), 10.0) # Run the simulation to 10 seconds and return
                           # the result as an array.
# plot the results
plot(y[:,1], y[:,2], y[:,1], y[:,3])
``` 

Here are the results:

![plot results](https://github.com/tshort-/Sims/raw/master/vanderpol.png "Van Der Pol results")


Electrical example
------------------

This example shows
definitions of several electrical components. Each is again a
function that returns a list of equations. Equations are
expressions (type MExpr) that includes other expressions and
unknowns (type Unknown).

Arguments to each function are model parameters. These are normally
nodes specifying connectivity followed by parameters specifying
model characteristics.

Models can contain models or other functions that return equations.
The function Branch is a special function that returns an equation
specifying relationships between nodes and flows. It also acts as an
indicator to mark nodes. In the flattening/elaboration process, equations are
created to sum flows (in this case electrical currents) to zero at
all nodes. RefBranch is another special function for marking nodes
and flow variables.

Nodes passed as parameters or created with ElectricalNode() are
simply unknowns. For these electrical examples, a node is simply an
unknown voltage.
 
    
``` .jl
function Resistor(n1, n2, R::Real) 
    i = Current()   # This is simply an Unknown. 
    v = Voltage()
    {
     Branch(n1, n2, v, i)
     R * i - v   # == 0 is implied
     }
end

function Capacitor(n1, n2, C::Real) 
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i)
     C * der(v) - i     
     }
end
```

What follows is a top-level circuit definition. In this case,
there are no input parameters. The ground reference "g" is
assigned zero volts.

All of the equations returned in the list of equations are other
models with various parameters.
   
``` .jl
function Circuit()
    n1 = ElectricalNode()
    n2 = ElectricalNode()
    g = 0.0  # A ground has zero volts; it's not an unknown.
    {
     VSource(n1, g, 10.0, 60.0)
     Resistor(n1, n2, 10.0)
     Resistor(n2, g, 5.0)
     Capacitor(n2, g, 5.0e-3)
     }
end

ckt = Circuit()
ckt_y = sim(ckt, 0.1)  
```

For further examples, see here:
    
https://github.com/tshort-/Sims/example-sims.jl


    
