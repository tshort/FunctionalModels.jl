[![Example](http://pkg.julialang.org/badges/Sims_release.svg)](http://pkg.julialang.org/?pkg=Sims&ver=release)
[![Example](http://pkg.julialang.org/badges/Sims_nightly.svg)](http://pkg.julialang.org/?pkg=Sims&ver=nightly)
[![Build Status](https://travis-ci.org/tshort/Sims.jl.svg?branch=master)](https://travis-ci.org/tshort/Sims.jl)
[![Coverage Status](https://img.shields.io/coveralls/tshort/Sims.jl.svg)](https://coveralls.io/r/tshort/Sims.jl)


Sims.jl
=======

A [Julia](http://julialang.org) package for equation-based modeling
and simulations. For more information, see the documentation:

* **[Documentation for the released version](https://tshort.github.io/Sims.jl/stable)**.
* **[Documentation for the development version](https://tshort.github.io/Sims.jl/latest)**.

---

NOTE: This is a work in progress to convert this to use [ModelingToolkit](https://mtk.sciml.ai/).

---

Sims builds on top of [ModelingToolkit](https://mtk.sciml.ai/). The following
are exported:

* `t`
* `D` and `der`: aliases for Differential(t)
* `system`: flattens a set of hierarchical equations and returns a simplified `ODESystem`

Sims uses a functional style as opposed to the more object-oriented
approach of ModelingToolkit, Modia, and Modelica. Because `system`
return an `ODESystem`, models can be built up of Sims components and
standard ModelingToolkit components.


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
[Modelica](https://www.modelica.org/) family. The MathWorks company also has
Simscape that uses Matlab notation. Modelica is an object-oriented,
open language with multiple implementations. It is a large, complex,
powerful language with an extensive standard library of components.

This implementation follows the work of
[David Broman](http://web.ict.kth.se/~dbro/)
([thesis](http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf)
and [code](http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip))
and [George Giorgidze](http://db.inf.uni-tuebingen.de/team/giorgidze)
([Hydra code](https://github.com/giorgidze/Hydra) and
[thesis](http://db.inf.uni-tuebingen.de/files/giorgidze/phd_thesis.pdf))
and [Henrik Nilsson](http://www.cs.nott.ac.uk/~nhn/) and their
functional hybrid modeling. Sims is most similar to
[Modelyze](https://github.com/david-broman/modelyze) by David Broman
([report](http://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf)).

    
Installation
------------

Sims is an installable package. To install Sims, use the following:

```julia
Pkg.add("Sims")
```

Sims.jl has one main module named `Sims` and the following submodules:

* `Sims.Lib` -- the standard library

* `Sims.Examples` -- example models, including:
  * `Sims.Examples.Basics`
  * `Sims.Examples.Lib`
  * `Sims.Examples.Neural`

Basic example
-------------

Sims uses ModelingToolkit to build up models. All equations use the
ModelingToolkit variables and syntax.
In a simulation, the unknowns are to be solved based on a set of
equations. Equations are built from device models. 

A device model is a function that returns a vector of equations or
other devices that also return lists of equations. 

The Van Der Pol oscillator is a simple problem with two equations
and two unknowns:

``` julia
function Vanderpol()
    @variables x(t) y(t)
    # The following gives the return value which is a list of equations.
    # Expressions with variables are kept as expressions. Expressions of
    # regular variables are evaluated immediately.
    [
        D(x, -1.0) ~ (1 - y^2) * x - y
        D(y) ~ x
    ]
end
``` 

Electrical example
------------------

This example shows definitions of several electrical components. Each
is again a function that returns a list of equations. 

Arguments to each function are model parameters. These normally include
nodes specifying connectivity followed by parameters specifying model
characteristics.

Models can contain models or other functions that return equations.
The function `Branch` is a special function that returns an equation
specifying relationships between nodes and flows. It also acts as an
indicator to mark nodes. In the flattening/elaboration process,
equations are created to sum flows (in this case electrical currents)
to zero at all nodes. `RefBranch` is another special function for
marking nodes and flow variables.

Nodes passed as parameters are unknown variables. For these
electrical examples, a node is simply an unknown voltage.
 

```julia
Current() = Num(Variable{ModelingToolkit.FnType{Tuple{Any},Real}}(gensym("i")))(t)
Voltage() = Num(Variable{ModelingToolkit.FnType{Tuple{Any},Real}}(gensym("v")))(t)

function Resistor(n1, n2, R::Real) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        R * i ~ v
    ]
end

function Capacitor(n1, n2, C::Real) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        C * D(v) ~ i
    ]
end
```

What follows is a top-level circuit definition. In this case,
there are no input parameters. The ground reference "g" is
assigned zero volts.

All of the equations returned in the list of equations are other
models with various parameters.
   
```julia
function Circuit()
    n1 = Voltage()
    n2 = Voltage()
    g = 0.0  # A ground has zero volts; it's not an unknown.
    [
        SineVoltage(n1, g, 10.0, 60.0)
        Resistor(n1, n2, 10.0)
        Resistor(n2, g, 5.0)
        Capacitor(n2, g, 5.0e-3)
    ]
end

ckt = Circuit()
```

