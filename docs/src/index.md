
Sims.jl
=======

A [Julia](http://julialang.org) package for equation-based modeling
and simulations using [ModelingToolkit](https://mtk.sciml.ai/dev/).

Background
----------

Sims is like a lite version of Modelica. This package is for
non-causal modeling in Julia. The idea behind non-causal modeling is
that the user develops models based on components which are described
by a set of equations. A tool can then transform the equations and
solve the differential algebraic equations. Non-causal models tend to
match their physical counterparts in terms of their specification and
implementation.

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

Sims creates a ModelingToolkit component. ModelingToolkit can be used
directly for noncausal modeling with more traditional composition of
components with `connect` and subsystems. Sims differs by using a 
more functional approach to composition.

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

