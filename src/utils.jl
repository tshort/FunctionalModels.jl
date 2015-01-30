
using Requires

@comment """
# Utilities

The API for simulating models and converting models to simulation objects. 
"""

    


########################################
## Basic plotting with Gaston         ##
########################################


@require Gaston begin

    @comment """
    # Gaston plotting
    """
    
    @doc* """

    Plot the simulation result with Gaston (must be installed and
    loaded).
    
    ```julia
    gplot(sm::SimResult)
    gplot(sm::SimResult, filename::ASCIIString)
    ```
    
    ### Arguments
    
    * `sm::SimResult` : the simulation result
    * `filename::ASCIIString` : the filename
    
    ### Returns
    
    * `::Void`  (??)
    """ ->
    function gplot(sm::SimResult)
        N = length(sm.colnames)
        figure()
        c = Gaston.CurveConf()
        a = Gaston.AxesConf()
        a.title = ""
        a.xlabel = "Time (s)"
        a.ylabel = ""
        Gaston.addconf(a)
        for plotnum = 1:N
            c.legend = sm.colnames[plotnum]
            Gaston.addcoords(sm.y[:,1],sm.y[:, plotnum + 1],c)
        end
        Gaston.llplot()
    end
    function gplot(sm::SimResult, filename::ASCIIString)
        Gaston.set_filename(filename)
        gplot(sm)
        Gaston.printfigure("pdf")
    end

end


########################################
## Basic plotting with Winston        ##
########################################

    
@require Winston begin
    
    @comment """
    # Winston plotting
    """
    
    function _wplot(sm::SimResult)
            N = length(sm.colnames)
            a = Winston.Table(N, 1)
            for plotnum = 1:N
                p = Winston.FramedPlot()
                Winston.add(p, Winston.Curve(sm.y[:,1],sm.y[:, plotnum + 1]))
                Winston.setattr(p, "ylabel", sm.colnames[plotnum])
                a[plotnum,1] = p
            end
            a
    end
    
    @doc* """
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
    """ ->
    function wplot(sm::SimResult, filename::String, args...)
            a = _wplot(sm)
            Winston.file(a, filename, args...)
            a
    end
    
    function wplot(sm::SimResult)
            a = _wplot(sm)
            Winston.display(a)
            a
    end
end

########################################
## DataFrames / Gadfly integration    ##
########################################

@comment """
# DataFrames and Gadfly
"""
    
@require DataFrames begin

    @doc """
    Convert to a DataFrame.
    
    ```julia
    Base.convert(::Type{DataFrames.DataFrame}, x::SimResult)
    ```
    
    ### Arguments
    
    * `x::SimResult` : a simulation result

    ### Returns
    
    * `::DataFrame` : a DataFrame with the first column as `:time` and
      remaining columns with simulation results.
    """ ->
    function Base.convert(::Type{DataFrames.DataFrame}, x::SimResult)
        df = convert(DataFrames.DataFrame, x.y)
        DataFrames.names!(df, [:time, map(symbol, x.colnames)])
        df
    end

end

@require Gadfly begin

    @doc* """
    Plot the simulation result with Gadfly (must be installed and
    loaded).
    
    ```julia
    plot(sm::SimResult, args...)
    ```
    
    ### Arguments
    
    * `sm::SimResult` : the simulation result

    ### Returns
    
    * A Gadfly object
    """ ->
    function Gadfly.plot(x::SimResult)
        Gadfly.plot(DataFrames.melt(convert(DataFrames.DataFrame, x), :time),
                    x = :time, y = :value, color = :variable, Gadfly.Geom.line)
    end

end

########################################
## PyPlot plotting                    ##
########################################

@comment """
# PyPlot
"""
    
