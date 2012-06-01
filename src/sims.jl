
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
#   Computer and Information Science, Linköping University, Sweden,
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
#   - Initial equations
#   - Causal relationships or input/outputs (?)
#   - Metadata like variable name, units, and annotations (hard?)
#   - Symbolic processing like index reduction
#   - Error checking
#   - Tests
#
# Downsides of this approach:
#   - No connect-like capability. Must be nodal.
#   - Tough to do model introspection.
#   - Tough to map to a GUI. This is probably true with most
#     functional approaches. Tough to add annotations.
#
# For an implementation point of view, Julia works well for this. The
# biggest headache was coding up the callback to the residual
# function. For this, I used a kludgy approach with several global
# variables. This should improve in the future with a better C api. I
# also tried interfacing with the Sundials IDA solver, but that was
# even more difficult to interface. 
# 

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

abstract ModelType
abstract UnknownCategory
abstract UnknownVariable <: ModelType

type DefaultUnknown <: UnknownCategory
end

type Unknown{T<:UnknownCategory} <: UnknownVariable
    sym::Symbol
    value         # holds initial values (and type info)
    label::String 
    Unknown() = new(gensym(), 0.0, "")
    Unknown(sym::Symbol, label::String) = new(sym, 0.0, label)
    Unknown(sym::Symbol, value) = new(sym, value, "")
    Unknown(value) = new(gensym(), value, "")
    Unknown(label::String) = new(gensym(), 0.0, label)
    Unknown(value, label::String) = new(gensym(), value, label)
    Unknown(sym::Symbol, value, label::String) = new(sym, value, label)
end
Unknown() = Unknown{DefaultUnknown}(gensym(), 0.0, "")
Unknown(x) = Unknown{DefaultUnknown}(gensym(), x, "")
Unknown(s::Symbol, label::String) = Unknown{DefaultUnknown}(s, 0.0, label)
Unknown(x, label::String) = Unknown{DefaultUnknown}(gensym(), x, label)
Unknown(label::String) = Unknown{DefaultUnknown}(gensym(), 0.0, label)
Unknown(s::Symbol, x) = Unknown{DefaultUnknown}(s, x, "")


is_unknown(x) = isa(x, UnknownVariable)
    
type DerUnknown <: UnknownVariable
    sym::Symbol
    value        # holds initial values
    parent::Unknown
    # label::String    # Do we want this? 
end
DerUnknown(u::Unknown) = DerUnknown(u.sym, 0.0, u)
der(x::Unknown) = DerUnknown(x.sym, 0.0, x)
der(x::Unknown, val) = DerUnknown(x.sym, val, x)

# show(a::Unknown) = show(a.sym)

#
# Discrete is a type for discrete variables. These are only changed
# during events. They are not used by the integrator.
#
type Discrete <: UnknownVariable
    sym::Symbol
    value
    label::String 
end
Discrete() = Discrete(gensym(), 0.0, "")
Discrete(x) = Discrete(gensym(), x, "")
Discrete(s::Symbol, label::String) = Discrete(s, 0.0, label)
Discrete(x, label::String) = Discrete(gensym(), x, label)
Discrete(label::String) = Discrete(gensym(), 0.0, label)
Discrete(s::Symbol, x) = Discrete(s, x, "")


type MExpr <: ModelType
    ex::Expr
end
mexpr(hd::Symbol, args::ANY...) = MExpr(expr(hd, args...))

# Set up defaults for operations on ModelType's for many common
# methods.

for f = (:+, :-, :*, :.*, :/, :./, :^, :min, :max, :isless)
    @eval ($f)(x::ModelType, y::ModelType) = mexpr(:call, ($f), x, y)
    @eval ($f)(x::ModelType, y::Any) = mexpr(:call, ($f), x, y)
    @eval ($f)(x::Any, y::ModelType) = mexpr(:call, ($f), x, y)
    @eval ($f)(x::MExpr, y::MExpr) = mexpr(:call, ($f), x.ex, y.ex)
    @eval ($f)(x::MExpr, y::ModelType) = mexpr(:call, ($f), x.ex, y)
    @eval ($f)(x::ModelType, y::MExpr) = mexpr(:call, ($f), x, y.ex)
    @eval ($f)(x::MExpr, y::Any) = mexpr(:call, ($f), x.ex, y)
    @eval ($f)(x::Any, y::MExpr) = mexpr(:call, ($f), x, y.ex)
