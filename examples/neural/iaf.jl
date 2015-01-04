
## Simple integrate-and-fire example to illustrate integrating over
## discontinuities.

using Sims
using Winston

gL     = 0.2 
vL     = -70.0 
Isyn   = 20.0 
C      = 1.0 
theta  = 25.0 
vreset = -65.0 
trefractory = 5.0 

function LeakyIaF()

    v   = Unknown(vreset, "v")   
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        der(v) = ( ((- gL) * (v - vL)) + Isyn) / C

        Event(v-theta,
             Equation[
              reinit(v, vreset)
              ],    # positive crossing
             Equation[])

     end
    
end

iaf   = LeakyIaF()      # returns the hierarchical model
iaf_f = elaborate(iaf)    # returns the flattened model
iaf_s = create_sim(iaf_f) # returns a "Sim" ready for simulation

tf = 100.0
dt = 0.025

iaf_ptr = setup_sunsim (iaf_s, reltol=1e-7, abstol=1e-7)

# runs the simulation and returns
# the result as an array plus column headings
iaf_yout = sunsim(iaf_ptr, tf, int(tf/dt))

plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

