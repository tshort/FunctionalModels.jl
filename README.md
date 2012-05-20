
Julia Sims
==========

Introduction
------------

Sims is a Julia package to support equation-based modeling for
simulations. Sims is like a lite version of Modelica.

[Julia](http://julialang.org) is a fast, Matlab-like language that is
well suited to modeling and simulations.


Background
----------

This package is for non-causal modeling in Julia. The idea behind
non-causal modeling is that the user develops models based on
components which are described by a set of equations. A tool can then
transform the equations and solve the differential algebraic
equations. Non-causal models tend to match their physical counterparts
in terms of their specification and implementation.

Causal modeling is where all signals have an input and an output, and
the flow of information is clear. Simulink is the highest-profile
example. The problem with causal modeling is that it is difficult to
build up models from components.

The highest profile noncausal modeling tools are in the
[Modelica](www.modelica.org) family. The MathWorks company also has
Simscape that uses Matlab notation. Modelica is an object-oriented,
open language with multiple implementations. It is a large, complex,
powerful language with an extensive standard library of components.

This implementation follows the work of
[David Broman](http://www.ida.liu.se/~davbr/)
([thesis](http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf)
and [code](http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip)
and [George Giorgidze](http://db.inf.uni-tuebingen.de/team/giorgidze)
([Hydra code](https://github.com/giorgidze/Hydra) and
[thesis](http://db.inf.uni-tuebingen.de/files/giorgidze/phd_thesis.pdf))
and [Henrik Nilsson](http://www.cs.nott.ac.uk/~nhn/) and their
functional hybrid modeling . The DASKR solver is used to solve the
implicit DAE's generated. DASKR is a derivative of DASSL with root
finding.
    
Basic example
-------------

Sims defines a basic symbolic class used for unknown variables in
the model. As unknown variables are evaluated, expressions (of
type MExpr) are built up.

``` .jl
julia> a = Unknown()
##1243

julia> a * (a + 1)
MExpr(*(##1243,+(##1243,1)))
```

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
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
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
plot(y)
``` 

Here are the results:

![plot results](https://github.com/tshort-/Sims/blob/master/examples/vanderpol.png?raw=true "Van Der Pol results")


Electrical example
------------------

This example shows definitions of several electrical components. Each
is again a function that returns a list of equations. Equations are
expressions (type MExpr) that includes other expressions and unknowns
(type Unknown).

Arguments to each function are model parameters. These normally include
nodes specifying connectivity followed by parameters specifying model
characteristics.

Models can contain models or other functions that return equations.
The function Branch is a special function that returns an equation
specifying relationships between nodes and flows. It also acts as an
indicator to mark nodes. In the flattening/elaboration process,
equations are created to sum flows (in this case electrical currents)
to zero at all nodes. RefBranch is another special function for
marking nodes and flow variables.

Nodes passed as parameters or created with ElectricalNode() are simply
unknowns. For these electrical examples, a node is simply an unknown
voltage.
 
    
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
    n1 = ElectricalNode("Source voltage")   # The string indicates labeling for plots
    n2 = ElectricalNode("Output voltage")
    n3 = ElectricalNode()
    g = 0.0  # A ground has zero volts; it's not an unknown.
    {
     VSource(n1, g, 10.0, 60.0)
     Resistor(n1, n2, 10.0)
     Resistor(n2, g, 5.0)
     SeriesProbe(n2, n3, "Capacitor current")
     Capacitor(n3, g, 5.0e-3)
     }
end

ckt = Circuit()
ckt_y = sim(ckt, 0.1)
plot(ckt_y)
```
Here are the results:

![plot results](https://github.com/tshort-/Sims/blob/master/examples/circuit.png?raw=true "Circuit results")

Hybrid Modeling and Structural Variability
------------------------------------------

Sims supports basic hybrid modeling, including the ability to handle
structural model changes. Consider the following example:

[Breaking pendulum](https://github.com/tshort-/Sims/blob/master/examples/breaking_pendulum_in_box.jl)

This model starts as a pendulum, then the wire breaks, and the ball
goes into free fall. Sims handles this much like
[Hydra](https://github.com/giorgidze/Hydra); the model is recompiled.
Because Julia can quickly JIT code, this happens relatively quickly.
After the pendulum breaks, the ball bounces around in a box. This
shows off another feature of Sims: handling nonstructural events. Each
time the wall is hit, the velocity is adjusted for the "bounce".

Here is an animation of the results. Note that the actual animation
was done in R, not Julia.

![plot results](https://github.com/tshort-/Sims/blob/master/examples/pendulum.gif?raw=true "Pendulum")

To Look Deeper
--------------

For further examples, see here:
    
https://github.com/tshort-/Sims/tree/master/examples

Minimal documentation is here:

https://github.com/tshort-/Sims/blob/master/doc/README.md

The main code that defines functions and types for simulations is
here:

https://github.com/tshort-/Sims/blob/master/src/sims.jl

For future development options, see here (somewhat outdated):

https://github.com/tshort-/Sims/wiki/Possible-future-developments

Status
------

Please note that this is a developer preview. There could be bugs, and
everything is subject to change.  
    
