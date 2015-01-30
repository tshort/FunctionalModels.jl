
using SIUnits
using SIUnits.ShortUnits
using Distributions ## for Poisson random numbers

using Grid ## for interpolating grids
using Sims.Lib

## A helper routine for creating an interpolation grid from
## a Poisson process

function PoissonGrid(lambda,tf,dt,scale)
    
    p  = Poisson(lambda*tf)
    events = float(cumsum(rand(p,int(round(float((tf / scale) / (lambda * tf)))))))

    return EventGrid(events,float(tf/scale),float(dt/scale))
end
