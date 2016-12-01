
##############################################
## Non-causal time-domain modeling in Julia ##
##############################################

# Tom Short, tshort@epri.com
#
#
# Copyright (c) 2012, Electric Power Research Institute 
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
# What can it do:
#   - Index-1 DAE's using the DASSL solver
#   - Arrays of unknown variables
#   - Complex valued unknowns
#   - Hybrid modeling
#   - Discrete systems
#   - Structurally variable systems
#   
# What's missing:
#   - Initial equations (some infrastructure in place)
#   - Causal relationships or input/outputs (?)
#   - Metadata like variable name, units, and annotations (hard?)
#   - Symbolic processing like index reduction
#   - Error checking
#   - Tests
#
# Downsides of this approach:
#   - No connect-like capability. Must be nodal.
#   - Tougher to do model introspection.
#   - Tougher to map to a GUI. This is probably true with most
#     functional approaches. Tougher to add annotations.
#
# For an implementation point of view, Julia works well for this.
# 

@comment """
# Building models

The API for building models with Sims. Includes basic types, models,
and functions.
"""

sim_verbose = 1
function sim_info(msgs, i)
    if i <= sim_verbose
        println(msgs)
    end
end

"""
Control the verbosity of output.

```julia
verbosity(i)
```

### Arguments

* `i` : Int indicator with the following meanings:
  * `i == 0` : don't print information
  * `i == 1` : minimal info
  * `i == 2` : all info, including events

More options may be added in the future. This function is not
exported, so you must qualify it as `Sims.verbosity(0)`.

"""
function verbosity(i)
    global sim_verbose = i   
end

########################################
## Type definitions                   ##
########################################

#
# This includes a few symbolic types of abstracted type ModelType.
# This includes symbols, expressions, and other objects that reduce to
# expressions.
#
# Expressions (of type MExpr) are built up based on Unknown's. Unknown
# is a symbol with a uniquely generated symbol name. If you have
#   a = 1
#   b = Unknown()
#   a * b + b^2
# evaluation produces the following:
#   MExpr(+(*(1,##1029),*(##1029,##1029)))
#   
# This is an expression tree where ##1029 is the symbol name for b.
# 
# The idea is that you can set up a set of hierarchical equations that
# will be later flattened.
#
# Other types or method definitions can be used to assign behavior
# during flattening (like the Branch type) or during instantiation
# (like the der method).
# 

"""
The main overall abstract type in Sims.
"""
abstract ModelType

"""
An abstract type for variables to be solved. Examples include Unknown,
DerUnknown, and Parameter.
"""
abstract UnknownVariable <: ModelType

"""
Categories of Unknown types; used to subtype Unknowns.
"""
abstract UnknownCategory

"""
The default UnknownCategory.
"""
type DefaultUnknown <: UnknownCategory
end

"""
Categories of constraints on Unknowns; used to create positive, negative, etc., constraints.
"""
abstract UnknownConstraint

"""
Indicates no constraint is imposed.
"""
type Normal <: UnknownConstraint
end
"""
Indicates unknowns of this type must be constrained to negative values.
"""
type Negative <: UnknownConstraint
end
"""
Indicates unknowns of this type must be constrained to positive or zero values.
"""
type NonNegative <: UnknownConstraint
end
"""
Indicates unknowns of this type must be constrained to positive values.
"""
type Positive <: UnknownConstraint
end
"""
Indicates unknowns of this type must be constrained to negative or zero values.
"""
type NonPositive <: UnknownConstraint
end

