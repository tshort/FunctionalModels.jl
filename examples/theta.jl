
#
# An implementation of the Ermentrout-Kopell neuron model.
#

using Grid
using Sims
using Winston

tend = 1000.0
dt   = 0.1

alpha = 0.012
beta  = 0.001

# y = sort (map (Poisson (100), Array(Float64, tend/dt)))
# yi = InterpGrid(y, BCnil, InterpLinear)


function Theta(theta,input)
    {
     der(theta) - (1 - cos(theta) + alpha * (1 + cos(theta)) * input(value(MTime)))
     
     Event(theta-pi,
          {
           reinit(theta, theta-2*pi)
           },    # positive crossing
          {})

    }
end


function In(time)
  return sin (beta * time)
end


function ThetaCircuit()
    theta = Unknown(0.0, "theta")
   {
     Theta(theta, In)
   }
end


theta   = ThetaCircuit()    # returns the hierarchical model
theta_f = elaborate(theta)    # returns the flattened model
theta_s = create_sim(theta_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
theta_yout = sunsim(theta_s, tend) 

#plot (theta_yout.y[:,1], theta_yout.y)
plot (theta_yout.y[:,1], theta_yout.y[:,2])
