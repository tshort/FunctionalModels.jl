using Sims
using Winston

########################################
## Test of the simulator with events  ##
## Van Der Pol oscillator             ##
## Automatic formulation              ##
########################################


function SVanderpol()
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
    mu_unk = Unknown(1.0, "mu_unk") 
    mu = Discrete(1.0, "mu")
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    {
     # The -1.0 in der(x, -1.0) is the initial value for the derivative 
     der(x, -1.0) - (mu * (1 - y^2) * x - y) # == 0 is assumed
     der(y) - x
     mu_unk - mu
     Event(sin(pi/2 * MTime),     # Initiate an event every 2 sec.
           {
            reinit(mu, mu * 0.75)
           },
           {
            reinit(mu, mu * 1.8)
           })
    }
end

v = SVanderpol()      # returns the hierarchical model
v_f = elaborate(v)    # returns the flattened model
v_s = create_sim(v_f) # returns a "Sim" ready for simulation

v_ptr = setup_sunsim (v_s, 1e-6, 1e-6)

tf = 10.0
dt = 0.025

@time v_yout = sunsim(v_ptr, tf, int(tf/dt))

figure()
p1 = plot(v_yout.y[:,1], v_yout.y[:,2])
display(p1)

figure()
# plot the signals against each other:
p2 = plot(v_yout.y[:,2], v_yout.y[:,3])
display(p2)


