# Sims

The API for use of Sims. Includes basic models and functions for
flattening, simulation, and plotting.




## BoolEvent
BoolEvent is a helper for attaching an event to a boolean variable.
In conjunction with `ifelse`, this allows constructs like Modelica's
if blocks.

Note that the lengths of `d` and `condition` must match for arrays.

```julia
BoolEvent(d::Discrete, condition::ModelType)
```

### Arguments

* `d::Discrete` : the discrete variable.
* `condition::ModelType` : the model expression(s) 

### Returns

* `::Event` : a model Event

### Examples

See [IdealDiode](../lib/index.html#IdealDiode) and
[Limiter](../lib/index.html#Limiter) in the standard library.


**source:**
[Sims/src/main.jl:1160](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1160)
## Branch
A helper Model to connect a branch between two different nodes and
specify potential between nodes and the flow between nodes.

See also [RefBranch](#RefBranch).

```julia
Branch(n1, n2, v, i)
```

### Arguments

* `n1` : the positive reference node.
* `n2` : the negative reference node.
* `v` : the potential variable between nodes.
* `i` : the flow variable between nodes.

### Returns

* `::Array{Equation}` : the model, consisting of a RefBranch entry for
  each node and an equation assigning `v` to `n1 - n2`.

### References

This nodal description is based on work by [David
Broman](http://web.ict.kth.se/~dbro/). See the following:

* http://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf
* http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
* https://github.com/david-broman/modelyze

### Examples

Here is the definition of an electrical resistor in the standard
library:

```julia
function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    @equations begin
        Branch(n1, n2, v, i)
        v = R .* i
    end
end
```

**source:**
[Sims/src/main.jl:759](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L759)
## addhook!
Add hooks to a Discrete variable.

The propagation and handling of Discrete variables is currently rather
simple. It would be nice for Discrete variables to handle data flows
like a reactive programming system. This allows for a simple way to
add some value propagation.

### Arguments

* `d::Discrete` : the discrete variable.
* `ex::ModelType` : the value of the delay; may be an object or Unknown.

### Returns

* `Void`

### Examples

```julia
function test_BoolEventHook()
    n1 = Voltage("n1")
    sig2 = Discrete(true)
    sig = Discrete(false)
    Sims.addhook!(sig, 
             reinit(sig2, false))
    g = 0.0
    Equation[
        SineVoltage(n1, g, ifelse(sig2, 10.0, 5.0), ifelse(sig, 1.0, 2.0)) 
        BoolEvent(sig, MTime - 0.25)  
        Resistor(n1, g, 1e-3)
    ]
end
y = sim(test_BoolEventHook())
```

**source:**
[Sims/src/main.jl:991](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L991)
## check
Prints the number of equations and the number of unknowns.

```julia
name(x)
```

### Arguments

* `x` : a Model, EquationSet, or Sim

### Returns

* `::Void`

**source:**
[Sims/src/utils.jl:22](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/utils.jl#L22)
## compatible_values
A helper functions to return the base value from an Unknown to use
when creating other Unknowns. It is especially useful for taking two
model arguments and creating a new Unknown compatible with both
arguments.

```julia
compatible_values(x,y)
compatible_values(x)
```

It's still somewhat broken but works for basic cases. No type
promotion is currently done.

### Arguments

* `x`, `y` : objects or Unknowns

### Returns

The returned object has zeros of type and length common to both `x`
and `y`.

### Examples

```julia
a = Unknown(45.0 + 10im)
x = Unknown(compatible_values(a))   # Initialized to 0.0 + 0.0im.
a = Unknown()
b = Unknown([1., 0.])
y = Unknown(compatible_values(a,b)) # Initialized to [0.0, 0.0].
```

**source:**
[Sims/src/main.jl:632](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L632)
## create_sim
`create_sim` converts a model to a Sim.

```julia
create_sim(m::Model)
create_sim(eq::EquationSet)
```

### Arguments

* `m::Model` : a Model
* `eq::EquationSet` : a flattened model

### Returns

* `::Sim` : a simulation object

**source:**
[Sims/src/simcreation.jl:97](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/simcreation.jl#L97)
## create_simstate
`create_simstate` converts a Sim is the main conversion function that
returns a SimState, a simulation object with state history.

```julia
create_simstate(m::Model)
create_simstate(eq::EquationSet)
create_simstate(sm::Sim)
```

### Arguments

* `m::Model` : a Model
* `eq::EquationSet` : a flattened model
* `sm::Sim` : a simulation object

### Returns

* `::Sim` : a simulation object

**source:**
[Sims/src/simcreation.jl:141](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/simcreation.jl#L141)
## delay
A Model specifying a delay to an Unknown.

Internally, Unknowns that are delayed store past history. This is
interpolated as needed to find the delayed quantity.

```julia
delay(x::Unknown, val)
```

### Arguments

* `x::Unknown` : the quantity to be delayed.
* `val` : the value of the delay; may be an object or Unknown.

### Returns

* `::MExpr` : a delayed Unknown


**source:**
[Sims/src/main.jl:870](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L870)
## der
Represents the derivative of an Unknown.

```julia
der(x::Unknown)
der(x::Unknown, val)
```

### Arguments

* `x::Unknown` : the Unknown variable
* `val` : initial value, defaults to 0.0

### Examples

```julia
a = Unknown()
der(a) + 1
```

**source:**
[Sims/src/main.jl:287](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L287)
## elaborate
`elaborate` is the main elaboration function that returns
a flattened model representation that can be used by `sim`.

```julia
elaborate(a::Model)
```

### Arguments

* `a::Model` : the input model

### Returns

* `::EquationSet` : the flattened model

### Details

The main steps in flattening are:

* Replace fixed initial values.
* Flatten models and populate `eq.equations`.
* Pull out InitialEquations and populate `eq.initialequations`.
* Pull out Events and populate `eq.events`.
* Handle StructuralEvents.
* Collect nodes and populate `eq.nodeMap`.
* Strip out MExpr's from expressions.
* Remove empty equations.

There is currently no real symbolic processing (sorting, index
reduction, or any of the other stuff a fancy modeling tool would do).

In EquationSet, `model` contains equations and StructuralEvents. When
a StructuralEvent triggers, the entire model is elaborated again.
The first step is to replace StructuralEvents that have activated
with their new_relation in model. Then, the rest of the EquationSet
is reflattened using `model` as the starting point.

**source:**
[Sims/src/elaboration.jl:69](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/elaboration.jl#L69)
## ifelse
A function allowing if-then-else action for objections and expressions.

Note that when this is used in a model, it does not trigger an
event. You need to use `Event` or `BoolEvent` for that. It is used
often in conjunction with `Event`.

```julia
ifelse(x, y)
ifelse(x, y, z)
```

### Arguments

* `x` : the condition, a Bool or ModelType
* `y` : the value to return when true
* `z` : the value to return when false, defaults to `nothing`

### Returns

* Either `y` or `z`

### Examples

See [DeadZone](../lib/index.html#DeadZone) and
[Limiter](../lib/index.html#Limiter) in the standard library.


**source:**
[Sims/src/main.jl:1203](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1203)
## is_unknown
Is the object an UnknownVariable?

**source:**
[Sims/src/main.jl:238](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L238)
## mexpr
Create MExpr's (model expressions). Analogous to `expr` in Base.

This is also useful for wrapping user-defined functions where
the built-in mechanisms don't work.

```julia
mexpr(head::Symbol, args::ANY...)
```
### Arguments

* `head::Symbol` : the expression head
* `args...` : values and expressions passed to expression
  arguments

### Returns

* `ex::MExpr` : a model expression

### Examples

```julia
a = Unknown()
b = Unknown()
d = a + sin(b)
typeof(d)
myfun(x) = mexpr(:call, :myfun, x)
```

**source:**
[Sims/src/main.jl:347](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L347)
## name
The name of an UnknownVariable.

```julia
name(a::UnknownVariable)
```

### Arguments

* `x::UnknownVariable`

### Returns

* `s::String` : either the label of the Unknown or if that's blank,
  the symbol name of the Unknown.

### Examples

```julia
a = Unknown("var1")
name(a)
```

**source:**
[Sims/src/main.jl:592](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L592)
## pre
The value of a Discrete variable `x` prior to an event.

See also [Event](#Event).

```julia
pre(x::DiscreteVar)
```

### Arguments

* `x::Discrete`

### Returns

* A value stored just prior to an event.


**source:**
[Sims/src/main.jl:1017](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1017)
## reinit
`reinit` is used in Event responses to redefine variables. 

```julia
reinit(x::DiscreteVar, y)
```

### Arguments

* `x::UnknownVariable` : the object to be reinitialized.
* `y` : value for redefinition.

### Returns

* A value stored just prior to an event.

### Examples

Here is the definition of Step in the standard library:

```julia
function Step(y::Signal, 
              height = 1.0,
              offset = 0.0, 
              startTime = 0.0)
    ymag = Discrete(offset)
    @equations begin
        y = ymag  
        Event(MTime - startTime,
              Equation[reinit(ymag, offset + height)],   # positive crossing
              Equation[reinit(ymag, offset)])            # negative crossing
    end
end
```

See also [IdealThyristor](../lib/index.html#IdealThyristor) in the standard library.


**source:**
[Sims/src/main.jl:1111](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1111)
## value
The value of an object or UnknownVariable.

```julia
value(x)
```

### Arguments

* `x` : an object

### Returns

For standard Julia objects, `value(x)` returns x. For Unknowns and
other ModelTypes, returns the current value of the object. `value`
evaluates immediately, so don't expect to use this in model
expressions, except to grab an immediate value.

### Examples

```julia
v = Voltage(value(n1) - value(n2))
```

**source:**
[Sims/src/main.jl:556](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L556)
## DefaultUnknown
The default UnknownCategory.

**source:**
[Sims/src/main.jl:145](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L145)
## DerUnknown
An UnknownVariable representing the derivitive of an Unknown, normally
created with `der(x)`.

### Arguments

* `x::Unknown` : the Unknown variable
* `val` : initial value, defaults to 0.0

### Examples

```julia
a = Unknown()
der(a) + 1
typeof(der(a))
```

**source:**
[Sims/src/main.jl:257](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L257)
## Discrete
Discrete is a type for discrete variables. These are only changed
during events. They are not used by the integrator. Because they are
not used by the integrator, almost any type can be used as a discrete
variable.

```julia
Discrete()
Discrete(x)
Discrete(s::Symbol, label::String)
Discrete(x, label::String)
Discrete(label::String)
Discrete(s::Symbol, x)
Discrete(s::Symbol, x, label::String)
```

### Arguments

* `s::Symbol` : identification symbol, defaults to `gensym()`
* `value` : initial value and type information, defaults to 0.0
* `label::String` : labeling string, defaults to ""

### Details

Discrete variables are currently quite limited. You cannot have
systems of equations where the values of Discrete variables propagates
easily. A crude mechanism for some chaining is provided by
`addhook!`. It would be nice to have data flow support (reactive
programming). The package
[Reactive.jl](https://github.com/JuliaLang/Reactive.jl) may help here.


**source:**
[Sims/src/main.jl:914](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L914)
## DiscreteVar
A helper type used inside of the residual function.

**source:**
[Sims/src/main.jl:947](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L947)
## EquationSet
A representation of a flattened model, normally created with
`elaborate(model)`. `sim` uses an elaborated model for simulations.

Contains the hierarchical equations, flattened equations, flattened
initial equations, events, event response functions, and a map of
Unknown nodes.

**source:**
[Sims/src/elaboration.jl:20](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/elaboration.jl#L20)
## Event
Event is the main type used for hybrid modeling. It contains a
condition for root finding and model expressions to process after
positive and negative root crossings are detected.

See also [BoolEvent](#BoolEvent).

```julia
Event(condition::ModelType, pos_response, neg_response)
```

### Arguments

* `condition::ModelType` : an expression used for the event detection.
* `pos_response` : an expression indicating what to do when the
  condition crosses zero positively. May be Model or MExpr.
* `neg_response::Model` : an expression indicating what to do when the
  condition crosses zero in the negative direction. Defaults to
  Equation[].

### Examples

See [IdealThyristor](../lib/index.html#IdealThyristor) in the standard library.


**source:**
[Sims/src/main.jl:1045](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1045)
## InitialEquation
A ModelType describing initial equations. Current support is limited
and may be broken. There are no tests. The idea is that the equations
provided will only be used during the initial solution.

```julia
InitialEquation(egs)
```

### Arguments

* `eqs::Array{Equation}` : a vector of equations, each to be equated
  to zero during the initial equation solution.


**source:**
[Sims/src/main.jl:788](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L788)
## LeftVar
A helper type needed to mark unknowns as left-side variables in
assignments during event responses.

**source:**
[Sims/src/main.jl:1069](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1069)
## MExpr
Represents expressions used in models.

```julia
MExpr(ex::Expr)
```

### Arguments

* `ex::Expr` : an expression

### Examples

```julia
a = Unknown()
b = Unknown()
d = a + sin(b)
typeof(d)
```

**source:**
[Sims/src/main.jl:314](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L314)
## ModelType
The main overall abstract type in Sims.

**source:**
[Sims/src/main.jl:129](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L129)
## Parameter{T<:UnknownCategory}
Represents an Unknown that stays constant through a simulation. Useful
for passing in at the top level.

```julia
Parameter(s::Symbol, value)
Parameter(value)
Parameter(s::Symbol, label::String)
Parameter(value, label::String)
```

### Arguments

* `s::Symbol` : identification symbol, defaults to `gensym()`
* `value` : initial value and type information, defaults to 0.0
* `label::String` : labeling string, defaults to ""


**source:**
[Sims/src/main.jl:368](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L368)
## PassedUnknown
An UnknownVariable used as a helper for the `delay` function.  It is
an identity unknown, but it doesn't replace with a reference to the y
array.

PassedUnknown(ref::UnknownVariable)

### Arguments

* `ref::UnknownVariable` : an Unknown

**source:**
[Sims/src/main.jl:814](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L814)
## RefBranch
A special ModelType to specify branch flows into nodes. When the model
is flattened, equations are created to zero out branch flows into
nodes. 

See also [Branch](#Branch).

```julia
RefBranch(n, i) 
```

### Arguments

* `n` : the reference node.
* `i` : the flow variable that goes with this node.

### References

This nodal description is based on work by [David
Broman](http://web.ict.kth.se/~dbro/). See the following:

* http://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf
* http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
* https://github.com/david-broman/modelyze

[Modelyze](https://github.com/david-broman/modelyze) has both
`RefBranch` and `Branch`.

### Examples

Here is an example of RefBranch used in the definition of a
HeatCapacitor in the standard library. `hp` is the reference node (a
HeatPort aka Temperature), and `Q_flow` is the flow variable.

```julia
function HeatCapacitor(hp::HeatPort, C::Signal)
    Q_flow = HeatFlow(compatible_values(hp))
    @equations begin
        RefBranch(hp, Q_flow)
        C .* der(hp) = Q_flow
    end
end
```

Here is the definition of SignalCurrent from the standard library a
model that injects current (a flow variable) between two nodes:

```julia
function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  
    @equations begin
        RefBranch(n1, I) 
        RefBranch(n2, -I) 
    end
end
```

**source:**
[Sims/src/main.jl:706](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L706)
## RefDiscrete
A helper type for Discretes used in Arrays.

**source:**
[Sims/src/main.jl:938](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L938)
## RefUnknown{T<:UnknownCategory}
An UnknownVariable used to allow Arrays as Unknowns. Normally created
with `getindex`. Defined methods include:

* getindex
* length
* size
* hcat
* vcat

**source:**
[Sims/src/main.jl:521](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L521)
## Sim
A type for holding several simulation objects needed for simulation,
normally created with `create_sim(eqs)`. 

**source:**
[Sims/src/simcreation.jl:42](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/simcreation.jl#L42)
## SimFunctions
The set of functions used in the DAE solution. Includes an initial set
of equations, a residual function, and several functions for detecting
and responding to events.

All functions take (t,y,yp) as arguments. {TODO: is this still right?}

**source:**
[Sims/src/simcreation.jl:24](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/simcreation.jl#L24)
## SimResult
A type holding simulation results from `sim`, `dasslsim`, or
`sunsim`. Includes a matrix of results and a vector of column names.

**source:**
[Sims/src/simcreation.jl:427](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/simcreation.jl#L427)
## SimState
The top level type for holding all simulation objects needed for
simulation, including a Sim. Normally created with
`create_simstate(sim)`.

**source:**
[Sims/src/simcreation.jl:70](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/simcreation.jl#L70)
## StructuralEvent
StructuralEvent defines a type for elements that change the structure
of the model. An event is created where the condition crosses zero.
When the event is triggered, the model is re-flattened after replacing
`default` with `new_relation` in the model.

```julia
StructuralEvent(condition::MExpr, default, new_relation::Function)
```

### Arguments

* `condition::MExpr` : an expression that will trigger the event at a
  zero crossing
* `default` : the default Model used
* `new_relation` : a function that returns a model that will replace
  the default model when the condition triggers the event.

### Examples

Here is an example from examples/breaking_pendulum.jl:

```julia
function FreeFall(x,y,vx,vy)
    @equations begin
        der(x) = vx
        der(y) = vy
        der(vx) = 0.0
        der(vy) = -9.81
    end
end

function Pendulum(x,y,vx,vy)
    len = sqrt(x.value^2 + y.value^2)
    phi0 = atan2(x.value, -y.value) 
    phi = Unknown(phi0)
    phid = Unknown()
    @equations begin
        der(phi) = phid
        der(x) = vx
        der(y) = vy
        x = len * sin(phi)
        y = -len * cos(phi)
        der(phid) = -9.81 / len * sin(phi)
    end
end

function BreakingPendulum()
    x = Unknown(cos(pi/4), "x")
    y = Unknown(-cos(pi/4), "y")
    vx = Unknown()
    vy = Unknown()
    Equation[
        StructuralEvent(MTime - 5.0,     # when time hits 5 sec, switch to FreeFall
            Pendulum(x,y,vx,vy),
            () -> FreeFall(x,y,vx,vy))
    ]
end

p_y = sim(BreakingPendulum(), 6.0)  
```

**source:**
[Sims/src/main.jl:1282](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1282)
## UnknownCategory
Categories of Unknown types; used to subtype Unknowns.

**source:**
[Sims/src/main.jl:140](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L140)
## UnknownVariable
An abstract type for variables to be solved. Examples include Unknown,
DerUnknown, and Parameter.

**source:**
[Sims/src/main.jl:135](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L135)
## Unknown{T<:UnknownCategory}
An Unknown represents variables to be solved in Sims. An `Unknown` is
a symbolic type. When used in Julia expressions, Unknowns combine into
`MExpr`s which are symbolic representations of equations.

Expressions (of type MExpr) are built up based on Unknown's. Unknown
is a symbol with a uniquely generated symbol name. If you have

Unknowns can contain Float64, Complex, and Array{Float64}
values. Additionally, Unknowns can be extended to support other types.
All Unknown types currently map to positions in an Array{Float64}.

In addition to a value, Unknowns can carry additional metadata,
including an identification symbol and a label. In the future, unit
information may be added.

Unknowns can also have type parameters. For example, `Voltage` is
defined as `Unknown{UVoltage}` in the standard library. The `UVoltage`
type parameter is a marker to distinguish those Unknown from
others. Users can add their own Unknown types. Different Unknown types
makes it easier to dispatch on model arguments.

```julia
Unknown(s::Symbol, x, label::String, fixed::Bool)
Unknown()
Unknown(x)
Unknown(s::Symbol, label::String)
Unknown(x, label::String)
Unknown(label::String)
Unknown(s::Symbol, x, fixed::Bool)
Unknown(s::Symbol, x)
Unknown{T}(s::Symbol, x, label::String, fixed::Bool)
Unknown{T}()
Unknown{T}(x)
Unknown{T}(s::Symbol, label::String)
Unknown{T}(x, label::String)
Unknown{T}(label::String)
Unknown{T}(s::Symbol, x, fixed::Bool)
Unknown{T}(s::Symbol, x)
```

### Arguments

* `s::Symbol` : identification symbol, defaults to `gensym()`
* `x` : initial value and type information, defaults to 0.0
* `label::String` : labeling string, defaults to ""

### Examples

```julia
  a = 4
  b = Unknown(3.0, "len")
  a * b + b^2
```

**source:**
[Sims/src/main.jl:203](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L203)
## @equations
A helper to make writing Models a little easier. It allows the use of
`=` in model equations.

```julia
@equations begin
    ...
end
```

### Arguments

* `eq` : the model equations, normally in a `begin` - `end` block.

### Returns

* `::Array{Equation}`

### Examples

The following are both equivalent:

```julia
function Vanderpol1()
    y = Unknown(1.0, "y")
    x = Unknown("x")
    Equation[
        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed
        der(y) - x
    ]
end
function Vanderpol2()
    y = Unknown(1.0, "y") 
    x = Unknown("x")
    @equations begin
        der(x, -1.0) = (1 - y^2) * x - y
        der(y) = x
    end
end
```

**source:**
[Sims/src/main.jl:1376](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L1376)
## @unknown
A macro to ease entry of many unknowns.

```julia
@unknown a1 a2 a3 ...
```

### Arguments

* `a` : various representations of Unknowns, several specification
  options include:
  * symbol: equivalent to `symbol = Unknown(symbol)`
  * symbol(val): equivalent to `symbol = Unknown(symbol, val)`

# Effects

Creates one or more Unknowns

* A Gadfly object

**source:**
[Sims/src/utils.jl:222](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/utils.jl#L222)
## Equation
Equations are used in Models. Right now, Equation is defined as `Any`,
but that may change.  Normally, Equations are of type Unknown,
DerUnknown, MExpr, or Array{Equation} (for nesting models).

### Examples

Models return Arrays of Equations. Here is an example:

```julia
function Vanderpol()
    y = Unknown(1.0, "y")
    x = Unknown("x")
    Equation[
        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed
        der(y) - x
    ]
end
dump( Vanderpol() )
```

**source:**
[Sims/src/main.jl:482](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L482)
## MTime
The model time - a special unknown variable.

**source:**
[Sims/src/main.jl:647](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L647)
## Model
Represents a vector of Equations. For now, `Equation` equals `Any`, but
in the future, it may only include ModelType's.

Models return Arrays of Equations. 

### Examples

```julia
function Vanderpol()
    y = Unknown(1.0, "y")
    x = Unknown("x")
    Equation[
        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed
        der(y) - x
    ]
end
dump( Vanderpol() )
x = sim(Vanderpol(), 50.0)
```

**source:**
[Sims/src/main.jl:506](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/main.jl#L506)
## sim
`sim` is the name of the default solver used to simulate Sims models
and also shows the generic simulation API for available solvers
(currently `dasslsim` and `sunsim`). The default solver is currently
`dasslsim`.

`sim` has many method definitions to accomodate solutions based on
intermediate model representations. Also, both positional and keyword
arguments are supported (use one or the other after the first
argument).

```julia
sim(m::Model, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4)
sim(m::Model; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4)
sim(m::Sim, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4)
sim(m::Sim; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4)
sim(m::SimState, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4)
sim(m::SimState; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4)
```

### Arguments

* `m::Model` : a Model
* `sm::Sim` : a simulation object
* `ss::SimState` : a simulation object
* `tstop::Float64` : the simulation stopping time [secs], default = 1.0
* `Nsteps::Int` : the number of simulation steps, default = 500
* `reltol::Float64` : the relative tolerance, default = 1e-4
* `abstol::Float64` : the absolute tolerance, default = 1e-4

### Returns

* `::SimResult` : the simulation result

A number of optional packages can be used with results, including:

* Winston - plotting: `wplot(y::SimResult)`
* Gaston - plotting: `gplot(y::SimResult)` 
* DataFrames - conversion to a DataFrame: `convert(DataFrame, y::SimResult)` 
* Gadfly - plotting: `plot(y::SimResult, ...)` 

For each of these, the package must be installed, and the package
pulled in with `require` or `using`.

### Details

The main steps in converting to a model and doing a simulation are:

```julia
eqs::EquationSet = elaborate(m::Model)   # flatten the model
sm::Sim = create_sim(eqs::EquationSet)   # prepare for simulation
sm::SimState = create_simstate(sm::Sim)  # prepare for simulation II
y::SimResult = sim(ss::SimState)         # simulate
```

The following are equivalent:

```julia
y = sim(create_simstate(create_sim(elaborate(m))))
y = sim(m)
```

### Example

```julia
using Sims
function Vanderpol()
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    @equations begin
        # The -1.0 in der(x, -1.0) is the initial value for the derivative 
        der(x, -1.0) = (1 - y^2) * x - y 
        der(y) = x
    end
end

v = Vanderpol()       # returns the hierarchical model
y = sunsim(v, 50.0)
using Winston
wplot(y)
```

**source:**
[Sims/src/Sims.jl:138](https://github.com/tshort/Sims.jl/tree/4daa82c7bb8aca8f9ca655abe46e9f4028f334c6/src/Sims.jl#L138)

