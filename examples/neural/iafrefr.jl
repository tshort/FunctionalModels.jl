
## Integrate-and-fire example with refractory period.


using Sims
using Winston

gL     = 0.1 
vL     = -70.0 
Isyn   = 10.0 
C      = 1.0 
theta  = 20.0 
vreset = -65.0 
trefractory = 5.0 

function Subthreshold(v)

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        der(v) = ( ((- gL) * (v - vL)) + Isyn) / C
    end
    
end


function RefractoryEq(v)
    @equations begin
        v = vreset
    end
end    

function Refractory(v,trefr)
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        StructuralEvent(MTime - trefr,
                        # when the end of refractory period is reached,
                        # switch back to subthreshold mode
            RefractoryEq(v),
            () -> LeakyIaF(trefr))
    end
    
end


function LeakyIaF(trefr)

    v = Unknown(vreset, "v")   
    Equation[                     # BUG: This doesn't work right with @equations
        StructuralEvent(v-theta,
                        # when v crosses the threshold,
                        # switch to refractory mode
            Subthreshold(v),
            () -> begin
                trefr = value(MTime)+trefractory
                Refractory(v,trefr)
            end)
    ]
end


iaf   = LeakyIaF(0.0)      # returns the hierarchical model
iaf_f = elaborate(iaf)    # returns the flattened model

tf = 1200.0
dt = 0.025

iaf_s = create_sim(iaf_f) # returns a "Sim" ready for simulation

iaf_ptr = setup_sunsim (iaf_s, 1e-6, 1e-6)

# runs the simulation and returns
# the result as an array plus column headings
@time iaf_yout = sunsim(iaf_ptr, tf, int(tf/dt))

plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

