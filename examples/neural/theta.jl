
#
# An implementation of the Ermentrout-Kopell neuron model.
#

using Sims
using Winston

alpha = 0.012
beta  = 0.01


function Theta(theta)
    @equations begin
        der(theta) = 1 - cos(theta) + alpha * (1 + cos(theta)) * sin(beta * MTime)
        
        Event(theta-pi,
             Equation[
                 reinit(theta, theta-2*pi)
             ],    # positive crossing
             Equation[])

    end
end


function ThetaCircuit()
    theta = Unknown(1.0, "theta")
    Theta(theta)
end


theta   = ThetaCircuit()    # returns the hierarchical model
theta_f = elaborate(theta)    # returns the flattened model
theta_s = create_sim(theta_f) # returns a "Sim" ready for simulation

tf = 1000.0
dt = 0.1

theta_ptr = setup_sunsim (theta_s, reltol=1e-7, abstol=1e-7)

# runs the simulation and returns
# the result as an array plus column headings
@time theta_yout = sunsim(theta_ptr, tf, int(tf/dt))

#plot (theta_yout.y[:,1], theta_yout.y)
plot (theta_yout.y[:,1], theta_yout.y[:,2])
