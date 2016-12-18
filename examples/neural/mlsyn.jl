
#
# Morris-Lecar neuron model with synapse.
#

using Sims




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

# Synaptic parameters
vsyn  = 120.0
vt    = 20.0
vs    = 2.0
alpha = 100.0
beta  = 0.25
f     = -25.0

function minf (v)
    return (0.5 * (1.0 + tanh ((v - v1) / v2)))
end

function winf (v)
    return (0.5 * (1.0 + tanh ((v - v3) / v4)))
end

function lamw (v)
    return (phi * cosh ((v - v3) / (2.0 * v4)))
end
   

function MorrisLecar(v)

    w   = Unknown(0.305,  "w")
    ica = Unknown("ica")   
    ik  = Unknown("ik")   

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        der(v) = (Istim + (gl * (vl - v)) + ica + ik) / c
        der(w) = lamw (v) * (winf(v) - w)
        ica = gca * (minf (v) * (vca - v))
        ik  = gk * (w * (vk - v))
    end
end


function k_(v)
    return 1.0 / (1.0 + exp(-(v - vt) / vs))
end


function Syn(v,s)
    @equations begin
        der(s) = alpha * k_(v) * (1-s) - beta * s
    end
end    


function MLCircuit()
    s = Unknown(0.056, "s")
    v = Voltage(-24.22, "v")
    @equations begin
        Syn(v,s)
        MorrisLecar(v)
    end
end


ml   = MLCircuit()    # returns the hierarchical model
ml_f = elaborate(ml)    # returns the flattened model
ml_s = create_sim(ml_f) # returns a "Sim" ready for simulation

tf = 1000.0
dt = 0.025

# runs the simulation and returns
# the result as an array plus column headings
@time ml_yout = sunsim(ml_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-6, abstol=1e-6)

#plot (ml_yout.y[:,1], ml_yout.y)
plot (ml_yout.y[:,1], ml_yout.y[:,2])
