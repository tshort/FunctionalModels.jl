
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

# Note: Gaston hasn't been "modularized", yet.
function gplot(sm::SimResult)
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
function gplot(sm::SimResult, filename::ASCIIString)
    set_filename(filename)
    plot(sm)
    printfigure("pdf")
end


########################################
## Basic plotting with Winston        ##
########################################


# the following is needed:
# load("winston.jl")

## function wplot( sm::SimResult, filename::String, args... )
##     N = length( sm.colnames )
##     a = FramedArray( N, 1, "", "" )
##     setattr( a, "xlabel", "Time (s)" )
##     setattr( a, "ylabel", " Y " )
##     ## setattr(a, "tickdir", +1)
##     ## setattr(a, "draw_spine", false)
##     for plotnum = 1:N
##         add( a[plotnum,1], Curve(sm.y[:,1],sm.y[:, plotnum + 1]) )
##         setattr( a[plotnum,1], "ylabel", sm.colnames[plotnum] )
##     end
##     file( a, filename, args... )
##     a
## end

function wplot( sm::SimResult, filename::String, args... )
    N = length( sm.colnames )
    a = Winston.Table( N, 1 )
    for plotnum = 1:N
        p = Winston.FramedPlot()
        add( p, Winston.Curve(sm.y[:,1],sm.y[:, plotnum + 1]) )
        Winston.setattr( p, "ylabel", sm.colnames[plotnum] )
        a[plotnum,1] = p
    end
    Winston.file( a, filename, args... )
    a
end

function wplot( sm::SimResult )
    N = length( sm.colnames )
    a = Winston.Table( N, 1 )
    for plotnum = 1:N
        p = Winston.FramedPlot()
        add( p, Winston.Curve(sm.y[:,1],sm.y[:, plotnum + 1]) )
        Winston.setattr( p, "ylabel", sm.colnames[plotnum] )
        a[plotnum,1] = p
    end
    dev = Tk.TkRenderer("plot", w, h)
    Winston.page_compose(self, dev, false)
    dev.on_close()
    Tk.tk( a, 800, 600 )
end
