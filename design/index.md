
# Design Documentation

This documentation is an overview of the design of Sims, particularly
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

Sims implements something like David's approach in MKL and
Modelyze. Modelyze models in particular look quite similar to Sims
models. A model constructor returns a list of equations. Models are
made of models, so this builds up a hierarchical structure of
equations that then needs to be flattened. Like David's approach, Sims
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

## Unknowns and MExpr's

An `Unknown` is a symbolic type. When used in Julia expressions,
Unknowns combine into `MExpr`s which are symbolic representations of
equations.

Expressions (of type MExpr) are built up based on Unknown's. Unknown
is a symbol with a uniquely generated symbol name. If you have

```julia
  a = 1
  b = Unknown()
  a * b + b^2
```

evaluation produces the following:

```julia
  MExpr(+(*(1,##1029),*(##1029,##1029)))
```
  
This is an expression tree where `##1029` is the symbol name for `b`.

The idea is that you can set up a set of hierarchical equations that
will be later flattened.

Other types or method definitions can be used to assign behavior
during flattening (like the Branch type) or during instantiation
(like the der method).

Unknowns can contain Float64, Complex, and Array{Float64}
values. Additionally, Unknowns can contain values for any types with
`from_real` and `to_real` defined. These methods define conversions
from and to Float64 arrays. This allows Unknowns to be extended to
cover additional types.

In addition to a value, Unknowns can carry additional metadata,
including an identification symbol and a label. In the future, unit
information may be added.

Unknowns can also have type parameters. For example, `Voltage` is
defined as `Unknown{UVoltage}`. The `UVoltage` type parameter is a
marker to distinguish those Unknown from others. Users can add their
own Unknown types. Different Unknown types makes it easier to dispatch
on model arguments.

In addition to standard Unknowns, additional variations are Unknowns
are provided:

* `DerUnknown` -- Derivative of an Unknown (not normally used by a
  user).
* `Discrete` -- Discrete is a type for discrete variables. These are
  only changed during events. They are not used by the integrator.
* `Parameter` -- Fixed model parameters.
* `RefUnknown` and `RefDiscrete` -- Used for supporting arrays.
* `PassedUnknown` -- Identity unknown: don't replace with a ref to the
  y array. I don't remember what this is for:)

## Models

A model is a function definition that returns an Equation or array of
Equations. Models can contain Models. Here is an example of two models:

```julia
function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, k::Real)
    tau = Angle()
    i = Current()
    v = Voltage()
    w = AngularVelocity()
    Equation[
        Branch(n1, n2, i, v)
        RefBranch(flange, tau)
        w - der(flange)
        v - k * w
        tau - k * i
    ]
end

function DCMotor(flange::Flange)
    n1 = Voltage()
    n2 = Voltage()
    n3 = Voltage()
    g = 0.0
    Equation[
        SignalVoltage(n1, g, 60.0)
        Resistor(n1, n2, 100.0)
        Inductor(n2, n3, 0.2)
        EMF(n3, g, flange, 1.0)
    ]
end
```

The normal rules for function returns and array creation apply.

An `@equations` macro can also be used to specify the model
equations. The main difference is that `=` can be used in models. Like
`Equation[]`, the result is of type Array{Equation}. Here is an
example of one of the models above:

```julia
function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, k::Real)
    tau = Angle()
    i = Current()
    v = Voltage()
    w = AngularVelocity()
    @equations begin
        Branch(n1, n2, i, v)
        RefBranch(flange, tau)
        w = der(flange)
        v = k * w
        tau = k * i
    end
end
```

Equation definitions normally consist of other Models, MExpr's, or
special types for other features like
`InitialEquation(equations)`. Right now, `Equation == Any`, but that
could change in the future.

Any valid Julia is allowed in models and Equation definitions. Some
limitations include:

* `if-then-else` constructs evaluate immediately, so you cannot use
  them for dynamic decision actions in a model. Use the `ifelse` function
  instead. You can use `if-then-else` to pick between Equations to
  include based on static inputs.
    
* Some functions may not automatically combine to MExpr's. Most
  user-defined functions will work if functions are defined in terms
  of the basic functions supported in Sims. For functions that are not
  automatically converted, there are ways to extend Sims to support
  them. TODO: document this / make it a little easier.
    
Julia's multiple dispatch works well with a functional model
specification. Variations of models or entirely different models can
be defined with the same model name with different inputs. For example
a `Capacitor(n1::Voltage, n2::Voltage, C::Signal = 1.0)`
can specify an electrical model, and `Capacitor(hp::Temperature,
C::Signal)` can specify a thermal capacitor.

