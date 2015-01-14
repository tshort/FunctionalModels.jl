



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

[Sims/src/utils.jl:110](https://github.com/tshort/Sims.jl/tree/558b12477832ec70e2baee9b22bfbfb2b68aae57/src/utils.jl#L110)




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

[Sims/src/utils.jl:149](https://github.com/tshort/Sims.jl/tree/558b12477832ec70e2baee9b22bfbfb2b68aae57/src/utils.jl#L149)



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

[Sims/src/utils.jl:175](https://github.com/tshort/Sims.jl/tree/558b12477832ec70e2baee9b22bfbfb2b68aae57/src/utils.jl#L175)




# Miscellaneous




## @unknown

A macro to ease entry of many unknowns.

```julia
@unknown a1 a2 a3 ...
```

### Arguments

* `a` : various representations of Unknowns:
  * `symbol`: equivalent to `symbol = Unknown()`
  * `symbol(val)`: equivalent to `symbol = Unknown(symbol, val)`
  * `symbol(x, y, z)`: equivalent to `symbol = Unknown(x, y, z)`

For `symbol(

### Effects

Creates one or more Unknowns


[Sims/src/utils.jl:221](https://github.com/tshort/Sims.jl/tree/558b12477832ec70e2baee9b22bfbfb2b68aae57/src/utils.jl#L221)



## check

Prints the number of equations and the number of unknowns.

```julia
name(x)
```

### Arguments

* `x` : a Model, EquationSet, or Sim

### Returns

* `::Void`

[Sims/src/utils.jl:260](https://github.com/tshort/Sims.jl/tree/558b12477832ec70e2baee9b22bfbfb2b68aae57/src/utils.jl#L260)