end 

for f = (:der, :sign, 
         :-, :!, :ceil, :floor,  :trunc,  :round, :sum, 
         :iceil,  :ifloor, :itrunc, :iround,
         :abs,    :angle,  :log10,
         :sqrt,   :cbrt,   :log,    :log2,   :exp,   :expm1,
         :sin,    :cos,    :tan,    :cot,    :sec,   :csc,
         :sinh,   :cosh,   :tanh,   :coth,   :sech,  :csch,
         :asin,   :acos,   :atan,   :acot,   :asec,  :acsc,
         :acoth,  :asech,  :acsch,  :sinc,   :cosc)
    @eval ($f)(x::ModelType) = mexpr(:call, ($f), x)
    @eval ($f)(x::MExpr) = mexpr(:call, ($f), x.ex)
end


# For now, a model is just a vector that anything, but probably it
# should include just ModelType's.
Model = Vector{Any}


# Add array access capability for Discretes and Unknowns:

type RefDiscrete <: UnknownVariable
    u::Discrete
    idx
end
ref(x::Discrete, args...) = RefDiscrete(x, args)
type RefUnknown{T<:UnknownCategory} <: UnknownVariable
    u::Unknown{T}
    idx
end
ref(x::Unknown, args...) = RefUnknown(x, args)
ref(x::MExpr, args...) = mexpr(:call, :ref, args...)

value(x) = x
value(x::Model) = map(value, x)
value(x::UnknownVariable) = x.value
value(x::RefUnknown) = x.u.value[x.idx...]
value(x::RefDiscrete) = x.u.value[x.idx...]
value(a::MExpr) = value(a.ex)
value(e::Expr) = eval(Expr(e.head, isempty(e.args) ? e.args : map(value, e.args), e.typ))
                       
# The following helper functions are to return the base value from an
# unknown to use when creating other unknowns. An example would be:
#   a = Unknown(45.0 + 10im)
#   b = Unknown(base_value(a))   # This one gets initialized to 0.0 + 0.0im.
#
compatible_values(u::UnknownVariable) = value(u) .* 0.0
# The value from the unknown determines the base value returned:
compatible_values(u1::UnknownVariable, u2::UnknownVariable) = length(value(u1)) > length(value(u2)) ? value(u1) .* 0.0 : value(u2) .* 0.0  
compatible_values(u::UnknownVariable, num::Number) = length(value(u)) > length(num) ? value(u) .* 0.0 : num .* 0.0 
compatible_values(num::Number, u::UnknownVariable) = length(value(u)) > length(num) ? value(u) .* 0.0 : num .* 0.0 
# This should work for real and complex valued unknowns, including
# arrays. For something more complicated, it may not.



# System time - a special unknown variable
MTime = Unknown(:time, 0.0)


#  The type RefBranch and the helper Branch are used to indicate the
#  potential between nodes and the flow between nodes.

type RefBranch <: ModelType
    n     # This is the reference node.
    i     # This is the flow variable that goes with this reference.
end

function Branch(n1, n2, v, i)
    {
     RefBranch(n1, i)
     RefBranch(n2, -i)
     n1 - n2 - v
     }
end






########################################
## Utilities for Hybrid Modeling      ##
########################################


#
# Event is the main type used for hybrid modeling. It contains a
# condition for root finding and model expressions to process after
# positive and negative root crossings are detected.
#

type Event <: ModelType
    condition::ModelType   # An expression used for the event detection. 
    pos_response::Model    # An expression indicating what to do when
                           # the condition crosses zero positively.
    neg_response::Model    # An expression indicating what to do when
                           # the condition crosses zero in the
                           # negative direction.
end
Event(condition::ModelType, p::MExpr, n::MExpr) = Event(condition, {p}, {n})
Event(condition::ModelType, p::Model, n::MExpr) = Event(condition, p, {n})
Event(condition::ModelType, p::MExpr, n::Model) = Event(condition, {p}, n)