Models can have positional function arguments and/or keyword function
arguments. Arguments may also have defaults. By convention in the
standard library, all models are defined with positional function
arguments. Often, especially for long argument lists, versions with
keyword arguments are also provided. As with any Julia functions, use
`methods(Resistor)` to see all of the method definitions for
`Resistor`. Variable-length arguments (`args...`) can also be used in
models.  Model arguments can be typed or untyped. In the examples
above, model arguments are typed.  The electrical nodes have type
`ElectricalNode` from the standard library defined as

```julia
typealias NumberOrUnknown{T} Union(AbstractArray, Number, MExpr,
                                   RefUnknown{T}, Unknown{T})
typealias ElectricalNode NumberOrUnknown{UVoltage}
```

This allows the user to pass in a fixed value or an Unknown. A fixed
value can be used to fix voltage (zero for a ground reference). Arrays
can also be passed.

As with most functional approaches, arguments to models can be model
types. This "functional composition" allows for easier replacement of
internal model subcomponents. For example, the `BranchHeatPort` in the
standard electrical library has the following signature:

```julia
function BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
                        model::Function, args...)
```

This can be used to add heat ports to any electrical branch passed in
with `model`. Here's an example of a definition defining a Resistor
that uses a heat port (a Temperature) in terms of another model:

```julia
function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal, hp::Temperature, T_ref::Signal, alpha::Signal) 
    BranchHeatPort(n1, n2, hp, Resistor, R .* (1 + alpha .* (hp - T_ref)))
end
```

By convention in the standard library, the first model arguments are
generally nodes.

Right now, there are no substantial model checks.

## Special Model Features

The following are special model types, functions, or models that are handled
specially when flattening or during instantiation:

* `der(x)` -- The time derivative of `x`.
* `MTime` -- The model time, secs.
* `RefBranch(node, flowvariable)` -- The type RefBranch is used to
  indicate the potential `node` and the flow
  (`flowvariable`) into the node from a branch connected to it.
* `InitialEquation(equations)` -- Specifies an array of initial
  equations.
* `delay(x, val)` -- `x` delayed by `val`.
* `pre(x)` -- The value of a Discrete variable `x` prior to an event.
* `ifelse(condition, trueresult, falseresult)` -- Like an if-then-else
  block, but for ModelTypes.
* `Event(condition, pos_response, neg_response)` -- The main type for
  hybrid modeling; specifies a condition for root finding and model
  expressions to process after positive and negative root crossings
  are detected.
* `StructuralEvent(condition, default_model, new_relation)` -- A type
  for elements that change the structure of the model. An event is
  created (condition is the zero crossing). When the event is
  triggered, the model is re-flattened after replacing default with
  new_relation in the model.


## Connections / Nodal Models



## Model Flattening

`elaborate` is the main flattening function. There is no real symbolic
processing (sorting, index reduction, or any of the other stuff a
fancy modeling tool would do). This returns an `EquationSet` object
containing the hierarchical equations, flattened equations, flattened
initial equations, events, event response functions, and a map of
Unknown nodes.

```julia
type EquationSet
    model             # The active model, a hierachichal set of equations.
    equations         # A flat list of equations.
    initialequations  # A flat list of initial equations.
    events
    pos_responses
    neg_responses
    nodeMap::Dict
end
```

Here is an example of a flattened version of the example
`breaking_pendulum_in_box.jl`. This model contains standard Events and
a StructuralEvent.

