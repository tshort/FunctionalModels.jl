
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
            () -> LeakyIaF())
    end
    
end


function LeakyIaF()

   v = Unknown(vreset, "v")   
   @equations begin
        StructuralEvent(v-theta,
                        # when v crosses the threshold,
                        # switch to refractory mode
            Subthreshold(v),
            () -> begin
                trefr = value(MTime)+trefractory
                Refractory(v,trefr)
            end)
   end
end


iaf   = LeakyIaF()      # returns the hierarchical model
iaf_f = elaborate(iaf)    # returns the flattened model
iaf_s = create_sim(iaf_f) # returns a "Sim" ready for simulation

tf = 0.1
dt = 0.025

function init (i)
    println ("init: ", i)
    iaf_ptr = setup_sunsim (iaf_s, 1e-6, 1e-6)

    return (i,iaf_s,iaf_ptr)
end

function iafsim (x::(Int64,Sims.SimState,Sims.SimSundials))
    i = x[1]
    iaf_s = x[2]
    iaf_ptr = x[3]
    println ("iafsim: ", i)

    # runs the simulation and returns
    # the result as an array plus column headings
    iaf_yout = sunsim(iaf_ptr, tf, int(tf/dt))

    return iaf_yout
end

    
inits = map(init, 1:12500)
@time map(iafsim, inits)


## plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

