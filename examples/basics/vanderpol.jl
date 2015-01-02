using Sims
using Winston

########################################
## Van Der Pol oscillator             ##
########################################

#
# Tom Short, tshort@epri.com
#
#
# Copyright (c) 2012, Electric Power Research Institute 
# BSD license - see the LICENSE file
# 



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

function Vanderpol()
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    @equations begin
     # The -1.0 in der(x, -1.0) is the initial value for the derivative 
     der(x, -1.0) - ((1 - y^2) * x - y) # == 0 is assumed
     der(y) - x
    end
end

v = Vanderpol()       # returns the hierarchical model
v_f = elaborate(v)    # returns the flattened model
v_s = create_sim(v_f) # returns a "Sim" ready for simulatio

tf = 50.0
dt = 0.025

@time v_yout = sunsim(v_s, tf, int(tf/dt))

figure()
p1 = plot(v_yout.y[:,1], v_yout.y[:,2])
display(p1)

figure()
# plot the signals against each other:
p2 = plot(v_yout.y[:,2], v_yout.y[:,3])
display(p2)

