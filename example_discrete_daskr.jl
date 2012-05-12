
########################################
## Test of the simulator with events  ##
## Van Der Pol oscillator             ##
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







########################################
## Manual circuit example             ##
########################################

#
# This attempts to replicate by hand a circuit done automatically in
# example_sims.jl. It's a 60-Hz voltage source in series with a
# resistor and the parallel combination of a resistor and capacitor.
# 


ckt = Sim(
    (t, y, yp) -> begin
        [y[1] - y[2],
        y[2] - 10.0 * sin(377 * t[1]),
        (y[1] - y[3]) - y[4],
        10.0 * y[5] - y[4],
        y[3] - y[6],
        5.0 * y[7] - y[6],
        y[3] - y[8],
        0.005 * yp[8] - y[9],
        -y[5] + y[7] + y[9],
        y[10] + y[5]]
    end,
    :(1 + jnk),
    zeros(10),  # y start values
    zeros(10),  # yp start values
    zeros(10),  # 0 for algebraic, 1 for differential
)

ckt_yout = sim(ckt)
plot(ckt_yout)