"""
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

Unknowns can also have type parameters. Two parameters are provided:

* `T`: type of unknown; several are defined in Sims.Lib, including
  `UVoltage` and `UAngularVelocity`.

* `C`: contstraint on the unknown; possibilities include `Normal` (the
  default), `Positive`, `NonNegative`, ``Negative`, and `NonPositive`.

As an example, `Voltage` is defined as `Unknown{UVoltage,Normal}` in
the standard library. The `UVoltage` type parameter is a marker to
distinguish those Unknown from others. Users can add their own Unknown
types. Different Unknown types makes it easier to dispatch on model
arguments.

```julia
Unknown(s::Symbol, x, label::AbstractString, fixed::Bool)
Unknown()
Unknown(x)
Unknown(s::Symbol, label::AbstractString)
Unknown(x, label::AbstractString)
Unknown(label::AbstractString)
Unknown(s::Symbol, x, fixed::Bool)
Unknown(s::Symbol, x)
Unknown{T,C}(s::Symbol, x, label::AbstractString, fixed::Bool)
Unknown{T,C}()
Unknown{T,C}(x)
Unknown{T,C}(s::Symbol, label::AbstractString)
Unknown{T,C}(x, label::AbstractString)
Unknown{T,C}(label::AbstractString)
Unknown{T,C}(s::Symbol, x, fixed::Bool)
Unknown{T,C}(s::Symbol, x)
```

### Arguments

* `s::Symbol` : identification symbol, defaults to `gensym()`
* `x` : initial value and type information, defaults to 0.0
* `label::AbstractString` : labeling string, defaults to ""

### Examples

```julia
  a = 4
  b = Unknown(3.0, "len")
  a * b + b^2
```
"""
type Unknown{T<:UnknownCategory,C<:UnknownConstraint} <: UnknownVariable
    sym::Symbol
    value         # holds initial values (and type info)
    label::AbstractString
    fixed::Bool
    save_history::Bool
    t::Array{Any,1}
    x::Array{Any,1}
    Unknown(;value = 0.0, label::AbstractString = "", fixed::Bool = false) =
        new(gensym(), value, label, fixed, false, Float64[], Float64[])
    Unknown(value, label::AbstractString = "", fixed::Bool = false) =
        new(gensym(), value, label, fixed, false, Float64[], Float64[])
    Unknown(label::AbstractString, value = 0.0, fixed::Bool = false) =
        new(gensym(), value, label, fixed, false, Float64[], Float64[])
    Unknown(sym::Symbol, value = 0.0, label::AbstractString = "", fixed::Bool = false) =
        new(sym, value, label, fixed, false, Float64[], Float64[])
end
Unknown(value, label::AbstractString = "", fixed::Bool = false) =
    Unknown{DefaultUnknown,Normal}(value, label, fixed)
Unknown(label::AbstractString, value = 0.0, fixed::Bool = false) =
    Unknown{DefaultUnknown,Normal}(value, label, fixed)
Unknown(;value = 0.0, label::AbstractString = "", fixed::Bool = false) =
    Unknown{DefaultUnknown,Normal}(value, label, fixed)



"""
Is the object an UnknownVariable?
"""
is_unknown(x) = isa(x, UnknownVariable)


"""
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
"""
type DerUnknown <: UnknownVariable
    sym::Symbol
    value        # holds initial values
    fixed::Bool
    parent::Unknown
    # label::AbstractString    # Do we want this? 
end
DerUnknown(u::Unknown) = DerUnknown(u.sym, 0.0, false, u)


"""
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
"""
der(x::Unknown) = DerUnknown(x.sym, compatible_values(x), false, x)
der(x::Unknown, val) = DerUnknown(x.sym, val, true, x)
der(x) = 0.0

show(io::IO, a::UnknownVariable) = print(io::IO, "<<", name(a), ",", value(a), ">>")


"""
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
"""
type MExpr <: ModelType
    ex::Expr
end

"""
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
"""
mexpr(head::Symbol, args::ANY...) = MExpr(Expr(head, args...))



# Set up defaults for operations on ModelType's for many common
# methods.


unary_functions = [:(+), :(-), :(!),
                   :abs, :sign, 
                   :ceil, :floor,
                   :round, :trunc, :exp, :exp2, :expm1, :log, :log10, :log1p,
                   :log2, :sqrt, :gamma, :lgamma, :digamma,
                   :erf, :erfc, 
                   :min, :max, :prod, :sum, :mean, :median, :std,
                   :var, :norm,
                   :diff, 
                   :cumprod, :cumsum, :cumsum_kbn, :cummin, :cummax,
                   :fft,
                   ## :rowmins, :rowmaxs, :rowprods, :rowsums,
                   ## :rowmeans, :rowmedians, :rowstds, :rowvars,
                   ## :rowffts, :rownorms,
                   ## :colmins, :colmaxs, :colprods, :colsums,
                   ## :colmeans, :colmedians, :colstds, :colvars,
                   ## :colffts, :colnorms,
                   :any, :all,
                   :angle,
                   :sin,    :cos,    :tan,    :cot,    :sec,   :csc,
                   :sinh,   :cosh,   :tanh,   :coth,   :sech,  :csch,
                   :asin,   :acos,   :atan,   :acot,   :asec,  :acsc,
                   :acoth,  :asech,  :acsch,  :sinc,   :cosc,
                   :acosh,  :asinh,  :atanh,
                   :transpose, :ctranspose]

