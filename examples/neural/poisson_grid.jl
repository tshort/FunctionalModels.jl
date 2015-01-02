
using SIUnits
using SIUnits.ShortUnits
using Distributions ## for Poisson random numbers
using Grid ## for interpolating grids

function search_grid (g::InterpGrid, x::Float64)
    i = searchsortedfirst (g, x)
    g[i]
end

function grid_point (x::Float64, v::Float64)
    x - v
end

## A helper routine for creating an interpolation grid from
## a Poisson process

function poisson_grid(lambda,tf,dt,scale)
    
    p  = Poisson(lambda*tf)
    events = float(cumsum(rand(p,int(round(float((tf / scale) / (lambda * tf)))))))

    g0 = InterpGrid(events, 0.0, InterpNearest)

    x = 0.0:float(dt / scale):float(tf / scale)
    y = map (x -> let v = search_grid (g0, x); grid_point (x,v) end, x)

    g = CoordInterpGrid (x,y,BCperiodic,InterpQuadratic)
    
    return g
end
