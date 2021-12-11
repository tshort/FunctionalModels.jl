# Design Documentation

This documentation is an overview of the design of FunctionalModels, particularly
the input specification. Some of the internals are also discussed.

## Overview

This implementation follows the work of David Broman and his MKL and
Modelyze simulators and the work of George Giorgidze and Henrik
Nilsson and their functional hybrid modeling.

A nodal formulation is used based on David's work. His thesis
documents this nicely:

* David Broman. Meta-Languages and Semantics for Equation-Based
  Modeling and Simulation. PhD thesis, Thesis No 1333. Department of
  Computer and Information Science, Linköping University,
  Sweden, 2010.
  http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf

Here is David's code and home page:

* http://web.ict.kth.se/~dbro/
* http://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf
* http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
* https://github.com/david-broman/modelyze

FunctionalModels implements something like David's approach in MKL and
Modelyze. Modelyze models in particular look quite similar to FunctionalModels
models. A model constructor returns a list of equations. Models are
made of models, so this builds up a hierarchical structure of
equations that then needs to be flattened. Like David's approach, FunctionalModels
is nodal; nodes are passed in as parameters to models to perform
connections between devices. 

Modeling of dynamically varying systems is handled similarly to
functional hybrid modelling (FHM), specifically the Hydra
implementation by George. See here for links:

* https://github.com/giorgidze/Hydra
* http://www.cs.nott.ac.uk/~nhn/

FHM is also a functional approach. Hydra is implemented as a domain
specific language embedded in Haskell. Their implementation handles
dynamically changing systems with JIT-compiled code from an amazingly
small amount of code.

 
Models can have positional function arguments and/or keyword function
arguments. Arguments may also have defaults. By convention in the
standard library, all models are defined with positional 
arguments for arguments that are normally nodes and keyword arguments
for all other model parameters.

As with most functional approaches, arguments to models can be model
types. This "functional composition" allows for easier replacement of
internal model subcomponents. For example, the `BranchHeatPort` in the
standard electrical library has the following signature:

```julia
function BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
                        model::Function; args...)
```

This can be used to add heat ports to any electrical branch passed in
with `model`. Here's an example of a definition defining a Resistor
that uses a heat port (a Temperature) in terms of another model:

```julia
function Resistor(n1::ElectricalNode, n2::ElectricalNode; R::Signal, hp::Temperature, T_ref::Signal, alpha::Signal) 
    BranchHeatPort(n1, n2, hp, Resistor, R = R .* (1 + alpha .* (hp - T_ref)))
end
```

By convention in the standard library, the first model arguments are
generally nodes.

## Special Model Features

The following are special model types, functions, or models that are handled
specially when flattening or during instantiation:

* `der(x)` or `D(x)` -- The time derivative of `x`.
* `t` -- The model time, secs.
* `RefBranch(node, flowvariable)` -- The type RefBranch is used to
  indicate the potential `node` and the flow
  (`flowvariable`) into the node from a branch connected to it.



