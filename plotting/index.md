---
layout: default
title:  Sims plotting
---

# Plotting Sims Results

The following describes several ways to plot results from Sims. Note
that because Gadfly, PyPlot, and Winston all define `plot`, the plot
methods below are written out to avoid conflicts.

## Gadfly

[Gadfly](http://gadflyjl.org) works well with Sims results. Sims
includes a basic Gadfly.plot method:

```julia
using Sims
z = sim(Sims.Examples.Basics.Vanderpol(), 50.0)

using Gadfly

Gadfly.plot(z)
```

For more control, convert to a DataFrame, and use Gadfly
directly. Here is an example showing how to plot each signal in a
separate frame.

Note that Gadfly works better with "long" DataFrames rather than
"wide" DataFrames, so a "melted" DataFrame is used.

```julia
using DataFrames

df = convert(DataFrame, z)
mdf = melt(df, :time)

Gadfly.plot(mdf, x = :time, y = :value, 
            ygroup = :variable, Geom.subplot_grid(Geom.line))
```

## PyPlot

[PyPlot](https://github.com/stevengj/PyPlot.jl) is another good
option. Here is a basic plot:

```julia
using Sims
z = sim(Sims.Examples.Lib.CauerLowPassAnalog(), 60.0)

using PyPlot

figure()
PyPlot.plot(z.y[:,1], z.y[:,2], label = "n1")
PyPlot.plot(z.y[:,1], z.y[:,3], label = "n4")
legend(loc = 1)
```

Here is a way to plot all columns:

```julia
figure()
for i in 1:length(z.colnames)
    PyPlot.plot(z.y[:,1], z.y[:,i+1], label = z.colnames[i])
end
legend(loc = 1)
xlabel("Time, sec")
title("Model results")
```

Here's a way to plot each channel in its own subplot:

```julia
figure()
for i in 1:length(z.colnames)
    subplot(length(z.colnames), 1, i, sharex = true)
    PyPlot.plot(z.y[:,1], z.y[:,i+1])
    ylabel(z.colnames[i])
end
xlabel("Time, sec")
suptitle("Model results")
```

DataFrames can make it easier to refer to columns by names:

```julia
using DataFrames

d = convert(DataFrame, z)

figure()
PyPlot.plot(d[:time], d[:n4])
legend(loc = 1)
xlabel("time")
ylabel("n4")
title("Model results")
```

If you have [pandas](http://pandas.pydata.org), that's also useful for
plotting multiple columns. The `[:plot]` is a method of the DataFrame
object.

```julia
using PyCall
@pyimport pandas

pd = pandas.DataFrame(z.y[:,2:end], z.y[:,1], columns = z.colnames)

figure()
pd[:plot]()
```

Here's an example using subplots:

```julia
figure()
pd[:plot](subplots = true)
```

## Winston

Sims provides basic [Winston](https://github.com/nolta/Winston.jl)
support that shows each data column in a frame. Here is an example:

```julia
using Sims
using Winston
z = sim(Sims.Examples.Basics.Vanderpol(), 50.0)

wplot(z)
```



