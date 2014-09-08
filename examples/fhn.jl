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
# The Van Der Pol oscillator is a simple problem with two equations
# and two unknowns:

function FitzHughNagumo(Iext)
    v = Unknown("v")   
    w = Unknown("w")        
    {
     der(v) - (v - (v^3 / 3)  - w + Iext) # == 0 is assumed
     der(w) - (v + a - b * w) / tau
     }
end

v   = FitzHughNagumo(0.5)       # returns the hierarchical model
v_f = elaborate(v)    # returns the flattened model
v_s = create_sim(v_f) # returns a "Sim" ready for simulatio

v_yout = sunsim(v_s, tend) 

plot (v_yout.y[:,1], v_yout.y[:,2])