@require PyPlot begin

    @doc* """
    Plot simulation result with PyPlot (must be installed and
    loaded).
    
    ```julia
    PyPlot.plot(z::SimResult,
                columns = [1:length(z.colnames)];
                title = "",
                subplots = :auto,
                newfigure::Bool = true,
                legend = :auto)
    ```
    
    ### Arguments
    
    * `z::SimResult` : the simulation result
    * `columns` : columns to plot; defaults to all; can be Int,
      String, Range, Arrays, or Regexs.

    ### Keyword arguments
    
    * `title` : a string to print at the top of the plot
    * `subplots` : whether to plot columns in subplots; options are:
      * `true` : use subplots
      * `false` : don't use subplots
      * `:auto` : use subplots if column has a length less than or equal to 6
    * `newfigure::Bool` : show a new figure
    * `legend` : whether to show legends
      * `true` : use legends
      * `false` : don't use legends
      * `:auto` : use legends if there is more than one column per subplot

    ### Returns
    
    * `nothing`

    ### Details

    The `columns` argument allows you to specify which columns to plot and in which subplot. Options are:

    * `Range` or `array` : if `subplot == true`, each entry in the array
      is plotted in its own subplot. Arrays can contain Ints, Strings,
      Tuples, Regexs, or Arrays.
    * `Int` : column position
    * `String` : column name
    * `Regex` : expands based on column name matches

    For three subplots, here is an example:

    ```julia
    plot(z,
         ["V1",          # 1st subplot: column V1
          ("Vx", "Vy"),  # 2nd subplot: columns Vx and Vy
          r"^I.*"],      # 3rd subplot: all columns starting with I
         subplots = true)
    ```

    ### Examples

    ```julia
    using Sims
    z = sim(Sims.Examples.Lib.CauerLowPassOPV2(), 60.0)
    
    using PyPlot
    plot(z)
    plot(z, [1:length(z.colnames)])
    plot(z, r".*", title = "CauerLowPassOPV")
    plot(z, subplots = true, title = "subplots = true")
    plot(z, 9:11, subplots = false, title = "subplots = false")
    plot(z, r"n", title = "r\"n\"")
    plot(z, r"n1", title = "r\"n1\"")
    plot(z, 5:8, legend = false)
    figure()
    plot(z, 5:8, legend = false, newfigure = false)
    plot(z, ["n8", "n9"], title = string(["n8", "n9"]))
    plot(z, [("n8", "n9"), ("n10", "n11")], title = string([("n8", "n9"), ("n10", "n11")]))
    plot(z, [r"n1", ("n9", "n10")], title = string([r"n1", ("n9", "n10")]))
    
    ```
    
    """ ->
    function PyPlot.plot(z::SimResult,
                         columns = [1:length(z.colnames)];
                         title = "",
                         subplots = :auto,
                         newfigure::Bool = true,
                         legend = :auto)
        newfigure && PyPlot.figure()
        columns = getcols(z, columns)
        if subplots == :auto
            subplots = length(columns) <= 6
        end
        @show columns
        if !subplots
            for c in columns
                for i in c
                    PyPlot.plot(z.y[:,1], z.y[:,i+1], label = z.colnames[i])
                end
            end
            legend in [true, :auto] && PyPlot.legend(loc = "best")
        else
            PyPlot.subplots_adjust(hspace=0.001)
            for i in 1:length(columns)
                PyPlot.subplot(length(columns), 1, i)  #, sharex = true)
                for j in columns[i]
                    PyPlot.plot(z.y[:,1], z.y[:,j+1], label = z.colnames[j])
                end
                PyPlot.margins(0, 0.05)
                if length(columns[i]) > 1 && legend in [true, :auto]
                    PyPlot.legend(loc = "best")
                else
                    PyPlot.ylabel(z.colnames[columns[i]])
                end
                ## PyPlot.yaxis.set_label_coords(labelx, 0.5)
            end
        end
        PyPlot.xlabel("Time, sec")
        PyPlot.suptitle(title)
    end
    getcols(z::SimResult, x::Real) = x
    getcols(z::SimResult, s::String) = indexin([s], z.colnames)[1]
    getcols(z::SimResult, v::Union(Range, Vector, Set, Tuple)) = [getcols(z, x) for x in v]
    function getcols(z::SimResult, r::Regex)
        res = Int[]
        for i in 1:length(z.colnames)
            ismatch(r, z.colnames[i]) && push!(res, i)
        end
        length(res) == 1 ? res[1] : res
    end
end
    
@comment """
# Miscellaneous
"""
    
#
# @unknown
#
# A macro to ease entry of many unknowns.
#
#   @unknowns i("Load resistor current") v x(3.0, "some val")
#
# becomes:
#
#   i = Unknown("Load resistor current")
#   v = Unknown()
#   x = Unknown(3.0, "some val") 
#

