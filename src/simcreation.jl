
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

@doc """
The set of functions used in the DAE solution. Includes an initial set
of equations, a residual function, and several functions for detecting
and responding to events.

All functions take (t,y,yp) as arguments. {TODO: is this still right?}
""" ->
type SimFunctions
    resid::Function           
    init::Function           
    event_at::Function          # Returns a Vector of root-crossing values. 
    event_pos::Vector{Function} # Each function is to be run when a
                                #   positive root crossing is detected.
    event_neg::Vector{Function} # Each function is to be run when a
                                #   negative root crossing is detected.
    get_discretes::Function     # Placeholder for a function to return
                                #   discrete values.
end
SimFunctions(resid::Function, event_at::Function,
             event_pos::Vector{None}, event_neg::Vector{None},
             get_discretes::Function) = 
    SimFunctions(resid, event_at, Function[], Function[], Function[], get_discretes)

@doc """
A type for holding several simulation objects needed for simulation,
normally created with `create_sim(eqs)`. 
""" ->
type Sim
    eq::EquationSet           # the input
    F::SimFunctions
    id::Array{Int, 1}         # indicates whether a variable is algebraic or differential
    outputs::Array{ASCIIString, 1} # output labels
    unknown_idx_map::Dict     # symbol => index into y (or yp)
    discrete_map::Dict        # sym => Discrete variable 
    parameter_idx_map::Dict   # symbol => index into parameters
    y_map::Dict               # sym => Unknown variable 
    yp_map::Dict              # sym => DerUnknown variable 
    parameter_map::Dict       # sym => Parameter
    varnum::Int               # variable indicator position that's incremented
    paramnum::Int             # parameter indicator position that's incremented
    abstol::Float64           # absolute error tolerance
    reltol::Float64           # relative error tolerance
    Sim(eq::EquationSet) = new(eq)
end

type SimStateHistory
    t::Dict # time
    x::Dict # variable values
end

@doc """
The top level type for holding all simulation objects needed for
simulation, including a Sim. Normally created with
`create_simstate(sim)`.
""" ->
type SimState
    t::Array{Float64, 1}      # time
    y0::Array{Float64, 1}     # state vector
    yp0::Array{Float64, 1}    # derivatives vector
    p::Array{Float64, 1}      # parameters vector
    structural_change::Bool
    history::SimStateHistory
    sm::Sim # reference to a Sim
end

@doc* """
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
""" ->
function create_sim(eq::EquationSet)
    
    sm = Sim(eq)
    sm.varnum = 1
    sm.paramnum = 1
    sm.parameter_idx_map = Dict()
    sm.unknown_idx_map = Dict()
    sm.discrete_map = Dict()
    sm.y_map = Dict()
    sm.yp_map = Dict()
    sm.parameter_map = Dict()
    sm.F = setup_functions(sm)  # Most of the work's done here.
    N_unknowns = sm.varnum - 1
    N_params = sm.paramnum - 1
    
    sm.outputs = fill_from_map("", N_unknowns, sm.y_map, x -> x.label)
    sm.id = fill_from_map(-1, N_unknowns, sm.yp_map, x -> 1)
    sm.abstol = 1e-4
    sm.reltol = 1e-4

    sm
end
create_sim(m::Model) = create_sim(elaborate(m))

@doc* """
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
""" ->
function create_simstate (sm::Sim)

    N_unknowns = sm.varnum - 1
    N_params = sm.paramnum - 1

    t = [0.0]
    y0 = fill_from_map(0.0, N_unknowns, sm.y_map, x -> to_real(x.value))
    yp0 = fill_from_map(0.0, N_unknowns, sm.yp_map, x -> to_real(x.value))
    p = fill_from_map(0.0, N_params, sm.parameter_map, x -> to_real(x.value))
    structural_change = false
    history = SimStateHistory (Dict(),Dict())
    for (k,v) in sm.y_map
        if v.save_history
            history.t[k] = Any[]
            history.x[k] = Any[]
        end
    end
    ss = SimState (t,y0,yp0,p,structural_change,history,sm)
    
    ss
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

