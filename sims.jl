
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
#   
# What's missing:
#   - Hybrid modeling (medium to hard difficulty to add)
#   - Discrete hard (medium to hard)
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

type DefaultUnknown <: UnknownCategory
end

type Unknown{T<:UnknownCategory} <: ModelType
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
    
type DerUnknown <: ModelType
    sym::Symbol
    value        # holds initial values
    # label::String    # Do we want this? 
end
DerUnknown() = DerUnknown(gensym(), 0.0)
DerUnknown(u::DerUnknown) = DerUnknown(gensym())
DerUnknown(u::Unknown) = DerUnknown(gensym(), u.value)
DerUnknown(x) = DerUnknown(gensym(), x)
der(x::Unknown) = DerUnknown(x.sym, x.value)
der(x::Unknown, val) = DerUnknown(x.sym, val)

# show(a::Unknown) = show(a.sym)

#
# A type for discrete variables. These are only changed during
# events. They are not used by the integrator.
#
type Discrete <: ModelType
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

type MSymbol <: ModelType
    sym::Symbol
end

for f = (:+, :-, :*, :.*, :/, :./, :^)
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

# Nodes are flows are Unknown's.
# Potential = Flow = Voltage = Current = Node = ElectricalNode = Unknown
# MTime = MSymbol(:t)
MTime = MExpr(:(t[1]))

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
## Elaboration / flattening           ##
########################################

#
# This converts a hierarchical model into a flat set of equations.
# 
# After elaboration, the following structure is returned.
#
type Event <: ModelType
    condition::MExpr
    pos_response::Function
    neg_response::Function
end
    
type EquationSet
    equations::Vector{Expr}
    events::Vector{Expr}
    responses::Vector{Expr}
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
    eventList = Event[]
    
    elaborate_unit(a::Any) = [] # The default is to ignore undefined types.
    elaborate_unit(a::ModelType) = a
    function elaborate_unit(a::Model)
        if (length(a) == 1)
            return(a)
        end
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
    
    function elaborate_unit(b::Event)
        push(eventList, b)
        {}
    end
    
    
    equations = elaborate_unit(copy(a))
    for (key, nodeset) in nodeMap
        push(equations, nodeset)
    end
    equations = convert(Vector{Expr}, map(strip_mexpr, equations))

    events = Expr[]
    pos_responses = Expr[]
    neg_responses = Expr[]
    for e in eventList
        push(events, strip_mexpr(e.condition))
        push(pos_responses, map(strip_mexpr, e.pos_response))
        push(neg_responses, map(strip_mexpr, e.neg_response))
    end
    
    EquationSet(equations, events, pos_responses, neg_responses)
end

# These methods strip the MExpr's from expressions.
strip_mexpr(a) = a
strip_mexpr(a::MExpr) = strip_mexpr(a.ex)
strip_mexpr(a::MSymbol) = a.sym 
function strip_mexpr(a::Expr)
    ret = copy(a)
    ret.args = map((x) -> strip_mexpr(x), ret.args)
    ret
end

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

## type Sim
##     F::Function  # the residual function
##     Fex::Expr    # the residual function expression
##     events::Function  # the event detection (root finding) function
##     event_responses::Vector{Function}  # responses after events detected (same length as above)
##     y0::Array{Float64, 1}   # initial values
##     yp0::Array{Float64, 1}  # initial values of derivatives
##     id::Array{Float64, 1}   # indicates whether a variable is algebraic or differential
##     outputs::Array{ASCIIString, 1} # output labels
##     discrete_map::Dict       # output labels for discrete variables
## end
type SimFunctions
    resid::Function
    event_at::Function
    event_pos::Vector{Function}
    event_neg::Vector{Function}
    get_discretes::Function
end

type Sim
    F::SimFunctions
    y0::Array{Float64, 1}   # initial values
    yp0::Array{Float64, 1}  # initial values of derivatives
    id::Array{Float64, 1}   # indicates whether a variable is algebraic or differential
    outputs::Array{ASCIIString, 1} # output labels
    discrete_map::Dict      # output labels for discrete variables
end

vcat_real(X::Any...) = [ to_real(X[i]) | i=1:length(X) ]
function vcat_real(X::Any...)
    res = map(to_real, X)
    vcat(res...)
end

