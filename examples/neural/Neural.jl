module Neural

using ....Sims
using ....Sims.Lib
using Docile
using Requires
@document

@comment """
# Neural models

Examples using neural models.

These are available in **Sims.Examples.Neural**.
"""

include("adex.jl")
include("hh.jl")
include("fhn.jl")
include("iaf.jl")
include("izhfs.jl")
include("ekc.jl")
include("ml.jl")

function run(model; dt = 0.025, tf = 100.0, reltol = 1e-6, abstol = 1e-6)
    y = sunsim(model, tstop = tf, Nsteps = int(tf/dt), reltol = reltol, abstol = abstol)
    return y
end

function runall()

    hh = HodgkinHuxley()
    y = run(hh, tf=500.0)
    
    fhn = FitzHughNagumo()
    y = run(fhn, tf=250.0)

    iaf = LeakyIaF()
    y = sunsim(iaf, tf=100.0)

    adex = AdEx()
    y = sunsim(adex, tf=80.0)
    
    izhfs = IzhikevichFS()
    y = sunsim(izhfs, tf=80.0)
    
    ekc = ErmentroutKopell()
    y = sunsim(ekc, tf=250.0)
    
    ml = MorrisLecar()
    y = sunsim(ml, tf=250.0)
    
end 

@require Gaston begin
    function plotrun(model; dt = 0.025, tf = 100.0, reltol = 1e-6, abstol = 1e-6)
        y = run(model, dt=dt, tf=tf, reltol=reltol, abstol=abstol)
        gplot(y)
        return y
    end
end

end # module