cmb(x, args...) = Expr(x, args...)

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
    in_block = replace_unknowns(sm.eq.initialequations, sm)
    eq_block = replace_unknowns(sm.eq.equations, sm)
    ev_block = replace_unknowns(sm.eq.events, sm)

    # Set up a master function with variable declarations and 
    # functions that have access to those variables.
    #
    # The following is a code block (thunk) for insertion into
    # the residual calculation function.
    resid_thunk = Expr(:call, :(Sims.vcat_real), eq_block...)
    # Same but for the root crossing function:
    event_thunk = Expr(:call, :(Sims.vcat_real), ev_block...)
    # Same but for the initial equations:
    init_thunk = Expr(:call, :(Sims.vcat_real), in_block...)

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
        push!(ev_pos_array, 
             quote
                 (t, y, yp, p, ss) -> begin $ex; return; end
             end)
        ex = to_thunk(replace_unknowns(sm.eq.neg_responses[idx], sm))
        push!(ev_neg_array, 
             quote
                 (t, y, yp, p, ss) -> begin $ex; return; end
             end)
    end
    ev_pos_thunk = length(ev_pos_array) > 0 ? Expr(:call, :vcat, ev_pos_array...) : Function[]
    ev_neg_thunk = length(ev_neg_array) > 0 ? Expr(:call, :vcat, ev_neg_array...) : Function[]

    get_discretes_thunk = :(() -> 1)   # dummy function for now

    # Variable declarations are for Discrete variables. Each is stored
    # in its own array, so it can be overwritten by reinit. From the
    # discrete_map Dict, y[1] is the key (symbol name), and y[2] is
    # the value (type Discrete).
    discrete_defs = :()
    for (k, v) in sm.discrete_map
        # println("k", k)
        if length(v.hookex) == 0
            ex = :($k = Sims.DiscreteVar($v))
        else
            funs = map(x -> :(() -> $(replace_unknowns(x, sm))), v.hookex)
            funs = cmb(:vcat, funs...)
            ex = :($k = Sims.DiscreteVar($v, $funs))
        end
        discrete_defs = :($discrete_defs; $ex)
    end

    _sim_resid_name = gensym ("_sim_resid")
    _sim_init_name = gensym ("_sim_init")
    _sim_event_at_name = gensym ("_sim_event_at")
    _sim_event_pos_array_name = gensym ("_sim_event_pos_array")
    _sim_event_neg_array_name = gensym ("_sim_event_neg_array")
    _sim_get_discretes_name = gensym ("_sim_get_discretes")
    
    #
    # The framework for the master function defined. Each "thunk" gets
    # plugged into a function which is evaluated.
    #
    expr = quote
            # Note: this was originally a closure, but it was converted
            # to eval globally for two reasons: (1) performance and (2) so
            # cfunction could be used to set up Julia callbacks. This does
            # mean that the _sim_* functions are seen globally.
            $discrete_defs
            function $_sim_resid_name (t, y, yp, p, r)
                 ##@show y
                 ## @show length(y)
                 ##@show p
                 a = $resid_thunk
                 ## @show a
                 ## @show length(a)
                 r[1:end] = a
                 nothing
            end
            function $_sim_init_name (t, y, yp, p, r)
                 a = $init_thunk
                 ##@show a
                 ##dump(a)
                 r[1:end] = a
                 nothing
            end
            function $_sim_event_at_name (t, y, yp, p, r)
                 r[1:end] = $event_thunk
                 nothing
            end
            $_sim_event_pos_array_name = $ev_pos_thunk
            $_sim_event_neg_array_name = $ev_neg_thunk
            function $_sim_get_discretes_name ()
                 $get_discretes_thunk
                 nothing
            end
        () -> begin
            Sims.SimFunctions($_sim_resid_name, $_sim_init_name,
                              $_sim_event_at_name, $_sim_event_pos_array_name,
                              $_sim_event_neg_array_name, $_sim_get_discretes_name)
        end
    end

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

# adds a variable to the unknown_idx_map if it isn't already
# there. 
function add_var(v, sm) 
    if !haskey(sm.unknown_idx_map, v.sym)
        # Account for the length and fundamental size of the object
        len = length(v.value) * int(sizeof([v.value][1]) / 8)  
        idx = len == 1 ? sm.varnum : (sm.varnum:(sm.varnum + len - 1))
        sm.unknown_idx_map[v.sym] = idx
        sm.varnum = sm.varnum + len
    end
end