binary_functions = [:(.==), :(!=), :(.!=), :isless, 
                    :(.>), :(.>=), :(.<), :(.<=),
                    :(>), :(>=), :(<), :(<=),
                    :(+), :(.+), :(-), :(.-), :(*), :(.*), :(/), :(./),
                    :(.^), :(^), :(div), :(mod), :(fld), :(rem),
                    :(&), :(|), :($),
                    :atan2,
                    :dot, :cor, :cov]

_expr(x) = x
_expr(x::MExpr) = x.ex

macro doimport(name)
  Expr(:toplevel, Expr(:import, :Base, esc(name)))
end

# special case to avoid a warning:
import Base.(^)
(^)(x::ModelType, y::Integer) = mexpr(:call, :(^), _expr(x), y)

for f in binary_functions
    ## @eval import Base.(f)
    # eval(Expr(:toplevel, Expr(:import, :Base, f)))
    @eval (Base.$f)(x::ModelType, y::ModelType) = mexpr(:call, $(Expr(:quote, f)), _expr(x), _expr(y))
    @eval (Base.$f)(x::ModelType, y::Number) = mexpr(:call, $(Expr(:quote, f)), _expr(x), y)
    @eval (Base.$f)(x::ModelType, y::AbstractArray) = mexpr(:call, $(Expr(:quote, f)), _expr(x), y)
    @eval (Base.$f)(x::Number, y::ModelType) = mexpr(:call, $(Expr(:quote, f)), x, _expr(y))
    @eval (Base.$f)(x::AbstractArray, y::ModelType) = mexpr(:call, $(Expr(:quote, f)), x, _expr(y))
end 

for f in unary_functions
    ## @eval import Base.(f)
    eval(Expr(:toplevel, Expr(:import, :Base, f)))

    # Define separate method to get rid of 'ambiguous definition' warnings in base/floatfuncs.jl
    # @eval (Base.$f)(x::ModelType, arg::Integer) = mexpr(:call, $(Expr(:quote, f)), _expr(x), arg)

    @eval (Base.$f)(x::ModelType, args...) = mexpr(:call, $(Expr(:quote, f)), _expr(x), map(_expr, args)...)
end

# Non-Base functions:
for f in [:der, :pre]
    @eval ($f)(x::ModelType, args...) = mexpr(:call, $(Expr(:quote, f)), _expr(x), args...)
end


########################################
## Equation & Mode                    ##
########################################

"""
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
"""
const Equation = Any


"""
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
"""
const Model = Vector{Equation}


# Add array access capability for Unknowns:

"""
An UnknownVariable used to allow Arrays as Unknowns. Normally created
with `getindex`. Defined methods include:

* getindex
* length
* size
* hcat
* vcat
"""
type RefUnknown{T<:UnknownCategory} <: UnknownVariable
    u::Unknown{T}
    idx
end
getindex(x::Unknown, args...) = RefUnknown(x, args)
getindex(x::MExpr, args...) = mexpr(:call, :getindex, args...)
length(u::UnknownVariable) = length(value(u))
size(u::UnknownVariable, i) = size(value(u), i)
hcat(x::ModelType...) = mexpr(:call, :hcat, x...)
vcat(x::ModelType...) = mexpr(:call, :vcat, x...)

"""
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
"""
value(x) = x
value(x::Model) = map(value, x)
value(x::UnknownVariable) = x.value
value(x::RefUnknown) = x.u.value[x.idx...]
value(a::MExpr) = value(a.ex)
value(e::Expr) = eval(Expr(e.head, (isempty(e.args) ? e.args : map(value, e.args))...))

function symname(s::Symbol)
    s = string(s)
    length(s) > 3 && s[1:2] == "##" ? "`" * s[3:end] * "`" : s
end

