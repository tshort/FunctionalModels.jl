

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
# This implementation follows the work of David Broman. His thesis
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
# Functional hybrid modelling (FHM) is another interesting approach
# developed by George Giorgidze and Henrik Nilsson. See here:
# 
#   https://github.com/giorgidze/Hydra
#   http://db.inf.uni-tuebingen.de/team/giorgidze
#   http://www.cs.nott.ac.uk/~nhn/
# 
# FHM is also a functional approach. Their implementation handles
# dynamically changing systems with JIT-compiled code from an
# amazingly small amount of code. Their implementation (Hydra) is
# implemented as a domain specific language embedded in Haskell. I
# can't read Haskell very well, so I haven't figured out how it works.
# I should try harder to figure it out, because the ability to handle
# structural changes is pretty cool. 
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
#   - Hybrid modeling (basics)
#   - Discrete hard
#   
# What's missing:
#   - Structurally variable systems
#   - Initial equations (medium difficulty)
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
# Differences with David's approach:
#   - Ground references are handled differently. By treating them
#     as knowns instead of unknowns, there are less equations.
#   - Arrays of unknowns can be used.
#
# For an implementation point of view, Julia works well for this.
# The biggest headache was coding up the callback to the residual
# function. For this, I used a kludgy approach with several global
# variables. This should improve in the future with a better C api.
# I also tried interfacing with the Sundials IDA solver, but that
# was even more difficult to interface. Also, if the residual
# function doesn't have the right number of arguments, you'll
# probably get segfaults.
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

# The following helper functions are to return the base value from an unknown to use when creating other unknowns. An example would be:
#   a = Unknown(45.0 + 10im)
#   b = Unknown(base_value(a))   # This one gets initialized to 0.0 + 0.0im.
#
base_value(u::Unknown) = u.value .* 0.0
# The value from the unknown determines the base value returned:
base_value(u1::Unknown, u2::Unknown) = length(u1.value) > length(u2.value) ? u1.value .* 0.0 : u2.value .* 0.0  
base_value(u::Unknown, num::Number) = length(u.value) > length(num) ? u.value .* 0.0 : num .* 0.0 
base_value(num::Number, u::Unknown) = length(u.value) > length(num) ? u.value .* 0.0 : num .* 0.0 
# This should work for real and complex valued unknowns, including
# arrays. For something more complicated, it may not.

is_unknown(x) = isa(x, Unknown)
    
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
# A type for discrete variables. These are only changed during
# events. They are not used by the integrator.
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

# show(m::MExpr) = show(m.ex)

## type MSymbol <: ModelType
##     sym::Symbol
## end

for f = (:+, :-, :*, :.*, :/, :./, :^, :isless)
    @eval ($f)(x::ModelType, y::ModelType) = mexpr(:call, ($f), x, y)
    @eval ($f)(x::ModelType, y::Any) = mexpr(:call, ($f), x, y)
    @eval ($f)(x::Any, y::ModelType) = mexpr(:call, ($f), x, y)
    @eval ($f)(x::MExpr, y::MExpr) = mexpr(:call, ($f), x.ex, y.ex)
    @eval ($f)(x::MExpr, y::ModelType) = mexpr(:call, ($f), x.ex, y)
    @eval ($f)(x::ModelType, y::MExpr) = mexpr(:call, ($f), x, y.ex)
    @eval ($f)(x::MExpr, y::Any) = mexpr(:call, ($f), x.ex, y)
    @eval ($f)(x::Any, y::MExpr) = mexpr(:call, ($f), x, y.ex)
end 