```julia
julia> dump(p_f, 10)
EquationSet 
  model: Array(Any,(1,))
    ...
  equations: Array(Any,(6,))
    1: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: DerUnknown 
          sym: Symbol ##8244
          value: Float64 0.0
          fixed: Bool false
          parent: Unknown{DefaultUnknown} 
            sym: Symbol ##8244
            value: Float64 0.7853981633974483
            label: ASCIIString ""
            fixed: Bool false
            save_history: Bool false
        3: Unknown{DefaultUnknown} 
          sym: Symbol ##8245
          value: Float64 0.0
          label: ASCIIString ""
          fixed: Bool false
          save_history: Bool false
      typ: Any
    2: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: DerUnknown 
          sym: Symbol ##8240
          value: Float64 0.0
          fixed: Bool false
          parent: Unknown{DefaultUnknown} 
            sym: Symbol ##8240
            value: Float64 0.7071067811865476
            label: ASCIIString "x"
            fixed: Bool false
            save_history: Bool true
        3: Unknown{DefaultUnknown} 
          sym: Symbol ##8242
          value: Float64 0.0
          label: ASCIIString ""
          fixed: Bool false
          save_history: Bool false
      typ: Any
      ...
    6: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: DerUnknown 
          sym: Symbol ##8245
          value: Float64 0.0
          fixed: Bool false
          parent: Unknown{DefaultUnknown} 
            sym: Symbol ##8245
            value: Float64 0.0
            label: ASCIIString ""
            fixed: Bool false
            save_history: Bool false
        3: Expr 
          head: Symbol call
          args: Array(Any,(3,))
            1: *
            2: Float64 -9.81
            3: Expr 
              head: Symbol call
              args: Array(Any,(2,))
                1: sin
                2: Unknown{DefaultUnknown} 
                  sym: Symbol ##8244
                  value: Float64 0.7853981633974483
                  label: ASCIIString ""
                  fixed: Bool false
                  save_history: Bool false
              typ: Any
          typ: Any
      typ: Any
  initialequations: Array(Any,(6,))
    1: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: DerUnknown 
          sym: Symbol ##8244
          value: Float64 0.0
          fixed: Bool false
          parent: Unknown{DefaultUnknown} 
            sym: Symbol ##8244
            value: Float64 0.7853981633974483
            label: ASCIIString ""
            fixed: Bool false
            save_history: Bool false
        3: Unknown{DefaultUnknown} 
          sym: Symbol ##8245
          value: Float64 0.0
          label: ASCIIString ""
          fixed: Bool false
          save_history: Bool false
      typ: Any
    2: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: DerUnknown 
          sym: Symbol ##8240
          value: Float64 0.0
          fixed: Bool false
          parent: Unknown{DefaultUnknown} 
            sym: Symbol ##8240
            value: Float64 0.7071067811865476
            label: ASCIIString "x"
            fixed: Bool false
            save_history: Bool true
        3: Unknown{DefaultUnknown} 
          sym: Symbol ##8242
          value: Float64 0.0
          label: ASCIIString ""
          fixed: Bool false
          save_history: Bool false
      typ: Any
      ...
    6: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: DerUnknown 
          sym: Symbol ##8245
          value: Float64 0.0
          fixed: Bool false
          parent: Unknown{DefaultUnknown} 
            sym: Symbol ##8245
            value: Float64 0.0
            label: ASCIIString ""
            fixed: Bool false
            save_history: Bool false
        3: Expr 
          head: Symbol call
          args: Array(Any,(3,))
            1: *
            2: Float64 -9.81
            3: Expr 
              head: Symbol call
              args: Array(Any,(2,))
                1: sin
                2: Unknown{DefaultUnknown} 
                  sym: Symbol ##8244
                  value: Float64 0.7853981633974483
                  label: ASCIIString ""
                  fixed: Bool false
                  save_history: Bool false
              typ: Any
          typ: Any
      typ: Any
  events: Array(Any,(1,))
    1: Expr 
      head: Symbol call
      args: Array(Any,(3,))
        1: -
        2: Unknown{DefaultUnknown} 
          sym: Symbol time
          value: Float64 0.0
          label: ASCIIString ""
          fixed: Bool false
          save_history: Bool false
        3: Float64 1.8
      typ: Any
  pos_responses: Array(Any,(1,))
    1: (anonymous function)
  neg_responses: Array(Any,(1,))
    1: (anonymous function)
  nodeMap: Dict{Any,Any} len 0
```

The main steps in flattening are:

* Replace fixed initial values.
* Flatten models and populate `eq.equations`.
* Pull out InitialEquations and populate `eq.initialequations`.
* Pull out Events and populate `eq.events`.
* Handle StructuralEvents.
* Collect nodes and populate `eq.nodeMap`.
* Strip out MExpr's from expressions.
* Remove empty equations.

In EquationSet, `model` contains equations and StructuralEvents. When
a StructuralEvent triggers, the entire model is elaborated again.
The first step is to replace StructuralEvents that have activated
with their new_relation in model. Then, the rest of the EquationSet
is reflattened using `model` as the starting point.

## Model Instantiation

    From the flattened equations, `create_sim` generates a set of functions
    for use by the simulation. The residual function has arguments
    (t,y,yp) that returns the residual of type Float64 of length N, the
    number of equations in the system. The vectors y and yp are also of
    length N and type Float64. As part of finding the residual function,
    we use several Dicts to map unknown variables to indexes into y and
    yp.
    
    SimFunctions is the set of functions used during simulation. All
    functions take (t,y,yp) as arguments.

## Initial Equations


## Hybrid Modeling



## Structural Events

