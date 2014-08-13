
#
# An implementation of the Hodgkin-Huxley neuron model.
#

using Sims
using Winston

I       =   10.0
C_m     =    1.0
E_Na    =   50.0
E_K     =  -77.0
E_L     =  -54.4
gbar_Na =  120.0
gbar_K  =   36.0
g_L     =    0.3

## Model equations

function amf (v)
    return (0.1 * (v + 40) / (1.0 - exp (- (v + 40) / 10)))
end

function bmf (v)
    return (4.0 * exp (- (v + 65) / 18))
end

function ahf (v)
    return (0.07 * (exp (- (v + 65.0) / 20.0)))
end

function bhf (v)
    return (1.0 / (1.0 + (exp (- (v + 35.0) / 10.0))))
end

function anf (v)
    return (0.01 * (v + 55) / (1 - (exp ((- (v + 55)) / 10))))
end

function bnf (v)
    return (0.125 * (exp ((- (v + 65)) / 80)))
end  	                   

function HodgkinHuxley()

    v   = Unknown(-65.0, "v")   
    m   = Unknown(0.052, "m")
    h   = Unknown(0.596, "h")
    n   = Unknown(0.317, "n")

    g_Na = Unknown ()
    g_K  = Unknown ()

    I_Na = Unknown ()
    I_K  = Unknown ()
    I_L  = Unknown ()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {

     der(v) - ((I - (I_Na + I_K + I_L)) / C_m)
     der(m) - ((amf(v) * (1 - m)) - (bmf(v) * m))
     der(h) - ((ahf(v) * (1 - h)) - (bhf(v) * h))
     der(n) - ((anf(v) * (1 - n)) - (bnf(v) * n))

     g_Na - (m^3 * h * gbar_Na)
     g_K  - (n^4 * gbar_K)
    
     I_Na - (g_Na * (v - E_Na))
     I_K  - (g_K  * (v - E_K))
     I_L  - (g_L  * (v - E_L))

    }
end

hh   = HodgkinHuxley()  # returns the hierarchical model
hh_f = elaborate(hh)    # returns the flattened model
hh_s = create_sim(hh_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
hh_yout = sunsim(hh_s, 200.0) 

plot (hh_yout.y[:,1], hh_yout.y[:,2])