#
# reinit is used in Event responses to redefine variables. LeftVar is
# needed to mark unknowns as left-side variables in assignments during
# event responses.
# 
type LeftVar <: ModelType
    var
end
function reinit(x, y)
    println("reinit: ", x[], " to ", y)
    x[:] = y
end
reinit(x::LeftVar, y) = mexpr(:call, :reinit, x, y)
reinit(x::LeftVar, y::MExpr) = mexpr(:call, :reinit, x, y.ex)
reinit(x::Unknown, y) = reinit(LeftVar(x), y)
reinit(x::RefUnknown, y) = reinit(LeftVar(x), y)
reinit(x::DerUnknown, y) = reinit(LeftVar(x), y)
reinit(x::Discrete, y) = reinit(LeftVar(x), y)
reinit(x::RefDiscrete, y) = reinit(LeftVar(x), y)

#
# BoolEvent is a helper for attaching an event to a boolean variable.
# In conjunction with ifelse, this allows constructs like Modelica's
# if blocks.
#
function BoolEvent(d::ModelType, condition::Union(Discrete, RefDiscrete))
    lend = length(value(d))
    lencond = length(value(condition))
    if lend > 1 && lencond == lend
        convert(Vector{Any},
                map((idx) -> BoolEvent(d[idx], condition[idx]), [1:lend]))
    elseif lend == 1 && lencond == 1
        Event(condition,       
              {reinit(d, true)},
              {reinit(d, false)})
    else
        error("Mismatched lengths for BoolEvent")
    end
end

#
# ifelse is like an if-then-else block, but for ModelTypes.
#
ifelse(x::Bool, y, z) = x ? y : z
ifelse(x::Bool, y) = x ? y : nothing
ifelse(x::Array{Bool}, y, z) = map((x) -> ifelse(x,y,z), x)
ifelse(x::Array{Bool}, y) = map((x) -> ifelse(x,y), x)
ifelse(x::ModelType, y, z) = mexpr(:call, :ifelse, x, y, z)
ifelse(x::ModelType, y) = mexpr(:call, :ifelse, x, y)
ifelse(x::MExpr, y, z) = mexpr(:call, :ifelse, x.ex, y, z)
ifelse(x::MExpr, y) = mexpr(:call, :ifelse, x.ex, y)
ifelse(x::MExpr, y::MExpr, z::MExpr) = mexpr(:call, :ifelse, x.ex, y.ex, z.ex)
ifelse(x::MExpr, y::MExpr) = mexpr(:call, :ifelse, x.ex, y.ex)




########################################
## Types for Structural Dynamics      ##
########################################

#
# StructuralEvent defines a type for elements that change the
# structure of the model. An event is created (condition is the zero
# crossing). When the event is triggered, the model is re-flattened
# after replacing default with new_relation in the model. 
type StructuralEvent <: ModelType
    condition::ModelType  # Expression indicating a zero crossing for event detection.
    default
    new_relation::Function
    activated::Bool       # Indicates whether the event condition has fired
end
StructuralEvent(condition::MExpr, default, new_relation::Function) = StructuralEvent(condition, default, new_relation, false)



########################################
## Elaboration / flattening           ##
########################################

#
# This converts a hierarchical model into a flat set of equations.
# 
# After elaboration, the following structure is returned. This sort-of
# follows Hydra's SymTab structure.
#

#
type EquationSet
    model           # The active model, a hierachichal set of equations.
    equations       # A flat list of equations.
    events
    pos_responses
    neg_responses
    nodeMap::Dict
end
# In EquationSet, model contains equations and StructuralEvents. When
# a StructuralEvent triggers, the entire model is elaborated again.
# The first step is to replace StructuralEvents that have activated
# with their new_relation in model. Then, the rest of the EquationSet
# is reflattened using model as the starting point.


# 
# elaborate is the main elaboration function. There is no real symbolic
# processing (sorting, index reduction, or any of the other stuff a
# fancy modeling tool would do).
# 
elaborate(a::Model) = elaborate(EquationSet(a, {}, {}, {}, {}, Dict()))

