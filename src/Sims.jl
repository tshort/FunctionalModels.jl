
module Sims

using ModelingToolkit: Equation, @parameters, @variables, ModelingToolkit, Num
import Symbolics
import IfElse
import OrdinaryDiffEq

export Unknown, Branch, RefBranch, Event, BoolEvent, Variable, Parameter, system, t, D, der, default_value, compatible_values, sim, @comment


# Documentation helper
macro comment(str="")
    name = gensym("comment")
    :( $name = :DOCCOMMENT )
end


##############################################
## Non-causal time-domain modeling in Julia ##
##############################################

# Tom Short, tshort@epri.com
#
#
# Copyright (c) 2012-2021, Electric Power Research Institute 
# BSD license - see the LICENSE file
 
# 
# This file is an experiment in doing non-causal modeling in Julia.
# The idea behind non-causal modeling is that the user develops models
# based on components which are described by a set of equations. A
# tool can then transform the equations and solve the differential
# algebraic equations. Non-causal models tend to match their physical
# counterparts in terms of their specification and implementation.
#
# Causal modeling is where all signals have an input and an output,
# and the flow of information is clear. Simulink is the
# highest-profile example.
# 
# The highest profile noncausal modeling tools are in the Modelica
# (www.modelica.org) family. The MathWorks also has Simscape that uses
# Matlab notation. Modelica is an object-oriented, open language with
# multiple implementations. It is a large, complex, powerful language
# with an extensive standard library of components.
#
# This implementation follows the work of David Broman and his MKL
# simulator and the work of George Giorgidze and Henrik Nilsson and
# their functional hybrid modeling.
#
# A nodal formulation is used based on David's work. His thesis
# documents this nicely:
# 
#   David Broman. Meta-Languages and Semantics for Equation-Based
#   Modeling and Simulation. PhD thesis, Thesis No 1333. Department of
#   Computer and Information Science, Link�ping University, Sweden,
#   2010.
#   http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf
#
# Here is David's code and home page:
# 
#   http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
#   http://www.ida.liu.se/~davbr/
#   
# Modeling of dynamically varying systems is handled similarly to
# functional hybrid modelling (FHM), specifically the Hydra
# implementation by George. See here for links:
# 
#   https://github.com/giorgidze/Hydra
#   http://db.inf.uni-tuebingen.de/team/giorgidze
#   http://www.cs.nott.ac.uk/~nhn/
# 
# FHM is also a functional approach. Hydra is implemented as a domain
# specific language embedded in Haskell. Their implementation handles
# dynamically changing systems with JIT-compiled code from an
# amazingly small amount of code.
# 
# As stated, this file implements something like David's approach. A
# model constructor returns a list of equations. Models are made of
# models, so this builds up a hierarchical structure of equations that
# then need to be flattened. David's approach is nodal; nodes are
# passed in as parameters to models to perform connections between
# devices.
#
# Downsides of this approach:
#   - No connect-like capability. Must be nodal.
#   - Tougher to do model introspection.
#   - Tougher to map to a GUI. This is probably true with most
#     functional approaches. Tougher to add annotations.
#

"""
The API for building models with Sims. Includes basic types, models,
and functions.
"""
@comment

@parameters t
""" Independent variable """
t

""" Differential(t) """
const D = ModelingToolkit.Differential(t)
""" Differential(t) """
const der = D

struct IdCtx end
struct NameCtx end

"""
```julia
Unknown(value = 0.0; name = :u) 
```

`Unknown` is a helper to create a variable with a default value.
The default value determines the type and shape of the result.
It also adds metadata to variables so that variable names don't clash.
The viewable variable name is based on a `gensym`.
`name` is stored as metadata, and when equations are flattened
with `system`, variables are renamed to include subsystem names
and variable base name. 

For example, `Unknown(:v)` may show as `var"##v#1057"(t)`, but
after flattening, it will show as something like `ss₊c1₊v(t)` 
(`ss` and `c1` are subsystems).

"""
function Unknown(value = 0.0; name = :u) 
    s = gensym(name)
    if length(value) > 1    # array
        map(Iterators.product(1:length(value))) do ind
            x = Symbolics.setmetadata(ModelingToolkit.Num(ModelingToolkit.Sym{(ModelingToolkit.FnType){NTuple{1, Any}, Real}}(s, ind...))(Symbolics.value(t)), 
                                  Symbolics.VariableDefaultValue, value[ind...])
            x = Symbolics.setmetadata(x, NameCtx, name)
            Symbolics.setmetadata(x, IdCtx, gensym())
        end
    else
        x = Symbolics.setmetadata(ModelingToolkit.Num(ModelingToolkit.Variable{ModelingToolkit.FnType{Tuple{Any},Real}}(s))(t), 
                              Symbolics.VariableDefaultValue, value)
        x = Symbolics.setmetadata(x, NameCtx, name)
        Symbolics.setmetadata(x, IdCtx, gensym())
    end
end

function Variable(value = 0.0; name = :d) 
    s = gensym(name)
    x = Symbolics.setdefaultval((Symbolics.Sym){typeof(value)}(s), value)
    x = Symbolics.setmetadata(x, NameCtx, name)
    Symbolics.wrap(Symbolics.setmetadata(x, IdCtx, gensym()))