"""
The name of an UnknownVariable.

```julia
name(a::UnknownVariable)
```

### Arguments

* `x::UnknownVariable`

### Returns

* `s::AbstractString` : either the label of the Unknown or if that's blank,
  the symbol name of the Unknown.

### Examples

```julia
a = Unknown("var1")
name(a)
```
"""
name(a::Unknown) = a.label != "" ? a.label : symname(a.sym)
name(a::DerUnknown) = a.parent.label != "" ? "der("*a.parent.label*")" : "der("*symname(a.parent.sym)*")"
name(a::RefUnknown) = a.u.label != "" ? a.u.label : symname(a.u.sym)

"""
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
"""
compatible_values(x,y) = length(x) > length(y) ? zero(x) : zero(y)
compatible_values(x) = zero(x)
compatible_values(u::UnknownVariable) = value(u) .* 0.0
# The value from the unknown determines the base value returned:
compatible_values(u1::UnknownVariable, u2::UnknownVariable) = length(value(u1)) > length(value(u2)) ? value(u1) .* 0.0 : value(u2) .* 0.0  
compatible_values(u::UnknownVariable, num::Number) = length(value(u)) > length(num) ? value(u) .* 0.0 : num .* 0.0 
compatible_values(num::Number, u::UnknownVariable) = length(value(u)) > length(num) ? value(u) .* 0.0 : num .* 0.0 
# This should work for real and complex valued unknowns, including
# arrays. For something more complicated, it may not.



"""
The model time - a special unknown variable.
"""
const MTime = Unknown{DefaultUnknown,Normal}(:time, 0.0, "", false)


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
"""
type RefBranch <: ModelType
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
"""
function Branch(n1, n2, v, i)
    Equation[
        RefBranch(n1, i)
        RefBranch(n2, -i)
        n1 - n2 - v
    ]
end



########################################
## Initial equations                  ##
########################################

"""
A ModelType describing initial equations. Current support is limited
and may be broken. There are no tests. The idea is that the equations
provided will only be used during the initial solution.

```julia
InitialEquation(eqs)
```

### Arguments

* `x::Unknown` : the quantity to be initialized
* `eqs::Array{Equation}` : a vector of equations, each to be equated
  to zero during the initial equation solution.

"""
type InitialEquation
    eq
end

# TODO enhance this to support begin..end blocks
macro init(eqs...)
   Expr(:cell1d, [:(InitialEquation($eq)) for eq in eqs])
end

########################################
## delay                              ##
########################################


"""
An UnknownVariable used as a helper for the `delay` function.  It is
an identity unknown, but it doesn't replace with a reference to the y
array.

PassedUnknown(ref::UnknownVariable)

### Arguments

* `ref::UnknownVariable` : an Unknown
"""
type PassedUnknown <: UnknownVariable
    ref
end
name(a::PassedUnknown) = a.ref.label != "" ? a.ref.label : symname(a.ref.sym)
value(a::PassedUnknown) = value(a.ref)

# vectorized version of _interp
function _interp(x, t)
    res = zero(value(t))
    for i in 1:length(res)
        if t[i] < 0.0 continue end
        idx = searchsortedfirst(x.t, t[i])
        if idx > length(res) continue end
        if idx == 1
            res[i] = x.x[1][i]
        elseif idx > length(x.t) 
            res[i] = x.x[end][i]
        else
            res[i] = (t[i] - x.t[idx-1]) / (x.t[idx] - x.t[idx-1]) .* (x.x[idx][i] - x.x[idx-1][i]) + x.x[idx-1][i]
        end
    end
    res
end
## function _interp(x::Unknown, t)
##     # assumes that tvec is sorted from low to high
##     if length(x.t) == 0 || t < 0.0 return zero(x.value) end
##     idx = searchsortedfirst(x.t, t)
##     if idx == 1
##         return x.x[1]
##     elseif idx > length(x.t) 
##         return x.x[end]
##     else
##         return (t - x.t[idx-1]) / (x.t[idx] - x.t[idx-1]) .* (x.x[idx] - x.x[idx-1]) + x.x[idx-1]
##     end
## end
## function _interp(x, t)
##     t > 0.0 ? x : 0.0
## end


"""
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

"""
function delay(x::Unknown, val)
    x.save_history = true
    x.t = [0.0]
    x.x = [x.value]
    MExpr(:(Sims._interp($(PassedUnknown(x)), $MTime - $val)))
end



########################################
## Utilities for Hybrid Modeling      ##
########################################