function elaborate(x::EquationSet)
    eq = EquationSet({}, {}, {}, {}, {}, Dict())
    eq.model = handle_events(x.model)
    eq.equations = elaborate_unit(eq.model, eq) # This will also modify eq.

    # Add in equations for each node to sum flows to zero:
    for (key, nodeset) in eq.nodeMap
        push(eq.equations, nodeset)
    end
    # last fixups: 
    eq.equations = remove_empties(strip_mexpr(eq.equations))
    eq
end

# Generic model traversing helper.
# Applies a function to each element of the model tree.
function traverse_mod(f::Function, a::Model)
    emodel = {}
    for el in a
        el1 = f(el)
        if applicable(length, el1)
            append!(emodel, el1)
        else  # this handles symbols
            push(emodel, el1)
        end
    end
    emodel
end

#
# handle_events traverses the model tree and replaces
# StructuralEvent's that have activated.
#
handle_events(a::Model) = traverse_mod(handle_events, a)
handle_events(x) = x
handle_events(ev::StructuralEvent) = ev.activated ? ev.new_relation() : ev

#
# elaborate_unit flattens the set of equations while building up
# events, event responses, and a Dict of nodes.
#
elaborate_unit(a::Any, eq::EquationSet) = Expr[] # The default is to ignore undefined types.
elaborate_unit(a::ModelType, eq::EquationSet) = a
elaborate_unit(a::Model, eq::EquationSet) = traverse_mod((x) -> elaborate_unit(x, eq), a)

function elaborate_unit(b::RefBranch, eq::EquationSet)
    if (isa(b.n, Unknown))
        eq.nodeMap[b.n] = get(eq.nodeMap, b.n, 0.0) + b.i
    elseif (isa(b.n, RefUnknown))
        vec = compatible_values(b.n.u)
        vec[b.n.idx...] = 1.0
        eq.nodeMap[b.n.u] = get(eq.nodeMap, b.n.u, 0.0) + b.i .* vec 
    end
    {}
end

function elaborate_unit(ev::Event, eq::EquationSet)
    push(eq.events, strip_mexpr(elaborate_unit(ev.condition, eq)))
    push(eq.pos_responses, strip_mexpr(elaborate_unit(ev.pos_response, eq)))
    push(eq.neg_responses, strip_mexpr(elaborate_unit(ev.neg_response, eq)))
    {}
end

function elaborate_unit(ev::StructuralEvent, eq::EquationSet)
    # Set up the event:
    push(eq.events, strip_mexpr(elaborate_unit(ev.condition, eq)))
    # A positive zero crossing initiates a change:
    push(eq.pos_responses, (t,y,yp) -> begin global __sim_structural_change = true; ev.activated = true; end)
    # Dummy negative zero crossing
    push(eq.neg_responses, (t,y,yp) -> return)
    strip_mexpr(elaborate_unit(ev.default, eq))
end


# These methods strip the MExpr's from expressions.
strip_mexpr(a) = a
strip_mexpr{T}(a::Vector{T}) = map(strip_mexpr, a)
strip_mexpr(a::MExpr) = strip_mexpr(a.ex)
## strip_mexpr(a::MSymbol) = a.sym 
strip_mexpr(e::Expr) = Expr(e.head, isempty(e.args) ? e.args : map(strip_mexpr, e.args), e.typ)

# Other utilities:
remove_empties(l::Vector{Any}) = filter(x -> !isequal(x, {}), l)
eval_all(x) = eval(x)
eval_all{T}(x::Array{T,1}) = map(eval_all, x)





########################################
## Residual function and Sim creation ##
########################################

#
# From the flattened equations, generate a set of functions for use by
# the simulation. The residual function has arguments (t,y,yp) that
# returns the residual of type Float64 of length N, the number of
# equations in the system. The vectors y and yp are also of length N
# and type Float64. As part of finding the residual function, we use
# several Dicts to map unknown variables to indexes into y and yp.
# 
# SimFunctions is the set of functions used during simulation. All
# functions take (t,y,yp) as arguments.
#
type SimFunctions
    resid::Function           
    event_at::Function          # Returns a Vector of root-crossing values. 
    event_pos::Vector{Function} # Each function is to be run when a
                                #   positive root crossing is detected.
    event_neg::Vector{Function} # Each function is to be run when a
                                #   negative root crossing is detected.
    get_discretes::Function     # Placeholder for a function to return
                                #   discrete values.
