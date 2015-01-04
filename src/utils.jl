
using Requires

########################################
## Model checks                       ##
########################################

# Compare the number of variables and the number of unknowns
function check(s::Sim)
    Nvar = length(s.y0)
    println("Number of floating point variables: ", Nvar)
    Neq = length(s.F.resid_check(Nvar))
    println("Number of equations: ", Neq)
end
check(e::EquationSet) = check(create_sim(e))
check(m::Model) = check(create_sim(elaborate(m)))


########################################
## Basic plotting with Gaston         ##
########################################

@require Gaston begin

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
    
    function _wplot(sm::SimResult)
        try
            N = length(sm.colnames)
            a = Winston.Table(N, 1)
            for plotnum = 1:N
                p = Winston.FramedPlot()
                add(p, Winston.Curve(sm.y[:,1],sm.y[:, plotnum + 1]))
                Winston.setattr(p, "ylabel", sm.colnames[plotnum])
                a[plotnum,1] = p
            end
            a
        end
    end
    
    function wplot(sm::SimResult, filename::String, args...)
        try
            a = _wplot(sm)
            Winston.file(a, filename, args...)
            a
        end
    end
    
    function wplot(sm::SimResult)
        try
            a = _wplot(sm)
            Winston.display(a)
            a
        end
    end
end

########################################
## DataFrames / Gadfly integration    ##
########################################

@require DataFrames begin

    function Base.convert(::Type{DataFrames.DataFrame}, x::SimResult)
        df = convert(DataFrames.DataFrame, x.y)
        DataFrames.names!(df, [:time, map(symbol, x.colnames)])
        df
    end

end

@require Gadfly begin

    function Gadfly.plot(x::SimResult, args...)
        Gadfly.plot(convert(DataFrames.DataFrame, x), args...)
    end

end

#
# @unknown
#
# A macro to ease entry of many unknowns.
#
#   @unknowns i("Load resistor current") v x("some val", 3.0)
#
# becomes:
#
#   i = Unknown(symbol("Load resistor current"))
#   v = Unknown(:v)
#   x = Unknown(symbol("some val"), 3.0) 
#

macro unknown(args...)
    blk = Expr(:block)
    for arg in args
        if isa(arg, Symbol)
            push!(blk.args, :($arg = Unknown($(Meta.quot(arg)), 0.0)))
        elseif isa(arg, Expr)
            name = arg.args[1]
            if length(arg.args) > 1
                newcall = copy(arg)
                newcall.args = [:Unknown, :($(Meta.quot(name))), newcall.args[2:end]]
                push!(blk.args, :($name = $newcall))
            else
                push!(blk.args, :($name = Unknown(name)))
            end
        end
    end
    push!(blk.args, :nothing)
    return esc(blk)
end
