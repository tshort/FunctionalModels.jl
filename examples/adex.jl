
## Adaptive exponential integrate-and-fire neuron.

using Sims
using Winston

C     = 200.0 
gL    =  10.0 
EL    = -58.0 
VT    = -50.0 
Delta = 2.0 
theta = 0.0 
trefractory = 0.25

a     =   2.0 
tau_w =  120.0 
b     =  100.0 
Vr    = -46.0 

Isyn  =  210.0

function AdEx()

    V   = Unknown(vreset, "V")   
    W   = Unknown(vreset, "W")   
    
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

# runs the simulation and returns
# the result as an array plus column headings
adex_yout = sunsim(adex_s, 80.0) 

plot (adex_yout.y[:,1], adex_yout.y[:,2])