end
SimFunctions(resid::Function, event_at::Function, event_pos::Vector{None}, event_neg::Vector{None}, get_discretes::Function) = 
    SimFunctions(resid, event_at, Function[], Function[], get_discretes)

type Sim
    eq::EquationSet           # the input
    F::SimFunctions
    y0::Array{Float64, 1}     # initial values
    yp0::Array{Float64, 1}    # initial values of derivatives
    id::Array{Int, 1}         # indicates whether a variable is algebraic or differential
    outputs::Array{ASCIIString, 1} # output labels
    unknown_idx_map::Dict     # symbol => index into y (or yp)
    discrete_map::Dict        # sym => Discrete variable 
    y_map::Dict               # sym => Unknown variable 
    yp_map::Dict              # sym => DerUnknown variable 
    varnum::Int               # variable indicator position that's incremented
    
    Sim(eq::EquationSet) = new(eq)
end

#
# This is the main function for creating Sim's.
#
function create_sim(eq::EquationSet)
    sm = Sim(eq)
    sm.varnum = 1
    sm.unknown_idx_map = Dict()
    sm.discrete_map = Dict()
    sm.y_map = Dict()
    sm.yp_map = Dict()
    sm.F = setup_functions(sm)  # Most of the work's done here.
    N_unknowns = sm.varnum - 1
    sm.y0 = fill_from_map(0.0, N_unknowns, sm.y_map, x -> to_real(x.value))
    sm.yp0 = fill_from_map(0.0, N_unknowns, sm.yp_map, x -> to_real(x.value))
    sm.id = fill_from_map(-1, N_unknowns, sm.yp_map, x -> 1)
    sm.outputs = fill_from_map("", N_unknowns, sm.y_map, x -> x.label)
    sm
end

# Utility to vectors based on values in Dict's. The key in the Dict
# gives the indexes in the vector.
function fill_from_map(default_val,# Default value for the vector.
                       N,          # Length of the resulting vector.
                       the_map,    # The Dict.
                       f)          # A function applied to each value.
    x = fill(default_val, N)
    for (k,v) in the_map
        x[ [k] ] = f(v)
    end
    x
end

#
# setup_functions sets up several functions in a closure setup to
# share common variables. This allows model components to access
# Discrete variables during integration steps and during event
# responses.
#
# Unknowns are also replaced by references to y and yp. As part of
# replacing unknowns, several of the Dicts in sm are populated.
#
function setup_functions(sm::Sim)
    # eq_block should be just expressions suitable for eval'ing.
    eq_block = replace_unknowns(sm.eq.equations, sm)
    ev_block = replace_unknowns(sm.eq.events, sm)
    
    # Set up a master function with variable declarations and 
    # functions that have access to those variables.
    #
    # Variable declarations are for Discrete variables. Each
    # is stored in its own array, so it can be overwritten by
    # reinit.
    discrete_defs = reduce((x,y) -> :($x;$(y[1]) = [$(y[2].value)]), :(), sm.discrete_map)
    # The following is a code block (thunk) for insertion into
    # the residual calculation function.
    resid_thunk = Expr(:call, append({:vcat_real}, eq_block), Any)
    # Same but for the root crossing function:
    event_thunk = Expr(:call, append({:vcat_real}, ev_block), Any)

    # Helpers to convert an array of expressions into a single expression.
    to_thunk{T}(ex::Vector{T}) = reduce((x,y) -> :($x;$y), :(), ex)
    to_thunk(ex::Expr) = ex
    to_thunk(ex::Function) = ex

    #
    # The event responses are more work. We need one "thunk" for each
    # event, and one set for positive and one set for negative
    # crossings.
    #
    ev_pos_array = Expr[]
    ev_neg_array = Expr[]
    for idx in 1:length(sm.eq.events)
        ex = to_thunk(replace_unknowns(sm.eq.pos_responses[idx], sm))
        push(ev_pos_array, 
             quote
                 (t, y, yp) -> begin $ex; return; end
             end)
        ex = to_thunk(replace_unknowns(sm.eq.neg_responses[idx], sm))
        push(ev_neg_array, 
             quote
                 (t, y, yp) -> begin $ex; return; end
             end)
    end
    ev_pos_thunk = length(ev_pos_array) > 0 ? Expr(:call, append({:vcat}, ev_pos_array), Any) : Function[]
    ev_neg_thunk = length(ev_neg_array) > 0 ? Expr(:call, append({:vcat}, ev_neg_array), Any) : Function[]
    
    get_discretes_thunk = :(() -> 1)   # dummy function for now

    #
    # The framework for the master function defined. Each "thunk" gets
    # plugged into a function which is evaluated.
    #
    expr = quote
        () -> begin
            $discrete_defs
            function resid(t, y, yp)
                 $resid_thunk
            end
            function event_at(t, y, yp)
                 $event_thunk
            end
            event_pos_array = $ev_pos_thunk
            event_neg_array = $ev_neg_thunk
            function get_discretes()
                 $get_discretes_thunk
            end
            SimFunctions(resid, event_at, event_pos_array, event_neg_array, get_discretes)
        end
    end
    global _ex = expr
    F = eval(expr)()

    # For event responses that were actual functions, insert those into
    # the F structure.
    for idx in 1:length(sm.eq.events)
        if isa(sm.eq.pos_responses[idx], Function)
            F.event_pos[idx] = sm.eq.pos_responses[idx]
        end
        if isa(sm.eq.neg_responses[idx], Function)
            F.event_neg[idx] = sm.eq.neg_responses[idx]
        end
    end
    F
