
#
# An implementation of the Morris-Lecar neuron model.
#

using Sims
using Winston


Istim =  50.0
c   =   20.0
vk  =  -70.0
vl  =  -50.0
vca =  100.0
gk  =    8.0
gl  =    2.0
gca =    4.0
v1  =   -1.0
v2  =   15.0
v3  =   10.0
v4  =   14.5
phi =   0.0667


function minf (v)
    return (0.5 * (1.0 + tanh ((v - v1) / v2)))
end

function winf (v)
    return (0.5 * (1.0 + tanh ((v - v3) / v4)))
end

function lamw (v)
    return (phi * cosh ((v - v3) / (2.0 * v4)))
end
  	                   


function MorrisLecar()

    v   = Unknown(-60.899, "v")   
    w   = Unknown(0.0149,  "w")
    ica = Unknown("ica")   
    ik  = Unknown("ik")   

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        der(v) = (Istim + (gl * (vl - v)) + ica + ik) / c   # == 0 is assumed
        der(w) = lamw (v) * (winf(v) - w)
        ica = gca * (minf (v) * (vca - v))
        ik  = gk * (w * (vk - v))
    end
end


ml   = MorrisLecar()    # returns the hierarchical model
ml_f = elaborate(ml)    # returns the flattened model
ml_s = create_sim(ml_f) # returns a "Sim" ready for simulation

tf = 1000.0
dt = 0.025

ml_ptr = setup_sunsim (ml_s, reltol=1e-6, abstol=1e-6)

# runs the simulation and returns
# the result as an array plus column headings
@time ml_yout = sunsim(ml_ptr, tf, int(tf/dt))

plot (ml_yout.y[:,1], ml_yout.y[:,2])