"""
An abstract type representing Unknowns that use the Reactive.jl
package. The main types included are `Discrete` and
`Parameter`. `Discrete` is normally used as inputs inside of models
and includes an initial value that is reset at every simulation
run. `Parameter` is used to pass information from outside to the
model. Use this for repeated simulation runs based on parameter
variations.

Because they are Unknowns, UnknownReactive types form MExpr's when
used in expressions just like Unknowns.

Many of the methods from Reactive.jl are supported, including `lift`,
`foldl`, `filter`, `dropif`, `droprepeats`, `keepwhen`, `dropwhen`,
`sampleon`, and `merge`. Use `reinit` to reinitialize a Discrete or a
Parameter (equivalent to `Reactive.push!`).

"""
abstract UnknownReactive{T} <: UnknownVariable

"""
Discrete is a type for discrete variables. These are only changed
during events. They are not used by the integrator. Because they are
not used by the integrator, almost any type can be used as a discrete
variable. Discrete variables wrap a Signal from the
[Reactive.jl](http://julialang.org/Reactive.jl/) package.

### Constructors

```julia
Discrete(initialvalue = 0.0)
Discrete(x::Reactive.Signal, initialvalue)
```

Without arguments, `Discrete()` uses an initial value of 0.0.

### Arguments

* `initialvalue` : initial value and type information, defaults to 0.0
* `x::Reactive.Signal` : a `Signal` from the Reactive.jl package.

### Details

`Discrete` is the main input type for discrete variables. By default,
it wraps a `Reactive.Signal` type. `Discrete` variables support data
flow using Reactive.jl. Use `reinit` to update Discrete variables. Use
`lift` to create additional `UnknownReactive` types that depend on the
`Discrete` input. Use `foldl` for actions that remember state. For
more information on *Reactive Programming*, see the
[Reactive.jl](http://julialang.org/Reactive.jl/) package.

"""
type Discrete{T <: Reactive.Signal} <: UnknownReactive{T}
    signal::T
    initialvalue
end
# Discrete(x::Reactive.SignalSource) = Discrete(x, zero(x))
Discrete(initialval) = Discrete(Reactive.Signal(initialval), initialval)
Discrete() = Discrete(Reactive.Signal(0.0), 0.0)

"""
An `UnknownReactive` type that is useful for passing parameters at the
top level.

### Arguments

```julia
Parameter(x = 0.0)
Parameter(sig::Reactive.Signal}
```

### Arguments

* `x` : initial value and type information, defaults to 0.0
* `sig` : A `Reactive.Signal 

### Details

Parameters can be reinitialized with `reinit`, either externally or
inside models. If you want Parameters to be read-only, wrap them in
another UnknownReactive before passing to models. For example, use
`param_read_only = lift(x -> x, param)`.

### Examples

Sims.Examples.Basics.VanderpolWithParameter takes one model argument
`mu`. Here is an example of it used externally with a Parameter:

```julia
mu = Parameter(1.0)
ss = create_simstate(VanderpolWithParameter(mu))
vwp1 = sim(ss, 10.0)
reinit(mu, 1.5)
vwp2 = sim(ss, 10.0)
reinit(mu, 1.0)
vwp3 = sim(ss, 10.0) # should be the same as vwp1
```

"""
type Parameter{T <: Reactive.Signal} <: UnknownReactive{T}
    signal::T
end
Parameter(x = 0.0) = Parameter(Reactive.Signal(x))

name(a::UnknownReactive) = "discrete"
value{T}(x::UnknownReactive{T}) = Reactive.value(x.signal)
signal(x::UnknownReactive) = x.signal

Reactive.push!{T}(x::Discrete{Reactive.Signal{T}}, y) = mexpr(:call, :(Reactive.push!), x.signal, y)
Reactive.push!{T}(x::Parameter{Reactive.Signal{T}}, y) = Reactive.push!(x.signal, y)


"""
`reinit` is used in Event responses to redefine variables. 

```julia
reinit(x, y)
```

### Arguments

* `x` : the object to be reinitialized; can be a Discrete, Parameter, an Unknown, or DerUnknown
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

See also [IdealThyristor](../../lib/electrical/#idealthyristor) in the standard library.

"""
reinit{T}(x::Discrete{Reactive.Signal{T}}, y) = mexpr(:call, :(Reactive.push!), x.signal, y)
reinit{T}(x::Parameter{Reactive.Signal{T}}, y) = Reactive.push!(x.signal, y)

