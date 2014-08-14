
## Modular integrate-and-fire model with synaptic dynamics.

using Sims
using Winston

gL     = 0.2 
vL     = -70.0 
Isyn   = 20.0 
C      = 1.0 
theta  = 25.0 
vreset = -65.0 
trefractory = 5.0


vsyn  = 80.0
alpha = 1.0
beta  = 0.25
gsmax = 0.1
taus  = 2.0
f     = -25.0
s0    = 0.5

function LeakyIaF(V,Isyn)

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(V) - (( ((- gL) * (V - vL)) + Isyn) / C)

     Event(V-theta,
          {
           reinit(V, vreset)
           },    # positive crossing
          {})

     }
    
end

function Syn(V,Isyn,spike)

    S  = Unknown ("S")
    SS = Unknown ("SS")
    gsyn = Unknown ()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(S)  - (alpha * (1 - S) - beta * S)
     der(SS) - ((s0 - SS) / taus)
     
     Isyn - (gsyn * (V - vsyn))
     gsyn - (gsmax * S * SS)

     Event(spike,
          {
           reinit(SS, SS + f * (1 - SS))
          },
          {})
     Event(V-theta,
          {
           reinit(S, 0.0)
           reinit(SS, 0.0)
          },
          {})
     }
    
end


function Circuit()
    V     = Voltage (-65.0, "V")
    Isyn  = Unknown ("Isyn")
    Isyn1 = Unknown ()
   {
    LeakyIaF(V,Isyn)
    Syn(V,Isyn1,MTime - 1.25)
    Isyn - Isyn1
   }
end


iaf   = Circuit()      # returns the hierarchical model
iaf_f = elaborate(iaf)    # returns the flattened model
iaf_s = create_sim(iaf_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
iaf_yout = sunsim(iaf_s, 80.0) 

plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

