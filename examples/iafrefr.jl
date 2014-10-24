
## Integrate-and-fire example with refractory period.

using Sims
using Winston

gL     = 0.2 
vL     = -70.0 
Isyn   = 20.0 
C      = 1.0 
theta  = 25.0 
vreset = -65.0 
trefractory = 5.0 

function Subthreshold(v)

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(v) - (( ((- gL) * (v - vL)) + Isyn) / C)
    }
    
end


function RefractoryEq(v)
    {
     v - vreset
    }
end    

function Refractory(v,trefr)
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    println (trefr)
    {
     StructuralEvent(MTime - trefr,
                     # when the end of refractory period is reached,
                     # switch back to subthreshold mode
         RefractoryEq(v),
         () -> LeakyIaF())
    }
    
end


function LeakyIaF()

    v   = Unknown(vreset, "v")   
   {
     StructuralEvent(v-theta,
                     # when v crosses the threshold,
                     # switch to refractory mode
         Subthreshold(v),
         () -> begin
             trefr = value(MTime)+trefractory
             Refractory(v,trefr)
         end)
   }
end


iaf   = LeakyIaF()      # returns the hierarchical model
iaf_f = elaborate(iaf)    # returns the flattened model
iaf_s = create_sim(iaf_f) # returns a "Sim" ready for simulation

tf = 800.0
dt = 0.025

iaf_ptr = setup_sunsim (iaf_s, 1e-6, 1e-6)

# runs the simulation and returns
# the result as an array plus column headings
iaf_yout = sunsim(iaf_ptr, iaf_s, tf, int(tf/dt))

plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