function reinit(x, y)
    sim_info("reinit: $(x[]) to $y", 2)
    x[:] = y
end

"""
A helper type needed to mark unknowns as left-side variables in
assignments during event responses.
"""
type LeftVar <: ModelType
    var
end

reinit(x::LeftVar, y) = mexpr(:call, :(Sims.reinit), x, y)
reinit(x::LeftVar, y::MExpr) = mexpr(:call, :(Sims.reinit), x, y.ex)
reinit(x::Unknown, y) = reinit(LeftVar(x), y)
reinit(x::RefUnknown, y) = reinit(LeftVar(x), y)
reinit(x::DerUnknown, y) = reinit(LeftVar(x), y)


"""
Create a new UnknownReactive type that links to existing
UnknownReactive types (like Discrete and Parameter).

```julia
lift{T}(f::Function, inputs::UnknownReactive{T}...)
lift{T}(f::Function, t::Type, inputs::UnknownReactive{T}...)
map{T}(f::Function, inputs::UnknownReactive{T}...)
map{T}(f::Function, t::Type, inputs::UnknownReactive{T}...)
```

See also
[Reactive.lift](http://julialang.org/Reactive.jl/api.html#lift)] and
the [@liftd](#liftd) helper macro to ease writing expressions.

Note that `lift` is being transitioned to `Base.map`.

### Arguments

* `f::Function` : the transformation function; takes one argument for
  each `inputs` argument
* `inputs::UnknownReactive` : signals to apply `f` to
* `t::Type` : optional output type

Note: you cannot use Unknowns or MExprs in `f`, the transformation
function.

### Examples

```julia
a = Discrete(1)
b = lift(x -> x + 1, a)
c = lift((x,y) -> x * y, a, b)
reinit(a, 3)
b    # now 4
c    # now 12
```
See [IdealThyristor](../../lib/electrical/#idealthyristor) in the standard library.

Note that you can use Discretes and Parameters in expressions that
create MExprs. Compare the following:

```julia
j = lift((x,y) = x * y, a, b)
k = a * b
```

In this example, `j` uses `lift` to immediately connect to `a` and
`b`. `k` is an MExpr with `a * b` embedded inside. When `j` is used in
a model, the `j` UnknownReactive object is embedded in the model, and it
is updated automatically. With `k`, `a * b` is inserted into the
model, so it's more like a macro; `a * b` will be evaluated every time
in the residual calculation. The advantage of the `a * b` approach is
that the expression can include Unknowns.

"""
Reactive.lift{T}(f::Function, input::UnknownReactive{T}, inputs::UnknownReactive{T}...) = Parameter(map(f, input.signal, [input.signal for input in inputs]...))

Reactive.lift{T}(f::Function, t::Type, input::UnknownReactive{T}, inputs::UnknownReactive{T}...) = Parameter(map(f, t, input.signal, [input.signal for input in inputs]...))

Base.map{T}(f::Function, input::UnknownReactive{T}, inputs::UnknownReactive{T}...) = Parameter(map(f, input.signal, [input.signal for input in inputs]...))

Base.map{T}(f::Function, t::Type, input::UnknownReactive{T}, inputs::UnknownReactive{T}...) = Parameter(map(f, t, input.signal, [input.signal for input in inputs]...))

Reactive.filter{T}(pred::Function, v0, s::UnknownReactive{T}) = Parameter(filter(pred, v0, s.signal))
Reactive.dropwhen{T}(test::Signal{Bool}, v0, s::UnknownReactive{T}) = Parameter(dropwhen(pred, v0, s.signal))
Reactive.sampleon(s1::UnknownReactive, s2::UnknownReactive) = Parameter(sampleon(s1.signal, s2.signal))
# Reactive.merge() = nothing
Reactive.merge(signals::UnknownReactive...) = Parameter(merge(map(signal, signals)))
Reactive.droprepeats(s::UnknownReactive) = Parameter(droprepeats(signal(s)))
Reactive.dropif(pred::Function, v0, s::UnknownReactive) = Parameter(dropif(pred, v0, s.signal))
Reactive.keepwhen(test::UnknownReactive{Signal{Bool}}, v0, s::UnknownReactive) = Parameter(keepwhen(test.signal, v0, s.signal))



