@comment """
# Simulations

Various functions for simulations and building simulation objects from models.
"""


"""
`sim` is the name of the default solver used to simulate Sims models
and also shows the generic simulation API for available solvers
(currently `dasslsim` and `sunsim`). The default solver is currently
`dasslsim` if DASSL is available.

`sim` has many method definitions to accomodate solutions based on
intermediate model representations. Also, both positional and keyword
arguments are supported (use one or the other after the first
argument).

```julia
sim(m::Model, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)
sim(m::Model; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)
sim(m::Sim, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)
sim(m::Sim; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)
sim(m::SimState, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)
sim(m::SimState; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)
```

### Arguments

* `m::Model` : a Model
* `sm::Sim` : a simulation object
* `ss::SimState` : a simulation object
* `tstop::Float64` : the simulation stopping time [secs], default = 1.0
* `Nsteps::Int` : the number of simulation steps, default = 500
* `reltol::Float64` : the relative tolerance, default = 1e-4
* `abstol::Float64` : the absolute tolerance, default = 1e-4
* `init` : initialization of the model; options include:
  * `:none` : no initialization
  * `:Ya_Ydp` :  given `Y_d`, calculate `Y_a` and `Y'_d` (the default)
  * `:Y` :  given `Y'`, calculate `Y`
  * `alg` : indicates whether algebraic variables should be included in the error estimate (default is true)
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
"""
sim = sunsim

function defaultsim(f::Function)
    global sim = f
end