end

# add_var add's a variable to the unknown_idx_map if it isn't already
# there. 
function add_var(v, sm) 
    if !has(sm.unknown_idx_map, v.sym)
        # Account for the length and fundamental size of the object
        len = length(v.value) * int(sizeof([v.value][1]) / 8)  
        idx = len == 1 ? sm.varnum : (sm.varnum:(sm.varnum + len - 1))
        sm.unknown_idx_map[v.sym] = idx
        sm.varnum = sm.varnum + len
    end
end

# The replace_unknowns method replaces Unknown types with
# references to the positions in the y or yp vectors.
replace_unknowns(a, sm::Sim) = a
replace_unknowns{T}(a::Array{T,1}, sm::Sim) = map(x -> replace_unknowns(x, sm), a)
replace_unknowns(e::Expr, sm::Sim) = Expr(e.head, replace_unknowns(e.args, sm), e.typ)
function replace_unknowns(a::Unknown, sm::Sim)
    if isequal(a.sym, :time)
        return :(t[1])
    end
    add_var(a, sm)
    sm.y_map[sm.unknown_idx_map[a.sym]] = a
    if isreal(a.value)
        :(ref(y, ($(sm.unknown_idx_map[a.sym]))))
    else
        :(from_real(ref(y, ($(sm.unknown_idx_map[a.sym]))), $(a.value)))
    end
end
function replace_unknowns(a::RefUnknown, sm::Sim) # handle array referencing
    add_var(a.u, sm)
    sm.y_map[sm.unknown_idx_map[a.u.sym]] = a.u
    if isreal(a.u.value)
        :(ref(y, ($(sm.unknown_idx_map[a.u.sym][a.idx...]))))
    else
        :(from_real(ref(y, ($(sm.unknown_idx_map[a.sym][a.idx...]))), $(a.value)))
    end
end
function replace_unknowns(a::DerUnknown, sm::Sim) 
    add_var(a, sm)
    sm.y_map[sm.unknown_idx_map[a.parent.sym]] = a.parent
    sm.yp_map[sm.unknown_idx_map[a.sym]] = a
    :(ref(yp, ($(sm.unknown_idx_map[a.sym]))))
end
function replace_unknowns(a::Discrete, sm::Sim)
    sm.discrete_map[a.sym] = a
    :(ref($(a.sym), 1))
end
function replace_unknowns(a::RefDiscrete, sm::Sim) # handle array referencing
    sm.discrete_map[a.u.sym] = a.u
    :(ref(ref($(a.u.sym), 1), a.idx))