end

"""
```julia
Parameter(value = 0.0; name) 
```

`Parameter` is a helper to create a parameter with default values.
The default value determines the type and shape of the result.
It also adds metadata to variables so that variable names don't clash.
The viewable variable name is based on a `gensym`.
`name` is stored as metadata, and when equations are flattened
with `system`, variables are renamed to include subsystem names
and the variable base name. 

For example, `Parameter(:R)` may show as `var"##R#1057"`, but
after flattening, it will show as something like `ss₊r1₊R` 
(`ss` and `r1` are subsystems).

"""
function Parameter(value = 0.0; name = :u) 
    s = gensym(name)
    x = Symbolics.setdefaultval((Symbolics.Sym){typeof(value)}(s), value)
    x = Symbolics.setmetadata(x, Symbolics.VariableSource, (:parameters, name))
    x = Symbolics.setmetadata(x, NameCtx, name)
    ModelingToolkit.toparam(Symbolics.wrap(Symbolics.setmetadata(x, IdCtx, gensym())))
end

"""
A special ModelType to specify branch flows into nodes. When the model
is flattened, equations are created to zero out branch flows into
nodes. 

See also [Branch](#branch).

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
    [
        RefBranch(hp, Q_flow)
        der(hp) ~ Q_flow ./ C
    ]
end
```

Here is the definition of SignalCurrent from the standard library a
model that injects current (a flow variable) between two nodes:

```julia
function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  
    [
        RefBranch(n1, I) 
        RefBranch(n2, -I) 
    ]
end
```
"""
struct RefBranch
    n     # This is the reference node.
    i     # This is the flow variable that goes with this reference.
end


"""
A helper Model to connect a branch between two different nodes and
specify potential between nodes and the flow between nodes.

See also [RefBranch](#refbranch).

```julia
Branch(n1, n2, v, i)
```

### Arguments

* `n1` : the positive reference node.
* `n2` : the negative reference node.
* `v` : the potential variable between nodes.
* `i` : the flow variable between nodes.

### Returns

* The model, consisting of a RefBranch entry for
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
    [
        Branch(n1, n2, v, i)
        v ~ R .* i
    ]
end
```
"""
function Branch(n1, n2, v, i)
    [
        RefBranch(n1, i)
        RefBranch(n2, -i)
        v ~ n1 - n2
    ]
end


########################################
## Elaboration / flattening           ##
########################################

#
# This converts a hierarchical model into a flat set of equations.
# 


"""
`system` is the main elaboration/flattening function that returns
an `ODESystem`.

```julia
system(a)
```

### Arguments

* `a` : the input model containing a nested vector of equations

### Optional/Keyword Arguments

* `simplify = true` : whether `structural_simplify` is used to simplify results 

### Returns

* `::ODESystem` : the flattened model

"""
function system(a; simplify = true, name = :sims_system)
    ctx = flatten(a)
    if length(ctx.events) > 0
        sys = ModelingToolkit.ODESystem(ctx.eq, t; continuous_events = ctx.events, name = name)
    else
        sys = ModelingToolkit.ODESystem(ctx.eq, t; name = name)
    end
    if simplify
        return ModelingToolkit.structural_simplify(sys)
    else
        return sys
    end
end

function flatten(a)
    ctx = EqCtx(Equation[], Event[], Dict(), Dict(), Dict())
    sweep_vars(a, (), ctx)
    prep_variables(ctx)
    elaborate_unit!(a, ctx)
    # Add in equations for each node to sum flows to zero:
    for (key, nodeset) in ctx.nodemap
        push!(ctx.eq, 0 ~ nodeset)
    end
    return ctx
end

struct Event
    condition::Equation
    affect::Union{Equation, Nothing}
end
Event(condition, affect, affect_neg) = Event(condition, affect.lhs ~ IfElse.ifelse(condition.lhs > condition.rhs, affect.rhs, affect_neg.rhs))
Event(condition) = Event(condition, nothing)
BoolEvent(d, condition) = Event(condition, d ~ true, d ~ false)

struct EqCtx
    eq::Vector{Equation}
    events::Vector{Equation}
    nodemap::Dict
    varmap::IdDict
    newvars::IdDict
end

# Return the name stored in metadata with subscript indices included (if needed).
function basevarname(v::ModelingToolkit.Term)
    name = v.f.name
    return Symbol(ModelingToolkit.getmetadata(v, NameCtx, name),
                  (x for x in string(name) if x in ('₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'))...)
end
function basevarname(v::ModelingToolkit.Sym)
    name = v.name
    return Symbol(ModelingToolkit.getmetadata(v, NameCtx, name),
                  (x for x in string(name) if x in ('₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'))...)
end

