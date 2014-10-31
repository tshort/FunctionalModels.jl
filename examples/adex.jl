
## Adaptive exponential integrate-and-fire neuron.

using Sims
using Winston

const C     = 200.0 
const gL    =  10.0 
const EL    = -58.0 
const VT    = -50.0 
const Delta = 2.0 
const theta = 0.0 
const trefractory = 0.25

const a     =   2.0 
const tau_w =  120.0 
const b     =  100.0 
const Vr    = -46.0 

const Isyn  =  210.0

function AdEx()

    V   = Unknown(Vr, "V")   
    W   = Unknown(Vr, "W")   
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(V) - (( ((- gL) * (V - EL)) +
                (gL * Delta * (exp ((V - VT) / Delta))) +
                (- W) + Isyn) / C)
     der(W) - (((a * (V - EL)) - W) / tau_w)

     Event(V-theta,
          {
           reinit(V, Vr)
           },    # positive crossing
          {})

     }
    
end

adex   = AdEx()      # returns the hierarchical model
adex_f = elaborate(adex)    # returns the flattened model
adex_s = create_sim(adex_f) # returns a "Sim" ready for simulation
adex_ptr = setup_sunsim (adex_s, 1e-7, 1e-7)

tf = 80.0
dt = 0.025

# runs the simulation and returns
# the result as an array plus column headings
adex_yout = sunsim(adex_ptr, adex_s, tf, int(tf/dt))

plot (adex_yout.y[:,1], adex_yout.y[:,2])