for f = (:der, 
         :-, :!, :ceil, :floor,  :trunc,  :round, 
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

# Add array access capability for Unknowns:

ref(x::Unknown, args...) = mexpr(:call, :ref, x, args...)

# System time
## MTime = MExpr(:(t[1]))
MTime = Unknown(:time, 0.0)

# UnknownOrNumber = Union(Unknown, Number)

#  The type RefBranch and the helper Branch are used to indicate the
#  potential between nodes and the flow between nodes.

type RefBranch <: ModelType
    n     # this is the reference node
    i     # this is the flow variable that goes with this reference
end

function Branch(n1, n2, v, i)
    {
     RefBranch(n1, i)
     RefBranch(n2, -i)
     n1 - n2 - v
     }
end


# For now, a model is just a vector that anything, but probably it
# should include just ModelType's.
Model = Vector{Any}



########################################
## Utilities for Hybrid Modeling      ##
########################################

#
# Event is the main type used for hybrid modeling. It contains a
# condition for root finding and model expressions to process for
# positive and negative root crossings.
#

type Event <: ModelType
    condition::ModelType
    pos_response::Model
    neg_response::Model
end

#
# reinit and LeftVar are needed to make assignments during events.
# 
type LeftVar <: ModelType
    var
end
function reinit(x, y)
    x[:] = y
end
reinit(x::LeftVar, y) = mexpr(:call, :reinit, x, y)
reinit(x::LeftVar, y::MExpr) = mexpr(:call, :reinit, x, y.ex)
reinit(x::Unknown, y) = reinit(LeftVar(x), y)
reinit(x::DerUnknown, y) = reinit(LeftVar(x), y)
reinit(x::Discrete, y) = reinit(LeftVar(x), y)

function BoolEvent(d::Discrete, cond::ModelType)
    Event(cond,
          {reinit(d, true)},
          {reinit(d, false)})
end

ifelse(x::Bool, y, z) = x ? y : z
ifelse(x::ModelType, y, z) = mexpr(:call, :ifelse, x, y, z)
ifelse(x::MExpr, y, z) = mexpr(:call, :ifelse, x.ex, y, z)
ifelse(x::MExpr, y::MExpr, z::MExpr) = mexpr(:call, :ifelse, x.ex, y.ex, z.ex)




########################################
## Utilities for Structural Changes   ##
########################################

insert_val(a) = a
insert_val(a::MExpr) = insert_val(a.ex)
insert_val(a::Unknown) = a.value 
insert_val(a::DerUnknown) = a.value 
insert_val(a::Discrete) = a.value 
function insert_val(a::Expr)
    ret = copy(a)
    ret.args = map((x) -> insert_val(x), ret.args)
    ret
end
function meval(x::Expr)   # Evaluate an MExpr with current values for all variables.
    eval(insert_val(x)) 
end
meval(x::MExpr) = meval(x.ex)

type StructuralEvent <: ModelType
    condition::MExpr
    new_relation
    default
end




########################################
## Elaboration / flattening           ##
########################################

#
# This converts a hierarchical model into a flat set of equations.
# 
# After elaboration, the following structure is returned.
#

EquationComponent = Union(Expr, UnknownVariable)

type EquationSet
    equations
    events
    ## equations::Vector{EquationComponent}
    ## events::Vector{EquationComponent}
    pos_response
    neg_response
    original        # unflattened, original model
end


# 
# This needs something to better separate special constructs (like
# RefBranch). The accumulating and finalizing is tricky to separate.
# 
# There is no real symbolic processing (sorting, index reduction, or
# any of the other stuff a fancy modeling tool would do).
# 
function elaborate(a::Model)
    nodeMap = Dict()
    events = Expr[]
    pos_responses = {}
    neg_responses = {}
    
    elaborate_unit(a::Any) = Expr[] # The default is to ignore undefined types.
    elaborate_unit(a::ModelType) = a
    function elaborate_unit(a::Model)
        ## if (length(a) == 1)
        ##     return(a)
        ## end
        emodel = {}
        for el in a
            el1 = elaborate_unit(el)
            if applicable(length, el1)
                append!(emodel, el1)
            else  # this handles symbols
                push(emodel, el1)
            end
        end
        emodel
    end
    
    function elaborate_unit(b::RefBranch)
        if (is_unknown(b.n))
            nodeMap[b.n] = get(nodeMap, b.n, 0.0) + b.i
        end
        {}
    end
    
    function elaborate_unit(ev::Event)
        ## println("Event found")
        ## println(ev)
        push(events, strip_mexpr(elaborate_unit(ev.condition)))
        push(pos_responses, convert(Vector{EquationComponent}, strip_mexpr(elaborate_unit(ev.pos_response))))
        push(neg_responses, convert(Vector{EquationComponent}, strip_mexpr(elaborate_unit(ev.neg_response))))
        {}
    end
    
    function elaborate_unit(ev::StructuralEvent)
        # Evaluate the condition now to determine what equations to return:
        # This is a bit shakey in that I'm not sure if the initial conditions
        # will work out with this.
        ## println("here")
        if meval(ev.condition) >= 0.0
            println("New relation: ", ev.new_relation)
            tmp = strip_mexpr(elaborate_unit(eval_all(strip_mexpr(ev.new_relation))))
            ## global _tmp = copy(tmp)
            tmp
        else
            # Set up the event:
            push(events, strip_mexpr(elaborate_unit(ev.condition)))
            # A positive zero crossing initiates a change:
            push(pos_responses, :({global __sim_structural_change = true}))
            # Dummy negative zero crossing
            push(neg_responses, :({pi + 0.0}))
            tmp = strip_mexpr(elaborate_unit(ev.default))
            tmp
        end
    end
    
    equations = elaborate_unit(copy(a))
    for (key, nodeset) in nodeMap
        push(equations, nodeset)
    end
    ## global _eq = copy(equations)
    ## global _eq1 = remove_empties(strip_mexpr(_eq))
    equations = convert(Vector{EquationComponent}, remove_empties(strip_mexpr(equations)))

    EquationSet(equations, events, pos_responses, neg_responses, a)
end

# These methods strip the MExpr's from expressions.
strip_mexpr(a) = a
strip_mexpr{T}(a::Vector{T}) = map(strip_mexpr, a)
strip_mexpr(a::MExpr) = strip_mexpr(a.ex)
## strip_mexpr(a::MSymbol) = a.sym 
function strip_mexpr(a::Expr)
    ret = copy(a)
    ret.args = strip_mexpr(ret.args)
    ret
end
remove_empties(l::Vector{Any}) = filter(x -> !isequal(x, {}), l)
eval_all(x) = eval(x)
eval_all{T}(x::Array{T,1}) = map(eval, x)

########################################
## Residual function and Sim creation ##
########################################

#
# From the flattened equations, generate a residual function with
# arguments (t,y,yp) that returns the residual of type Float64 of
# length N, the number of equations in the system. The vectors y and
# yp are also of length N and type Float64. As part of finding the
# residual function, we need to map unknown variables to indexes into
# y and yp.
# 

type SimFunctions
    resid::Function
    event_at::Function
    event_pos::Vector{Function}
    event_neg::Vector{Function}
    get_discretes::Function
end
SimFunctions(resid::Function, event_at::Function, event_pos::Vector{None}, event_neg::Vector{None}, get_discretes::Function) = 
    SimFunctions(resid, event_at, Function[], Function[], get_discretes)

type Sim
    F::SimFunctions
    y0::Array{Float64, 1}     # initial values
    yp0::Array{Float64, 1}    # initial values of derivatives
    id::Array{Int, 1}         # indicates whether a variable is algebraic or differential
    outputs::Array{ASCIIString, 1} # output labels
    discrete_map::Dict        # sym => Discrete variable 
    y_map::Dict               # sym => Unknown variable 
    yp_map::Dict              # sym => DerUnknown variable 
    eq::EquationSet           # the input
end

vcat_real(X::Any...) = [ to_real(X[i]) for i=1:length(X) ]
function vcat_real(X::Any...)
    ## println(X[1])
    res = map(to_real, X)
    vcat(res...)
end

function create_sim(eq::EquationSet)
    # unknown_map holds a variable's symbol and an index into the
    # variable array.
    unknown_idx_map = Dict()  # symbol => index into y (or yp)
    unknown_map = Dict()      # symbol => the Unknown object
    discrete_map = Dict()     # symbol => the Discrete object
    y_map = Dict()           # index => the Unknown object
    yp_map = Dict()          # index => the DerUnknown object
    varnum = 1 # variable indicator position that's incremented
    
    # add_var add's a variable to the unknown_map if it isn't already
    # there. 
    function add_var(v) 
        if !has(unknown_idx_map, v.sym)
            # Account for the length and fundamental size of the object
            len = length(v.value) * int(sizeof([v.value][1]) / 8)  
            idx = len == 1 ? varnum : (varnum:(varnum + len - 1))
            unknown_idx_map[v.sym] = idx
            varnum = varnum + len
        end
    end
    
    # The replace_unknowns method replaces Unknown types with
    # references to the positions in the y or yp vectors.
    replace_unknowns(a) = a
    replace_unknowns{T}(a::Array{T,1}) = map(replace_unknowns, a)
    function replace_unknowns(a::Expr)
        ret = copy(a)
        ret.args = replace_unknowns(ret.args)
        ret
    end
    function replace_unknowns(a::Unknown)
        if isequal(a.sym, :time)
            return :(t[1])
        end
        add_var(a)
        unknown_map[a.sym] = a
        y_map[unknown_idx_map[a.sym]] = a
        if isreal(a.value)
            :(ref(y, ($(unknown_idx_map[a.sym]))))
        else
            :(from_real(ref(y, ($(unknown_idx_map[a.sym]))), $(a.value)))
        end
    end
    function replace_unknowns(a::DerUnknown) 
        add_var(a)
        unknown_map[a.parent.sym] = a.parent
        y_map[unknown_idx_map[a.parent.sym]] = a.parent
        yp_map[unknown_idx_map[a.sym]] = a
        :(ref(yp, ($(unknown_idx_map[a.sym]))))
    end
    function replace_unknowns(a::Discrete)
        discrete_map[a.sym] = a
        :(ref($(a.sym), 1))
    end
    # In assigned variables (LeftVar), use SubArrays (sub), instead of ref.
    function replace_unknowns(a::LeftVar)
        var = replace_unknowns(a.var)
        :(sub($(var.args[2]), $(var.args[3])))
    end
    
    # eq_block should be just expressions suitable for eval'ing.
    eq_block = replace_unknowns(eq.equations)
    ev_block = replace_unknowns(eq.events)
    
    # Set up a master function with variable declarations and 
    # functions that have access to those variables.
    #
    # Variable declarations are for Discrete variables. Each
    # is stored in its own array, so it can be overwritten by
    # reinit.
    discrete_defs = reduce((x,y) -> :($x;$(y[1]) = [$(y[2].value)]), :(), discrete_map)
    # The following is a code block (thunk) for insertion into
    # the residual calculation function.
    resid_thunk = Expr(:call, append({:vcat_real}, eq_block), Any)
    # Same but for the root crossing function:
    event_thunk = Expr(:call, append({:vcat_real}, ev_block), Any)

    to_thunk(ex::Vector{Expr}) = reduce((x,y) -> :($x;$y), :(), ex)
    to_thunk(ex::Expr) = ex

    ev_pos_array = Expr[]
    ev_neg_array = Expr[]
    for idx in 1:length(eq.events)
        ex = to_thunk(replace_unknowns(eq.pos_response[idx]))
        push(ev_pos_array, 
             quote
                 (t, y, yp) -> begin $ex; return; end
             end)
        ex = to_thunk(replace_unknowns(eq.neg_response[idx]))
        push(ev_neg_array, 
             quote
                 (t, y, yp) -> begin $ex; return; end
             end)
    end
    ev_pos_thunk = length(ev_pos_array) > 0 ? Expr(:call, append({:vcat}, ev_pos_array), Any) : Function[]
    ev_neg_thunk = length(ev_neg_array) > 0 ? Expr(:call, append({:vcat}, ev_neg_array), Any) : Function[]
    
    get_discretes_thunk = :(() -> 1)   # dummy function for now

    # The framework for the master function defined
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
    vp_fun = eval(expr)
    ## global _resid_thunk = copy(resid_thunk)  # debugging
    ## global _expr = copy(expr)
    ## global _ev_pos = copy(ev_pos_thunk)
    ## global _ev_neg = copy(ev_neg_thunk)
    
    function fill_from_map(default_val, N, the_map, f)
        x = fill(default_val, N)
        for (k,v) in the_map
            x[ [k] ] = f(v)
        end
        x
    end
    N_unknowns = varnum - 1
    y0 = fill_from_map(0.0, N_unknowns, y_map, x -> to_real(x.value))
    yp0 = fill_from_map(0.0, N_unknowns, yp_map, x -> to_real(x.value))
    id = fill_from_map(-1, N_unknowns, yp_map, x -> 1)
    outputs = fill_from_map("", N_unknowns, y_map, x -> x.label)
    
    Sim(vp_fun(), y0, yp0, id, outputs, discrete_map, y_map, yp_map, eq)
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
    info[11] = 1    # calc initial conditions
    ## info[18] = 2    # more initialization info
    
    function setup_sim(sm::Sim, tstart::Float64, tstop::Float64, Nsteps::Int)
        global __sim_structural_change = false
        N = [int32(length(sm.y0))]
        t = [tstart]
        y = copy(sm.y0)
        yp = copy(sm.yp0)
        nrt = [int32(length(sm.F.event_pos))]
        rpar = [0.0]
        rtol = [0.0]
        atol = [1e-3]
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
        if t[1] > tstop
            break
        end
        ## if t[1] > 0.018     #### DEBUG
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
                    println("structural change event found at t = $(t[1]), restarting")
                    # Put t, y, and yp values back into original equations:
                    for (k,v) in sm.y_map
                        v.value = y[k]
                    end
                    for (k,v) in sm.yp_map
                        v.value = yp[k]
                    end
                    MTime.value = t[1]
                    # Reflatten equations
                    sm = create_sim(elaborate(sm.eq.original))
                    ## global _sm = copy(sm)
                    # Restart the simulation:
                    simulate = setup_sim(sm, t[1], tstop, int(Nsteps * (tstop - t[1]) / tstop))
                    yidx = map((s) -> s != "", sm.outputs)
                    info[1] = 0
                elseif any(jroot != 0)
                    println("event found at t = $(t[1]), restarting")
                    info[1] = 0
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
## PROBABLY BROKEN                    ##
########################################


# the following is needed:
# load("winston.jl")

function wplot( sm::SimResult, filename::String, args... )
    N = length( sm.colnames )
    a = FramedArray( N, 1 )
    setattr( a, "xlabel", "Time (s)" )
    setattr( a, "ylabel", "" )
    setattr( a, "cellspacing", 1. )
    for plotnum = 1:N
        add( a[plotnum,1], Curve(sm.y[:,1],sm.y[:, plotnum + 1]) )
        add( a[plotnum,1], "ylabel", sm.colnames[plotnum] )
        # setattr( a[plotnum,1], "title", sm.colnames[plotnum] )
    end
    file( a, filename, args... )
end



########################################
## Utilities                          ##
########################################

keys(d::Dict) = [k for (k, v) in d]
vals(d::Dict) = [v for (k, v) in d]
        