end
# In assigned variables (LeftVar), use SubArrays (sub), instead of ref.
# This allows assignment.
function replace_unknowns(a::LeftVar, sm::Sim)
    var = replace_unknowns(a.var, sm)
    :(sub($(var.args[2]), $(var.args[3])))
end

#
# vcat_real is like vcat, but each element is converted to real with
# to_real.
#
vcat_real(X::Any...) = [ to_real(X[i]) for i=1:length(X) ]
function vcat_real(X::Any...)
    ## println(X[1])
    res = map(to_real, X)
    vcat(res...)
end



########################################
## Simulation                         ##
########################################

#
# This uses an interface to the DASSL library to solve a DAE using the
# residual function from above.
# 
# This is quite kludgy and should get better when Julia's C interface
# improves. I use global variables for the callback function and for
# the main variables used in the residual function callback.
#
global __daskr_res_callback 
global __daskr_event_callback 
global __daskr_t  
global __daskr_y 
global __daskr_yp
global __daskr_res
ilib = dlopen("daskr_interface.so")  # Something went wrong when these were
lib = dlopen("daskr.so")             # inside the sim function.

type SimResult
    y::Array{Float64, 2}
    colnames::Array{ASCIIString, 1}
end
ref(x::SimResult, idx...) = SimResult(x.y[:,idx...], x.colnames[idx...])

function sim(sm::Sim, tstop::Float64, Nsteps::Int)
    # tstop & Nsteps should be in options

    yidx = sm.outputs != ""
    yidx = map((s) -> s != "", sm.outputs)
    Noutputs = sum(yidx)
    Ncol = Noutputs
    tstep = tstop / Nsteps
    tout = [tstep]
    idid = [int32(0)]
    info = fill(int32(0), 20)
    info[11] = 1    # calc initial conditions (1 or 2) / don't calc (0)
    info[18] = 0    # more initialization info
    
    function setup_sim(sm::Sim, tstart::Float64, tstop::Float64, Nsteps::Int)
        global __sim_structural_change = false
        N = [int32(length(sm.y0))]
        t = [tstart]
        y = copy(sm.y0)
        yp = copy(sm.yp0)
        nrt = [int32(length(sm.F.event_pos))]
        rpar = [0.0]
        rtol = [1e-5]
        atol = [1e-5]
        lrw = [int32(N[1]^2 + 9 * N[1] + 60 + 3 * nrt[1])] 
        rwork = fill(0.0, lrw[1])
        liw = [int32(2*N[1] + 40)] 
        iwork = fill(int32(0), liw[1])
        iwork[40 + (1:N[1])] = sm.id
        ipar = [int32(length(sm.y0)), nrt[1]]
        jac = [int32(0)]
        psol = [int32(0)]
        jroot = fill(int32(0), max(nrt[1], 1))
         
        # Set up the callback.
        callback = dlsym(ilib, :res_callback)
        rt = dlsym(ilib, :event_callback)
        global __daskr_res_callback = sm.F.resid
        global __daskr_event_callback = sm.F.event_at
        global __daskr_t = [0.0] 
        global __daskr_y = y
        global __daskr_yp = yp
        global __daskr_res = copy(y)
        
        (tout) -> begin
            ccall(dlsym(lib, :ddaskr_), Void,
                  (Ptr{Void}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, # RES, NEQ, T, Y, YPRIME
                   Ptr{Float64}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64},            # TOUT, INFO, RTOL, ATOL
                   Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},                # IDID, RWORK, LRW, IWORK
                   Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Void}, Ptr{Void},      # LIW, RPAR, IPAR, JAC, PSOL
                   Ptr{Void}, Ptr{Int32}, Ptr{Int32}),                              # RT, NRT, JROOT
                  callback, N, t, y, yp, tout, info, rtol, atol,
                  idid, rwork, lrw, iwork, liw, rpar, ipar, jac, psol,
                  rt, nrt, jroot)
             (t,y,yp,jroot)
         end
    end

    simulate = setup_sim(sm, 0.0, tstop, Nsteps)
    yout = zeros(Nsteps, Ncol + 1)

    for idx in 1:Nsteps
        (t,y,yp,jroot) = simulate(tout)
        ## if t[1] * 1.01 > tstop
        ##     break
        ## end
        ## if t[1] > 0.005     #### DEBUG
        ##     break
        ## end
        if idid[1] >= 0 && idid[1] <= 5 
            yout[idx, 1] = t[1]
            yout[idx, 2:(Noutputs + 1)] = y[yidx]
            tout = t + tstep
            if idid[1] == 5 # Event found
                for ridx in 1:length(jroot)
                    if jroot[ridx] == 1
                        sm.F.event_pos[ridx](t, y, yp)
                    elseif jroot[ridx] == -1
                        sm.F.event_neg[ridx](t, y, yp)
                    end
                end
                if __sim_structural_change
                    println("")
                    println("Structural change event found at t = $(t[1]), restarting")
                    # Put t, y, and yp values back into original equations:
                    for (k,v) in sm.y_map
                        v.value = y[k]
                    end
                    for (k,v) in sm.yp_map
                        v.value = yp[k]
                    end
                    MTime.value = t[1]
                    # Reflatten equations
                    sm = create_sim(elaborate(sm.eq))
                    global _sm = copy(sm)
                    # Restart the simulation:
                    info[1] = 0
                    info[11] = 1    # do/don't calc initial conditions
                    simulate = setup_sim(sm, t[1], tstop, int(Nsteps * (tstop - t[1]) / tstop))
                    yidx = map((s) -> s != "", sm.outputs)
                elseif any(jroot != 0)
                    println("event found at t = $(t[1]), restarting")
                    info[1] = 0
                    info[11] = 1    # do/don't calc initial conditions
                end
            end
        elseif idid[1] < 0 && idid[1] > -11
            println("RESTARTING")
            info[1] = 0
        else
            println("DASKR failed prematurely")
            break
        end
    end
    SimResult(yout, [sm.outputs[yidx]])