# adds a parameter to the parameter_idx_map if it isn't already
# there. 
function add_param(v, sm) 
    if !haskey(sm.parameter_idx_map, v.sym)
        # Account for the length and fundamental size of the object
        len = length(v.value) * int(sizeof([v.value][1]) / 8)  
        idx = len == 1 ? sm.paramnum : (sm.paramnum:(sm.paramnum + len - 1))
        sm.parameter_idx_map[v.sym] = idx
        sm.paramnum = sm.paramnum + len
    end
end

# The replace_unknowns method replaces Unknown types with
# references to the positions in the y or yp vectors.
replace_unknowns(a, sm::Sim) = a
replace_unknowns(a::Array{Any,1}, sm::Sim) = map(x -> replace_unknowns(x, sm), a)
replace_unknowns(e::Expr, sm::Sim) = Expr(e.head, replace_unknowns(e.args, sm)...)
function replace_unknowns(a::Unknown, sm::Sim)
    if isequal(a.sym, :time)
        return :(t[1])
    end
    add_var(a, sm)
    sm.y_map[sm.unknown_idx_map[a.sym]] = a
    if isreal(a.value) && ndims(a.value) < 2
        :(getindex(y, ($(sm.unknown_idx_map[a.sym]))))
    else
        :(from_real(getindex(y, ($(sm.unknown_idx_map[a.sym]))), $(basetypeof(a.value)), $(size(a.value))))
    end
end
function replace_unknowns(a::RefUnknown, sm::Sim) # handle array referencing
    add_var(a.u, sm)
    sm.y_map[sm.unknown_idx_map[a.u.sym]] = a.u
    if isreal(a.u.value) && ndims(a.u.value) < 2
        :(getindex(y, ($(sm.unknown_idx_map[a.u.sym][a.idx...]))))
    else
        :(from_real(getindex(y, ($(sm.unknown_idx_map[a.u.sym]))), $(basetypeof(a.u.value)), $(size(a.u.value)))[$(a.idx...)])
    end
end
function replace_unknowns(a::DerUnknown, sm::Sim) 
    add_var(a, sm)
    sm.y_map[sm.unknown_idx_map[a.parent.sym]] = a.parent
    sm.yp_map[sm.unknown_idx_map[a.sym]] = a
    if isreal(a.value) && ndims(a.value) < 2
        :(getindex(yp, ($(sm.unknown_idx_map[a.sym]))))
    else
        :(from_real(getindex(yp, ($(sm.unknown_idx_map[a.sym]))), $(basetypeof(a.value)), $(size(a.value))))
    end
end
function replace_unknowns(a::PassedUnknown, sm::Sim)
    a.ref
end
function replace_unknowns(a::Discrete, sm::Sim)
    # println(a.sym)
    sm.discrete_map[a.sym] = a
    :(($(a.sym)).value)
end
function replace_unknowns(a::RefDiscrete, sm::Sim) # handle array referencing
    sm.discrete_map[a.u.sym] = a.u
    :(getindex(($(a.u.sym)).value, a.idx))
end
# In assigned variables (LeftVar), use SubArrays (sub), instead of ref.
# This allows assignment.
function replace_unknowns(a::LeftVar, sm::Sim)
    if isa(a.var, Discrete)
        # println("D",a.var.sym)
        sm.discrete_map[a.var.sym] = a.var
        :($(a.var.sym))
    elseif isa(a.var, Parameter)
        :(sub(p,$(sm.parameter_idx_map[a.var.sym]):$(sm.parameter_idx_map[a.var.sym])))
    else
        var = replace_unknowns(a.var, sm)
        :(sub($(var.args[2]), $(var.args[3]):$(var.args[3])))
    end
end
function replace_unknowns(a::Parameter, sm::Sim) 
    add_param(a, sm)
    sm.parameter_map[sm.parameter_idx_map[a.sym]] = a
    if isreal(a.value) && ndims(a.value) < 2
        :(getindex(p, ($(sm.parameter_idx_map[a.sym]))))
    else
        :(from_real(getindex(p, ($(sm.parameter_idx_map[a.sym]))), $(basetypeof(a.value)), $(size(a.value))))
    end
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


@doc """
A type holding simulation results from `sim`, `dasslsim`, or
`sunsim`. Includes a matrix of results and a vector of column names.
""" ->
type SimResult
    y::Array{Float64, 2}
    colnames::Array{ASCIIString, 1}
end
getindex(x::SimResult, idx...) = SimResult(x.y[:,idx...], x.colnames[idx...])
