module Neural

using ....Sims
using ....Sims.Lib


@comment """
# Neural models

Examples using neural models.

These are available in **Sims.Examples.Neural**.
"""

include("lib.jl")

include("adex.jl")
include("fhn.jl")
include("iaf.jl")
include("iafrefr.jl")
include("izhfs.jl")
include("ekc.jl")
include("ml.jl")
include("hr.jl")
include("hh.jl")

include("hhmod.jl")
include("wb.jl")
include("CaT.jl")
include("pr.jl")
include("purkinje.jl")
include("cgc.jl")
include("cgoc.jl")

function run(model; dt = 0.025, tf = 100.0, reltol = 1e-6, abstol = 1e-6, alg = true)
    y = sunsim(model, tstop = tf, Nsteps = convert(Int,round(tf/dt)), reltol = reltol, abstol = abstol, alg = alg)
    return y
end

function runall()

    hh = HodgkinHuxley()
    y = run(hh, tf=500.0)
    
    fhn = FitzHughNagumo()
    y = run(fhn, tf=250.0)

    iaf = LeakyIaF()
    y = run(iaf, tf=100.0)

    iafrefr = RefractoryLeakyIaF()
    y = run(iafrefr, tf=100.0)

    adex = AdEx()
    y = run(adex, tf=80.0)
    
    izhfs = IzhikevichFS()
    y = run(izhfs, tf=80.0)
    
    ekc = ErmentroutKopell()
    y = run(ekc, tf=250.0)
    
    ml = MorrisLecar()
    y = run(ml, tf=250.0)

    hr = HindmarshRose()
    y = run(hr, tf=250.0)
    
    hh2 = HodgkinHuxleyModule.Main()
    y = run(hh2, tf=500.0)

    wb = WangBuzsaki.Main()
    y = run(wb, tf=500.0)
    
    cat = CaT.Soma()
    y = run(cat, tf=100.0)

    pr = PinskyRinzel.Circuit()
    y = run(pr, tf=500.0)

    cpc = Purkinje.Soma()
    y = run(cpc, reltol=1e-1, tf=500.0)

    cgc = CGC.Soma()
    y = run(cgc, tf=500.0)

    cgoc = CGoC.Soma()
    y = run(cgoc, tf=500.0)

end 

end # module