function create_sim(eq::EquationSet)
    # unknown_map holds a variable's symbol and an index into the
    # variable array.
    unknown_map = Dict() 
    discrete_map = Dict() 
    y0_map = Dict() 
    discrete0_map = Dict() 
    yp0_map = Dict() 
    id_map = Dict() # indicator for algebraic vs. differential
    output_map = Dict() # for labeled unknowns
    doutput_map = Dict() # for labeled discretes
    varnum = 1 # variable indicator position that's incremented
    
    # add_var add's a variable to the unknown_map if it isn't already
    # there. 
    function add_var(v) 
        if !has(unknown_map, v.sym)
            # Account for the length and fundamental size of the object
            len = length(v.value) * int(sizeof([v.value][1]) / 8)  
            idx = len == 1 ? varnum : (varnum:(varnum + len - 1))
            unknown_map[v.sym] = idx
            varnum = varnum + len
        end
    end
    
    # The replace_unknowns method replaces Unknown types with
    # references to the positions in the y or yp vectors.
    replace_unknowns(a) = a
    function replace_unknowns(a::Expr)
        ret = copy(a)
        ret.args = map((x) -> replace_unknowns(x), ret.args)
        ret
    end
    function replace_unknowns(a::Unknown)
        add_var(a)
        y0_map[unknown_map[a.sym]] = a.value
        output_map[unknown_map[a.sym]] = a.label
        if isreal(a.value)
            :(ref(y, ($(unknown_map[a.sym]))))
        else
            :(from_real(ref(y, ($(unknown_map[a.sym]))), $(a.value)))
        end
    end
    function replace_unknowns(a::Discrete)
        doutput_map[a.sym] = a
        a.sym
    end
    function replace_unknowns(a::DerUnknown) 
        add_var(a)
        id_map[unknown_map[a.sym]] = true
        yp0_map[unknown_map[a.sym]] = a.value
        :(ref(yp, ($(unknown_map[a.sym]))))
    end
    
    # eq_block should be just expressions suitable for eval'ing.
    eq_block = map(replace_unknowns, eq.equations)
    ev_block = map(replace_unknowns, eq.events)
    rsp_block = map(replace_unknowns, eq.responses)
    
    N_unknowns = varnum - 1
    N_discrete = dvarnum - 1
    y0 = fill(0.0, N_unknowns)
    yp0 = fill(0.0, N_unknowns)
    id = fill(0.0, N_unknowns)
    outputs = fill("", N_unknowns)
    for (k,v) in y0_map
        y0[ [k] ] = to_real(v)
    end
    for (k,v) in yp0_map
        yp0[ [k] ] = to_real(v)
    end
    for (k,v) in id_map
        id[ [k] ] = v
    end
    for (k,v) in output_map
        outputs[k] = v
    end
    
    # body is a vector where each element is one of the equation
    # expressions.
    # vec = Expr(:vcat, eq_block, Any)
    vec = Expr(:call, append({:vcat_real}, eq_block), Any)
    Fex = :((t, y, yp, rpar) -> $vec)
    F = eval(Fex)
    evec = Expr(:call, append({:vcat_real}, ev_block), Any)
    event_expr = :((t, y, yp, rpar) -> $evec)
    events = eval(event_expr)
    event_responses = Function[]
    for r in rsp_block
        fun_ex = :((t, y, yp, rpar) -> $r)
        push(event_responses, eval(fun_ex))
    end

    # Set up a master function with variable declarations and 

    
    # Create the residual function
    # Finally, return the Sim with the residual function
    # initial values:
    Sim(F, Fex, events, event_responses, y0, yp0, id, outputs, discrete_map)
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
               
    N = [int32(length(sm.y0))]
    t = [0.0]
    y = copy(sm.y0)
    yp = copy(sm.yp0)
    nrt = [int32(length(sm.F.event_at(t, y, yp)))]
    rpar = [0.0]
    info = fill(int32(0), 20)
    info[18] = 2
    rtol = [0.0]
    atol = [1e-3]
    idid = [int32(0)]
    lrw = [int32(N[1]^2 + 9 * N[1] + 60 + 3 * nrt[1])] 
    rwork = fill(0.0, lrw[1])
    liw = [int32(N[1] + 40)] 
    iwork = fill(int32(0), liw[1])
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
    yidx = sm.outputs != ""
    yidx = map((s) -> s != "", sm.outputs)
    ## didx = sm.doutputs != ""
    ## didx = map((s) -> s != "", sm.doutputs)
    Noutputs = sum(yidx)
    ## Ndoutputs = length(didx) > 0 ? sum(didx) : 0
    ## Ncol = Noutputs + Ndoutputs
    Ncol = Noutputs
    
    yout = zeros(Nsteps, Ncol + 1)
    tstep = tstop / Nsteps
    tout = [tstep]

    for idx in 1:Nsteps
        ccall(dlsym(lib, :ddaskr_), Void,
              (Ptr{Void}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, # RES, NEQ, T, Y, YPRIME
               Ptr{Float64}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64},            # TOUT, INFO, RTOL, ATOL
               Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},                # IDID, RWORK, LRW, IWORK
               Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Void}, Ptr{Void},      # LIW, RPAR, IPAR, JAC, PSOL
               Ptr{Void}, Ptr{Int32}, Ptr{Int32}),                              # RT, NRT, JROOT
              callback, N, t, y, yp, tout, info, rtol, atol,
              idid, rwork, lrw, iwork, liw, rpar, ipar, jac, psol,
              rt, nrt, jroot)
        if idid[1] >= 0 && idid[1] <= 5
            yout[idx, 1] = t[1]
            yout[idx, 2:(Noutputs + 1)] = y[yidx]
            ## if Ndoutputs > 0
            ##     yout[didx, (Noutputs + 2):end] = rpar[didx]
            ## end
            tout = t + tstep
            if idid[1] == 5 # Event found
                for ridx in 1:length(jroot)
                    if jroot[ridx] == 1
                        sm.F.event_pos[ridx](t, y, yp)
                    elseif jroot[ridx] == -1
                        sm.F.event_neg[ridx](t, y, yp)
                    end
                end
                if any(jroot != 0)
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
