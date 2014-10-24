
#
# An implementation of the Izhikevich Fast Spiking neuron model.
#

using Sims
using Winston

k     =   1.0
Vinit = -65.0
Vpeak =  25.0
Vt    = -55.0
Vr    = -40.0
Vb    = -55.0
Cm    =  20.0
Isyn  =   0.0
Iext  = 400.0

FS_a = 0.2
FS_b = 0.025
FS_c = -45.0
FS_U = FS_b * Vinit

function IzhikevichFS()

    v   = Unknown(-60.899, "v")   
    u   = Unknown(FS_U,  "u")
    s   = Unknown()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(v) - (((k * (v - Vr) * (v - Vt)) + (- u) + Iext) / Cm)
     der(u) - (FS_a * (s - u))
     s - (FS_b * (v - Vb) ^ 3)

     Event(v-Vpeak,
          {
           reinit(v, FS_c)
           },    # positive crossing
          {})

     }
    
end


izhfs   = IzhikevichFS()      # returns the hierarchical model
izhfs_f = elaborate(izhfs)    # returns the flattened model
izhfs_s = create_sim(izhfs_f) # returns a "Sim" ready for simulation

tf = 800.0
dt = 0.025

izhfs_ptr = setup_sunsim (izhfs_s, 1e-6, 1e-6)

# runs the simulation and returns
# the result as an array plus column headings
@time izhfs_yout = sunsim(izhfs_ptr, izhfs_s, tf, int(tf/dt))

plot (izhfs_yout.y[:,1], izhfs_yout.y[:,2])