"""
"Fold over time" -- an UnknownReactive updated based on stored state
and additional inputs.

See also
[Reactive.foldl](http://julialang.org/Reactive.jl/api.html#foldl)].

```julia
foldl(f::Function, v0, inputs::UnknownReactive{T}...)
```

### Arguments

* `f::Function` : the transformation function; the first argument is
  the stored state followed by one argument for each `inputs` argument
* `v0` : initial value of the stored state
* `inputs::UnknownReactive` : signals to apply `f` to


### Returns

* `::UnknownReactive`

### Examples

See the definition of [pre](#pre) for an example.

"""
Reactive.foldl{T,S}(f,v0::T, signal::UnknownReactive{S}, signals::UnknownReactive{S}...) =
    Parameter(Reactive.foldl(f, v0, signal.signal, [s.signal for s in signals]...))



"""
A helper for an expression of UnknownReactive variables

```julia
@liftd exp
```

Note that the expression should not contain Unknowns. To mark the
Discrete variables, enter them as Symbols. This uses `lift()`.

### Arguments

* `exp` : an expression, usually containing other Discrete variables

### Returns

* `::Discrete` : a signal

### Examples

```julia
x = Discrete(true)
y = Discrete(false)
z = @liftd :x & !:y
## equivalent to:
z2 = lift((x, y) -> x & !y, x, y)
```

"""
macro liftd(ex)
    varnames = Any[]
    body = replace_syms(ex, varnames)
    front = Expr(:tuple, varnames...)
    esc(:( Reactive.lift($front ->  $body, $(varnames...)) ))
end
replace_syms(x, varnames) = x
function replace_syms(e::Expr, varnames)
    if e.head == :call && length(e.args) == 2 && e.args[1] == :^
        return e.args[2]
    elseif e.head == :.     # special case for :a.b
        return Expr(e.head, replace_syms(e.args[1], varnames),
                            typeof(e.args[2]) == Expr && e.args[2].head == :quote ? e.args[2] : replace_syms(e.args[2], varnames))
    elseif e.head != :quote
        return Expr(e.head, (isempty(e.args) ? e.args : map(x -> replace_syms(x, varnames), e.args))...)
    else
        push!(varnames, e.args[1])
        return e.args[1]
    end
end

"""
An `UnknownReactive` based on the previous value of `x` (normally prior to an event).

See also [Event](#event).

```julia
pre(x::UnknownReactive)
```

### Arguments

* `x::Discrete`

### Returns

* `::UnknownReactive`

"""
function pre{T}(x::UnknownReactive{T})
    Reactive.lift(x -> x[1],
         Reactive.foldl((a,b) -> (a[2], b), (zero(Sims.value(x)), Sims.value(x)), x))
end

    
"""
Event is the main type used for hybrid modeling. It contains a
condition for root finding and model expressions to process after
positive and negative root crossings are detected.

See also [BoolEvent](#boolevent).

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

See [IdealThyristor](../../lib/electrical/#idealthyristor) in the standard library.

"""
type Event <: ModelType
    condition::ModelType   # An expression used for the event detection. 
    pos_response::Model    # An expression indicating what to do when
                           # the condition crosses zero positively.
    neg_response::Model    # An expression indicating what to do when
                           # the condition crosses zero in the
                           # negative direction.
end
Event(condition::ModelType, p::MExpr, n::MExpr) = Event(condition, Equation[p], Equation[n])
Event(condition::ModelType, p::Model, n::MExpr) = Event(condition, p, Equation[n])
Event(condition::ModelType, p::MExpr, n::Model) = Event(condition, Equation[p], n)
Event(condition::ModelType, p::Model) = Event(condition, p, Equation[])
Event(condition::ModelType, p::MExpr) = Event(condition, Equation[p], Equation[])
Event(condition::ModelType, p::Expr) = Event(condition, p, Equation[])



"""
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

See [IdealDiode](../../lib/electrical/#idealdiode) and
[Limiter](../../lib/blocks/#limiter) in the standard library.

"""
function BoolEvent{T}(d::Discrete{T}, condition::ModelType)
    lend = length(value(d))
    lencond = length(value(condition))
    if lend > 1 && lencond == lend
        convert(Vector{Any},
                map((idx) -> BoolEvent(d[idx], condition[idx]), [1:lend]))
    elseif lend == 1 && lencond == 1
        Event(condition,       
              Equation[reinit(d, true)],
              Equation[reinit(d, false)])
    else
        error("Mismatched lengths for BoolEvent")
    end
