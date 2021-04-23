
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tshort.github.io/Sims.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tshort.github.io/Sims.jl/dev)
[![Build Status](https://github.com/tshort/Sims.jl/workflows/CI/badge.svg)](https://github.com/tshort/Sims.jl/actions)

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

* `t`: independent variable
* `D` and `der`: aliases for `Differential(t)`
* `system`: flattens a set of hierarchical equations and returns a simplified `ODESystem`
* `Unknown`: helper function to create variables
* `default_value`: return the default (starting) value of a variable
* `compatible_values`: return the base value from a variable to use when creating other variables
* `RefBranch` and `Branch`: marks nodes and flow variables

Equations are standard ModelingToolkit equations. The main difference in Sims is
that variables should be created with `Unknown(val; name)` or one of the helpers like `Voltage()`.
Variables created this way include metadata to ensure that variable names don't clash.
Multiple subcomponents can all have a `v(t)` variable for example.
Once the model is flattened, the variable names will be normalized.

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

Model Libraries
---------------

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

function Resistor(n1, n2; R::Real) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        R * i ~ v
    ]
end

function Capacitor(n1, n2; C::Real) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        D(v) ~ i / C
    ]
end
```

What follows is a top-level circuit definition. In this case,
there are no input parameters. The ground reference "g" is
assigned zero volts.

All of the equations returned in the list of equations are other
models with various parameters.

In this example, the model components are named (`:vs`, `:r1`, ...).
Unnamed components can also be used, but then variables used 
in components have anonymized naming (`c1₊i(t)` vs. `var"##i#1057"(t)`).
   
```julia
function Circuit()
    @named n1 = Voltage()
    @named n2 = Voltage()
    g = 0.0  # A ground has zero volts; it's not an unknown.
    [
        :vs => SineVoltage(n1, g, V = 10.0, f = 60.0)
        :r1 => Resistor(n1, n2, R = 10.0)
        :r2 => Resistor(n2, g, R = 5.0)
        :c1 => Capacitor(n2, g, C = 5.0e-3)
    ]
end

ckt = Circuit()
```

