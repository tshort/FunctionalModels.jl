



# Simulations

Various functions for simulations and building simulation objects from models.




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

[Sims/src/simcreation.jl:97](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/simcreation.jl#L97)



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

[Sims/src/simcreation.jl:141](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/simcreation.jl#L141)



## dasslsim

The solver that uses DASKR, a variant of DASSL.

See [sim](#sim) for the interface.

[Sims/src/dassl.jl:56](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/dassl.jl#L56)



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

[Sims/src/elaboration.jl:69](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/elaboration.jl#L69)



## sunsim

The solver that uses Sundials.

See [sim](#sim) for the interface.

[Sims/src/sundials.jl:109](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/sundials.jl#L109)



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

[Sims/src/sim.jl:92](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/sim.jl#L92)



## EquationSet

A representation of a flattened model, normally created with
`elaborate(model)`. `sim` uses an elaborated model for simulations.

Contains the hierarchical equations, flattened equations, flattened
initial equations, events, event response functions, and a map of
Unknown nodes.

[Sims/src/elaboration.jl:20](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/elaboration.jl#L20)



## Sim

A type for holding several simulation objects needed for simulation,
normally created with `create_sim(eqs)`. 

[Sims/src/simcreation.jl:42](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/simcreation.jl#L42)



## SimFunctions

The set of functions used in the DAE solution. Includes an initial set
of equations, a residual function, and several functions for detecting
and responding to events.

All functions take (t,y,yp) as arguments. {TODO: is this still right?}

[Sims/src/simcreation.jl:24](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/simcreation.jl#L24)



## SimResult

A type holding simulation results from `sim`, `dasslsim`, or
`sunsim`. Includes a matrix of results and a vector of column names.

[Sims/src/simcreation.jl:427](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/simcreation.jl#L427)



## SimState

The top level type for holding all simulation objects needed for
simulation, including a Sim. Normally created with
`create_simstate(sim)`.

[Sims/src/simcreation.jl:70](https://github.com/tshort/Sims.jl/tree/41fa42185a92c02017ceab02d9b448fb8286c66e/src/simcreation.jl#L70)