end



"""
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

See [DeadZone](../../lib/electrical/#deadzone) and
[Limiter](../../lib/blocks/#limiter) in the standard library.

"""
ifelse(x::ModelType, y, z) = mexpr(:call, :ifelse, x, y, z)
ifelse(x::ModelType, y) = mexpr(:call, :ifelse, x, y)
## ifelse(x::Bool, y, z) = x ? y : z
## ifelse(x::Bool, y) = x ? y : nothing
## ifelse(x::Array{Bool}, y, z) = map((x) -> ifelse(x,y,z), x)
## ifelse(x::Array{Bool}, y) = map((x) -> ifelse(x,y), x)
ifelse(x::MExpr, y, z) = mexpr(:call, :ifelse, x.ex, y, z)
ifelse(x::MExpr, y) = mexpr(:call, :ifelse, x.ex, y)
ifelse(x::MExpr, y::MExpr, z::MExpr) = mexpr(:call, :ifelse, x.ex, y.ex, z.ex)
ifelse(x::MExpr, y::MExpr) = mexpr(:call, :ifelse, x.ex, y.ex)






########################################
## Types for Structural Dynamics      ##
########################################

"""
StructuralEvent defines a type for elements that change the structure
of the model. An event is created where the condition crosses zero.
When the event is triggered, the model is re-flattened after replacing
`default` with `new_relation` in the model.

```julia
StructuralEvent(condition::MExpr, default, new_relation::Function,
                pos_response, neg_response)
```

### Arguments

* `condition::MExpr` : an expression that will trigger the event at a
  zero crossing
* `default` : the default Model used
* `new_relation` : a function that returns a model that will replace
  the default model when the condition triggers the event.
* `pos_response` : an expression indicating what to do when the
  condition crosses zero positively. Defaults to Equation[].
* `neg_response::Model` : an expression indicating what to do when the
  condition crosses zero in the negative direction. Defaults to
  Equation[].

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
"""
type StructuralEvent <: ModelType
    condition::ModelType  # Expression indicating a zero crossing for event detection.
    default
    new_relation::Function
    activated::Bool       # Indicates whether the event condition has fired
    pos_response::Union{Void,Function}
    # A procedure that will be invoked with the model states and parameters when
    # the condition crosses zero positively.
end
StructuralEvent(condition::MExpr, default, new_relation::Function; pos_response=nothing) =
    StructuralEvent(condition, default, new_relation, false, pos_response)


########################################
## Complex number support             ##
########################################

#
# To support objects other than Float64, the methods to_real and
# from_real need to be defined.
#
# When complex quantities are output, the y array will contain the
# real and imaginary parts. These will not be labeled as such.
#

## from_real(x::Array{Float64, 1}, ref::Complex) = complex(x[1:2:length(x)], x[2:2:length(x)])
basetypeof{T}(x::Array{T}) = T
basetypeof(x) = typeof(x)
from_real(x::Array{Float64, 1}, basetype, sz) = reinterpret(basetype, x, sz)

to_real(x::Float64) = x
to_real(x::Array{Float64, 1}) = x
to_real(x::Array{Float64}) = x[:]
## to_real(x::Complex) = Float64[real(x), imag(x)]
## function to_real(x::Array{Complex128, 1}) # I tried reinterpret for this, but it seemed broken.
##     res = fill(0., 2*length(x))
##     for idx = 1:length(x)
##         res[2 * idx - 1] = real(x[idx])
##         res[2 * idx] = imag(x[idx])
##     end
##     res
## end
to_real(x) = reinterpret(Float64, collect(x)[:])



########################################
## @equations macro                   ##
########################################

"""
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
"""
macro equations(args)
    esc(equations_helper(args))
end

function parse_args(a::Expr)
    if a.head == :line
        nothing
    elseif a.head == :(=)
        Expr(:call, :-, parse_args(a.args[1]), parse_args(a.args[2]))
    elseif a.head == :(->)
        a     # don't traverse into anonymous functions
    else
        Expr(a.head, [parse_args(x) for x in a.args]...)
    end
end

parse_args(a::Array) = [parse_args(x) for x in a]
parse_args(x) = x

function equations_helper(arg)
    Expr(:ref, :Equation, parse_args(arg.args)...)
end

