
using Sims
using Sims.Lib
using Gaston

## Wang, X.-J. and Buzsaki G. (1996) Gamma oscillations by synaptic
## inhibition in a hippocampal interneuronal network.
## J. Neurosci. 16, 6402-6413.

type UConductance <: UnknownCategory
end

typealias Gate Unknown{DefaultUnknown,NonNegative}
typealias Conductance Unknown{UConductance,NonNegative}

# Parameter values

I = 0.5

diam = 5.6419
L = 5.6419
area = pi * L * diam

C_m = 1

const E_Na = 55
const E_K  = -90
const E_L  = -65

        
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

    gbar_Na = Parameter(0.035)
    gbar_K  = Parameter(0.009)
    g_L     = Parameter(0.0001)

    I_Na = Current()
    I_K  = Current()
    I_L  = Current()

    g_Na = Conductance()
    g_K  = Conductance()
    
    @equations begin

        der(v) = ((I * (100.0 / area)) - 1e3 * (I_K + I_Na + I_L)) / C_m

        der(n) = 5.0 * (an(v)*(1-n) - bn(v)*n)
        der(h) = 5.0 * (ah(v)*(1-h) - bh(v)*h)

        g_Na = minf(v)^3 * h * gbar_Na
        g_K  = n^4 * gbar_K
    
        I_Na = g_Na * (v - E_Na)
        I_K  = g_K  * (v - E_K)
        I_L  = g_L  * (v - E_L)

        
    end
end



wb   = WB(I)  # returns the hierarchical model
wb_f = elaborate(wb)    # returns the flattened model
wb_s = create_sim(wb_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 500.0
dt = 0.025

@time wb_yout = sunsim(wb_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-4, abstol=1e-4)

plot (wb_yout.y[:,1], wb_yout.y[:,2])
