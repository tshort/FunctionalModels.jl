

########################################
## Test of the DAE simulator          ##
## Van Der Pol oscillator             ##
########################################




vanderpol = Sim(
    (t, y, yp) -> begin
        [yp[1] - ((1 - y[2]^2) * y[1] - y[2]),
         yp[2] - y[1]]
    end,
    :(1 + jnk),
    [0, 1.0],   # y start values
    [-1.0, 0],  # yp start values
    ones(2),    # 0 for algebraic, 1 for differential
)

v_yout = sim(vanderpol)
# push(LOAD_PATH, "/home/tshort/julia/julia/extras/gaston-0.3")
# load("gaston.jl")
plot(v_yout[:,1], v_yout[:,2])
plot(v_yout[:,2], v_yout[:,3])







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
