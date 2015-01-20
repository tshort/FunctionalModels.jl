using Sims
using Winston


########################################
## FitzHugh-Nagumo neuron model       ##
########################################

tend = 110.0

a = 0.7
b = 0.8
tau = 12.5

#
# A device model is a function that returns a list of equations or
# other devices that also return lists of equations. The equations
# each are assumed equal to zero. So,
#    der(y) = x + 1
# Should be entered as:
#    der(y) - (x+1)
#

function FitzHughNagumo(Iext)
    v = Unknown("v")   
    w = Unknown("w")        
    @equations begin
        der(v) = v - (v^3 / 3)  - w + Iext
        der(w) = (v + a - b * w) / tau
    end
end

v   = FitzHughNagumo(0.5)       # returns the hierarchical model
v_f = elaborate(v)    # returns the flattened model
v_s = create_sim(v_f) # returns a "Sim" ready for simulation

tf = 200.0
dt = 0.025

# runs the simulation and returns
# the result as an array plus column headings
@time v_yout = sunsim(v_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-7, abstol=1e-7)

plot (v_yout.y[:,1], v_yout.y[:,2])