@doc """
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

""" ->
macro unknown(args...)
    blk = Expr(:block)
    for arg in args
        if isa(arg, Symbol)
            push!(blk.args, :($arg = Unknown()))
        elseif isa(arg, Expr)
            name = arg.args[1]
            if length(arg.args) > 1
                newcall = copy(arg)
                newcall.args = [:Unknown, newcall.args[2:end]]
                push!(blk.args, :($name = $newcall))
            else
                push!(blk.args, :($name = Unknown()))
            end
        end
    end
    push!(blk.args, :nothing)
    return esc(blk)
end

########################################
## Model checks                       ##
########################################

@doc* """
Prints the number of equations and the number of unknowns.

```julia
check(x)
```

### Arguments

* `x` : a Model, EquationSet, Sim, or SimState

### Returns

* `Nvar` : Number of floating point variables
* `Neq` : Number of equations

""" ->
function check(s::Sim)
    Nvar = length(s.y0)
    Neq = length(s.F.resid_check(Nvar))
    Nvar, Neq
end
check(s::SimState) = check(s.sm)
check(e::EquationSet) = check(create_sim(e))
check(m::Model) = check(create_sim(elaborate(m)))


########################################
## Model initiation                   ##
########################################

import JuMP

@doc* """
Experimental function to initialize models.

```julia
initialize!(ss::SimState)
```

### Arguments

* `ss::SimState` : the SimState to be initialized

### Returns

* `::JuMP.Model`

### Details

`initialize!` updates `ss.y0` and `ss.yp0` with values that
satisfy the initial equations. If it does not converge, a warning
is printed, and `ss` is not changed.

`JuMP.jl` must be installed along with a nonlinear solver like
`Ipopt.jl` or `NLopt.jl`. The JuMP model is set up without an
objective function. Linear equality constraints are added for each
`fixed` variable. Nonlinear equality constraints are added for
each equation in the model (with some additional checking work,
some of these could probably be converted to linear constraints).

Also, `initialize!` only works for scalar models. Models with Unknown
vector components don't work. Internally, `.*` is replaced with
`*`. It's rather kludgy, but right now, JuMP doesn't support `.*`. A
better approach might be to fully flatten the model.

`initialize!` only runs at the beginning of simulations. It does not
run after Events.

""" ->
function initialize!(ss::SimState)
    sm    = ss.sm
    m = JuMP.Model()
    n = length(ss.y0)
    JuMP.@defVar(m, y[1:n])
    JuMP.@defVar(m, yp[1:n])
    eq = ss.sm.eq.initialequations
    exv = Sims.replace_unknowns(eq, sm)
    for i in 1:n
        JuMP.setValue(y[i], ss.y0[i])
        JuMP.setValue(yp[i], ss.yp0[i])
        ## Add constraints for the fixed variables and derivatives
        if sm.yfixed[i]
            JuMP.@addConstraint(m, y[i] == ss.y0[i])
        end
        if sm.ypfixed[i]
            JuMP.@addConstraint(m, yp[i] == ss.yp0[i])
        end
        ex = exv[i]
        if Meta.isexpr(ex, :call) && ex.args[1] == :(-) && length(ex.args) == 3
            ex.args[1] = :(==)
            ex = Expr(:comparison, ex.args[2], :(==), ex.args[3])
        else
            ex = Expr(:comparison, 0.0, :(==), ex)
        end
        ex = cleanexpr(ex)
        ## Add a constraint for each equation in the system
        ## kludgy way to run JuMP's macro!
        eval(:( using Base.Operators; _f(y, yp, m) = JuMP.@addNLConstraint(m, $ex) ))
        _f(y, yp, m)
    end
    global _m = m
    r = JuMP.solve(m)
    if r == :Optimal
        ss.y0[:] = JuMP.getValue(y)[:]
        ss.yp0[:] = JuMP.getValue(yp)[:]
        return m
    else
        println("Initial value solution failed")
    end
end

cleanexpr(x) = x
cleanexpr(x::UnknownReactive) = value(x)
function cleanexpr(e::Expr)
    if e.head == :call && e.args[1] == :getindex
        e.head = :ref
        e.args = e.args[2:end]
    elseif e.head == :call && e.args[1] == :value
        return cleanexpr(e.args[2])
    elseif e.head == :call && e.args[1] == :.*
        e.args[1] = :*
    end
    Expr(e.head, map(cleanexpr, e.args)...)
end