# Prepare the newvars map and fix up duplicate names.
function prep_variables(ctx)
    for (k, v) in ctx.varmap
        kval = ModelingToolkit.value(k)
        ctx.newvars[k] = Num(ModelingToolkit.rename(kval, Symbol(join((v..., basevarname(kval)), "ₓ"))))
    end
    vars = collect(keys(ctx.newvars))
    newvars = collect(values(ctx.newvars))
    for i in 1:length(vars)-1
        for j in i+1:length(vars)
            name = ModelingToolkit.tosymbol(newvars[j])
            if ModelingToolkit.tosymbol(newvars[i]) == name
                ctx.newvars[vars[j]] = newvars[j] = Num(ModelingToolkit.rename(ModelingToolkit.value(newvars[j]), gensym(ModelingToolkit.value(newvars[j]).f.name)))
            end
        end
    end
    nothing
end

_nameof(a) = nameof(a)
_nameof(a::ModelingToolkit.Term) = nameof(a.f)

function sweep_vars(a::Union{ModelingToolkit.Sym,ModelingToolkit.Term}, names, ctx::EqCtx)
# function sweep_vars(a::ModelingToolkit.Term, names, ctx::EqCtx)
    _nameof(a) == :t && return
    if !haskey(ctx.varmap, a)
        ctx.varmap[a] = names
    else 
        original = ctx.varmap[a]
        if original != names
            ctx.varmap[a] = common_root(original, names)
        end
    end
    nothing
end
sweep_vars(a, names, ctx::EqCtx) = nothing
sweep_vars(a::Num, names, ctx::EqCtx) = sweep_vars(ModelingToolkit.value(a), names, ctx)
sweep_vars(a::Pair, names, ctx::EqCtx) = sweep_vars(a[2], (names..., a[1]), ctx)
sweep_vars(a::Vector, names, ctx::EqCtx) = map(x -> sweep_vars(x, names, ctx), a)
function sweep_vars(a::RefBranch, names, ctx::EqCtx)
    sweep_vars(a.n, names, ctx)
    sweep_vars(a.i, names, ctx)
end
function sweep_vars(a::Equation, names, ctx::EqCtx)
    sweep_vars(ModelingToolkit.get_variables(a.lhs), names, ctx)
    sweep_vars(ModelingToolkit.get_variables(a.rhs), names, ctx)
end

function common_root(a, b)
    rng = 1:min(length(a), length(b))
    for i in rng
        if a[i] !== b[i]
            return a[1:i-1]
        end
    end
    return a[rng]
end




#
# elaborate_unit flattens the set of equations while building up
# events, event responses, and a Dict of nodes.
#
elaborate_unit!(a::Any, ctx::EqCtx) = nothing # The default is to ignore undefined types.
function elaborate_unit!(a::Equation, ctx::EqCtx)
    push!(ctx.eq, ModelingToolkit.substitute(a, ctx.newvars))
end
function elaborate_unit!(a::Vector, ctx::EqCtx)
    map(x -> elaborate_unit!(x, ctx), a)
end
function elaborate_unit!(a::Pair, ctx::EqCtx)
    map(x -> elaborate_unit!(x, ctx), a)
end
function elaborate_unit!(a::Event, ctx::EqCtx)
    cond = ModelingToolkit.substitute(a.condition, ctx.newvars)
    push!(ctx.events, a.affect == nothing ? cond : cond => ModelingToolkit.substitute(a.affect, ctx.newvars))
end

function elaborate_unit!(b::RefBranch, ctx::EqCtx)
    if b.n isa ModelingToolkit.Num
        ctx.nodemap[b.n] = get(ctx.nodemap, b.n, 0.0) + ModelingToolkit.substitute(ModelingToolkit.value(b.i), ctx.newvars)
    end
end


"""
The default or starting value of a variable.

```julia
default_value(x) 
```

### Arguments

* `x` : the reference variable or numeric value.
"""
default_value(x::ModelingToolkit.Num) = default_value(x.val)
default_value(x::ModelingToolkit.Term) = Symbolics.getmetadata(x, Symbolics.VariableDefaultValue, 0.0)
default_value(x::Array) = default_value.(x)
default_value(x) = x


"""
A helper functions to return the base value from a variable to use
when creating other variables. It is especially useful for taking two
model arguments and creating a new variable compatible with both
arguments.

```julia
compatible_values(x,y)
compatible_values(x)
```

It's still somewhat broken but works for basic cases. No type
promotion is currently done.

### Arguments

* `x`, `y` : objects or variables

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
"""
compatible_values(x,y) = length(x) > length(y) ? zero(default_value(x)) : zero(default_value(y))
compatible_values(x) = zero(default_value(x))
# This should work for real and complex valued unknowns, including
# arrays. For something more complicated, it may not.

function sim(x, t, solver = OrdinaryDiffEq.Rosenbrock23, problem = OrdinaryDiffEq.ODEProblem)
    sys = system(x)
    prob = problem(sys, Dict(k => 0.0 for k in ModelingToolkit.states(sys)), (0, t))
    ModelingToolkit.solve(prob, solver())
end
sim(x::Function, t, solver = OrdinaryDiffEq.Rosenbrock23, problem = OrdinaryDiffEq.ODEProblem) = sim(x(), t, solver, problem)


# load standard Sims libraries

include("../lib/Lib.jl")

# load standard Sims examples

include("../examples/Examples.jl")


end # module Sims


