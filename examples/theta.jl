
#
# An implementation of the Ermentrout-Kopell neuron model.
#

using Grid
using Sims
using Winston

y  = rand (100)-0.5
yi = InterpGrid(y, BCnil, InterpLinear)

alpha = 1.0
I = 0.01

function Theta(theta)
    {
     der(theta) - (1 - cos(theta) + alpha * (1 + cos(theta)) * I)
     
     Event(theta-pi,
          {
           reinit(theta, theta-2*pi)
           },    # positive crossing
          {})

    }
end

function ThetaCircuit()
    theta = Unknown(0.5, "theta")
   {
     Theta(theta)
   }
end


theta   = ThetaCircuit()    # returns the hierarchical model
theta_f = elaborate(theta)    # returns the flattened model
theta_s = create_sim(theta_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
theta_yout = sunsim(theta_s, 50.0) 

#plot (theta_yout.y[:,1], theta_yout.y)
plot (theta_yout.y[:,1], theta_yout.y[:,2])
