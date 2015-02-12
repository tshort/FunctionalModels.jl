
using Sims
using Sims.Lib
using Gaston

## Wang, X.-J. and Buzsaki G. (1996) Gamma oscillations by synaptic
## inhibition in a hippocampal interneuronal network.
## J. Neurosci. 16, 6402-6413.


# Parameter values

I = 0.5

minf(v)=am(v)/(am(v)+bm(v))
am(v)=0.1*(v+35.0)/(1.0-exp(-(v+35.0)/10.0))
bm(v)=4.0*exp(-(v+60.0)/18.0)
ah(v)=0.07*exp(-(v+58.0)/20.0)
bh(v)=1.0/(1.0+exp(-(v+28.0)/10.0))
an(v)=0.01*(v+34.0)/(1.0-exp(-(v+34.0)/10.0))
bn(v)=0.125*exp(-(v+44.0)/80.0)


function WB(I)

    v   = Unknown(-20.0, "v")
    h   = Unknown(0.283, "h")
    n   = Unknown(0.265, "n")
    
    @equations begin
        
        der(v) = -0.1 * (v + 65) - 35.0 * minf(v)^3 * h * (v - 55) - 9 * n^4 * (v + 90) + I
        der(n) = 5.0 * (an(v)*(1-n) - bn(v)*n)
        der(h) = 5.0 * (ah(v)*(1-h) - bh(v)*h)
   
    end
end



wb   = WB(I)  # returns the hierarchical model
wb_f = elaborate(wb)    # returns the flattened model
wb_s = create_sim(wb_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 250.0
dt = 0.025

@time wb_yout = sunsim(wb_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-4, abstol=1e-4)

plot (wb_yout.y[:,1], wb_yout.y[:,2])
