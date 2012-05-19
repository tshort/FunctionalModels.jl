
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
v_y = sim(v_s, 10.0)  # run the simulation to 10 seconds and return
stophere()


########################################
## Test of the simulator with events  ##
## Van Der Pol oscillator             ##
## By hand formulation                ##
########################################

function vp_fun()
    mu = 1.0   # This is a discrete variable we will change
    function resid(t, y, yp)
        [yp[1] - (mu * (1 - y[2]^2) * y[1] - y[2]),
         yp[2] - y[1]]
    end
    function event_at(t, y, yp)
        [ sin(pi/2 * t[1]) ]     # Initiate an event every 2 sec.
    end
    function event_pos(t, y, yp)
        mu = mu * 0.75
        yp[1] = (mu * (1 - y[2]^2) * y[1] - y[2])
        yp[2] = y[1]
        return
    end
    function event_neg(t, y, yp)
        mu = mu * 1.8
        yp[1] = (mu * (1 - y[2]^2) * y[1] - y[2])
        yp[2] = y[1]
        return
    end
    function get_discretes()
        (["mu"], [mu])
    end
    SimFunctions(resid, event_at, [event_pos], [event_neg], get_discretes)
end

vanderpol = Sim(
    vp_fun(),  
    [0, 1.0],   # y start values
    [-1.0, 0],  # yp start values
    ones(2),    # 0 for algebraic, 1 for differential
    ["x", "y"],
    {"mu" => Discrete(:mu, 1.0, "mu")}
)


v_yout = sim(vanderpol, 10.)
plot(v_yout)
stophere()

# push(LOAD_PATH, "/home/tshort/julia/julia/extras/gaston-0.3")
# load("gaston.jl")
plot(v_yout)
plot(v_yout.y[:,1], v_yout.y[:,2])
plot(v_yout.y[:,2], v_yout.y[:,3])



