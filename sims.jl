
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
#   
# What's missing:
#   - Scopes or variable labeling or other ways to tell what the
#     output is.
#   - Hybrid modeling (medium to hard difficulty to add)
#   - Discrete hard (medium to hard)
#   - Initial equations (medium difficulty)
#   - Causal relationships or input/outputs (?)
#   - Metadata like variable name, units, and annotations (hard?)
#   - Complex numbers or other complicated data types as unknowns
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
#   - No "scope" capability.
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
# From the user's point of view, the biggest issue is not having a
# good mapping from unknown variables to columns in the solution
# array. Better naming of unknowns or some sort of "scope" feature are
# needed.
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

type Unknown{T} <: ModelType
    sym::Symbol
    placeholder::T   # could also hold initial values
end
Unknown() = Unknown{Float64}(gensym(), 0.0)
Unknown(u::Unknown) = Unknown(gensym(), u.placeholder .* 0.0)
Unknown(x) = Unknown{typeof(x)}(gensym(), x)
Unknown(s::Symbol, x) = Unknown{typeof(x)}(s, x)
sym = Unknown

is_unknown(x) = isa(x, Unknown)
    
type DerUnknown{T} <: ModelType
    sym::Symbol
    placeholder::T   # could also hold initial values
end
DerUnknown() = DerUnknown{Float64}(gensym(), 0.0)
DerUnknown(u::DerUnknown) = DerUnknown(gensym())
DerUnknown(u::Unknown) = DerUnknown(gensym(), u.placeholder)
DerUnknown(x) = DerUnknown{typeof(x)}(gensym(), x)
DerUnknown(s::Symbol, x) = DerUnknown{typeof(x)}(s, x)
der(x::Unknown) = DerUnknown(x.sym, x.placeholder)
der(x::Unknown, val) = DerUnknown(x.sym, val)

show(a::Unknown) = show(a.sym)
  
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

# Nodes are flows are Unknown's.
Potential = Flow = Voltage = Current = Node = ElectricalNode = Unknown
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


# 
# This needs something to better separate special constructs (like
# RefBranch). The accumulating and finalizing is tricky to separate.
# 
# There is no real symbolic processing (sorting, index reduction, or
# any of the other stuff a fancy modeling tool would do).
# 
function elaborate(a::Model)
    nodeMap = Dict()

    elaborate_unit(a::Any) = [] # The default is to ignore undefined types.
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
    
    elaborate_unit(a::ModelType) = a
    
    function node_sum_zero()
        res = {}
        for (key, nodeset) in nodeMap
            push(res, nodeset)
        end
        res
    end

    append(elaborate_unit(copy(a)), node_sum_zero())
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

type Sim
    F::Function  # the residual function
    Fex::Expr    # the residual function expression
    y0::Array{Float64, 1}   # initial values
    yp0::Array{Float64, 1}  # initial values of derivatives
    id::Array{Float64, 1}   # indicates whether a variable is algebraic or differential
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

function create_sim(a::Model)
    # unknown_map holds a variable's symbol and an index into the
    # variable array.
    unknown_map = Dict() 
    y0_map = Dict() 
    yp0_map = Dict() 
    id_map = Dict() # indicator for algebraic vs. differential
    varnum = 1 # variable indicator position that's incremented
    # add_var add's a variable to the unknown_map if it isn't already
    # there. 
    function add_var(v) 
        if !has(unknown_map, v.sym)
            len = length(v.placeholder)
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
        y0_map[unknown_map[a.sym]] = a.placeholder
        :(ref(y, ($(unknown_map[a.sym]))))
    end
    function replace_unknowns(a::DerUnknown) 
        add_var(a)
        id_map[unknown_map[a.sym]] = true
        yp0_map[unknown_map[a.sym]] = a.placeholder
        :(ref(yp, ($(unknown_map[a.sym]))))
    end
    # eq_block should be just expressions suitable for eval'ing.
    eq_block = map(replace_unknowns, map(strip_mexpr, copy(a)))
    N_unknowns = varnum - 1
    y0 = fill(0.0, N_unknowns)
    yp0 = fill(0.0, N_unknowns)
    id = fill(0.0, N_unknowns)
    for (k,v) in y0_map
        y0[k] = v
    end
    for (k,v) in yp0_map
        yp0[k] = v
    end
    for (k,v) in id_map
        id[k] = v
    end
    # body is a vector where each element is one of the equation
    # expressions.
    vec = Expr(:vcat, eq_block, Any)
    Fex = :((t, y, yp) -> $vec)
    F = eval(Fex)
    # Create the residual function
    # Finally, return the Sim with the residual function
    # initial values:
    # Sim(F, y0, yp0, id, 1.0, 500)
    # :((t, y, yp, res) -> begin res[:] = $vec; return; end)
    Sim(F, Fex, y0, yp0, id)
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
global __dassl_res_callback 
global __dassl_t  
global __dassl_y 
global __dassl_yp
global __dassl_res
ilib = dlopen("dassl_interface.so")  # Something went wrong when these were
lib = dlopen("dassl.so")             # inside the sim function.

function sim(sm::Sim, tstop::Float64, Nsteps::Int)
    # tstop & Nsteps should be in options
               
    N = [int32(length(sm.y0))]
    t = [0.0]
    y = copy(sm.y0)
    yp = copy(sm.yp0)
    info = fill(int32(0), 20)
    info[18] = 2
    rtol = [0.0]
    atol = [1e-3]
    idid = [int32(0)]
    lrw = [N[1]^2 + 9 * N[1] + 40] # from Octave
    # lrw = [max(N[1]^2 + 10*N[1], 2000)] # crude estimate
    rwork = fill(0.0, lrw[1])
    liw = [N[1] + 21] # from Octave
    # liw = [max(N[1]^2 + N[1], 2000)]
    iwork = fill(int32(0), liw[1])
    rpar = [0.0]
    # rpar = sm.F # attempt to pass in the julia residual function
    ipar = N
    jac = [int32(0)]
    psol = [int32(0)]
     
    # Set up the callback.
    callback = dlsym(ilib, :res_callback)
    global __dassl_res_callback = sm.F
    global __dassl_t = [0.0] 
    global __dassl_y = y
    global __dassl_yp = yp
    global __dassl_res = copy(y)
    yout = zeros(Nsteps, N[1] + 1)
    tstep = tstop / Nsteps
    tout = [tstep]

    for idx in 1:Nsteps
        ccall(dlsym(lib, :ddassl_), Void,
              (Ptr{Void}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, # RES, NEQ, T, Y, YPRIME
               Ptr{Float64}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64},            # TOUT, INFO, RTOL, ATOL
               Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},                # IDID, RWORK, LRW, IWORK
               Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Void}, Ptr{Void}),     # LIW, RPAR, IPAR, JAC, PSOL
              callback, N, t, y, yp, tout, info, rtol, atol,
              idid, rwork, lrw, iwork, liw, rpar, ipar, jac, psol)
        yout[idx, 1] = t[1]
        yout[idx, 2:end] = y
        tout = t + tstep
        if idid[1] < 0 && idid[1] > -11
            println("RESTARTING")
            info[1] = 0
            continue
        end
        if idid[1] < 0
            break
        end
    end
    yout
end
sim(sm::Sim) = sim(sm, 1.0, 500)
sim(sm::Sim, tstop::Float64) = sim(sm, tstop, 500)
sim(m::Model, tstop::Float64, Nsteps::Int)  = sim(create_sim(elaborate(m)), tstop, Nsteps)
sim(m::Model) = sim(m, 1.0, 500)
sim(m::Model, tstop::Float64) = sim(m, tstop, 500)



