



# Utilities

The API for simulating models and converting models to simulation objects. 





# Winston plotting




## wplot

Plot the simulation result with Winston (must be installed and
loaded).

```julia
wplot(sm::SimResult, filename::String, args...)
wplot(sm::SimResult)
```

### Arguments

* `sm::SimResult` : the simulation result
* `filename::ASCIIString` : the filename
* `args...` : extra arguments passed to `Winston.file()`

If `filename` is not give, plot interactively.

### Returns

* A Winston object

[Sims/src/utils.jl:110](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/utils.jl#L110)




# DataFrames and Gadfly




## convert(::Type{DataFrame}, x::SimResult)

Convert to a DataFrame.

```julia
Base.convert(::Type{DataFrames.DataFrame}, x::SimResult)
```

### Arguments

* `x::SimResult` : a simulation result

### Returns

* `::DataFrame` : a DataFrame with the first column as `:time` and
  remaining columns with simulation results.

[Sims/src/utils.jl:149](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/utils.jl#L149)



## plot

Plot the simulation result with Gadfly (must be installed and
loaded).

```julia
plot(sm::SimResult, args...)
```

### Arguments

* `sm::SimResult` : the simulation result

### Returns

* A Gadfly object

[Sims/src/utils.jl:175](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/utils.jl#L175)




# Miscellaneous




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

### Effects

Creates one or more Unknowns

* A Gadfly object

[Sims/src/utils.jl:220](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/utils.jl#L220)



## check

Prints the number of equations and the number of unknowns.

```julia
name(x)
```

### Arguments

* `x` : a Model, EquationSet, or Sim

### Returns

* `::Void`

[Sims/src/utils.jl:259](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/utils.jl#L259)