end
sim(sm::Sim) = sim(sm, 1.0, 500)
sim(sm::Sim, tstop::Float64) = sim(sm, tstop, 500)
sim(m::Model, tstop::Float64, Nsteps::Int)  = sim(create_sim(elaborate(m)), tstop, Nsteps)
sim(m::Model) = sim(m, 1.0, 500)
sim(m::Model, tstop::Float64) = sim(m, tstop, 500)




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

from_real(x::Array{Float64, 1}, ref::Complex) = complex(x[1:2:length(x)], x[2:2:length(x)])
to_real(x::Float64) = x
to_real(x::Array{Float64, 1}) = x
to_real(x::Complex) = Float64[real(x), imag(x)]
function to_real(x::Array{Complex128, 1}) # I tried reinterpret for this, but it seemed broken.
    res = fill(0., 2*length(x))
    for idx = 1:length(x)
        res[2 * idx - 1] = real(x[idx])
        res[2 * idx] = imag(x[idx])
    end
    res
end







########################################
## Basic plotting with Gaston         ##
########################################




function plot(sm::SimResult)
    N = length(sm.colnames)
    figure()
    c = CurveConf()
    a = AxesConf()
    a.title = ""
    a.xlabel = "Time (s)"
    a.ylabel = ""
    addconf(a)
    for plotnum = 1:N
        c.legend = sm.colnames[plotnum]
        addcoords(sm.y[:,1],sm.y[:, plotnum + 1],c)
    end
    llplot()
end




########################################
## Basic plotting with Winston        ##
########################################


# the following is needed:
# load("winston.jl")

function wplot( sm::SimResult, filename::String, args... )
    N = length( sm.colnames )
    a = FramedArray( N, 1, "", "" )
    setattr( a, "xlabel", "Time (s)" )
    setattr( a, "ylabel", " Y " )
    ## setattr(a, "tickdir", +1)
    ## setattr(a, "draw_spine", false)
    for plotnum = 1:N
        add( a[plotnum,1], Curve(sm.y[:,1],sm.y[:, plotnum + 1]) )
        setattr( a[plotnum,1], "ylabel", sm.colnames[plotnum] )
    end
    file( a, filename, args... )
    a
end



########################################
## Utilities                          ##
########################################

keys(d::Dict) = [k for (k, v) in d]
vals(d::Dict) = [v for (k, v) in d]
        
