
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


function init (size)

    netiaf  = Equation[ LeakyIaF() for i = 1:size ]

    return netiaf
end

    
net = init(250)

tf = 1.0
dt = 0.25

yout = sunsim(net, tstop=tf, Nsteps=int(tf/dt))

## plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

