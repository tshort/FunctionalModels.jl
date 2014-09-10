
using Sims
using Winston

### Wang, X., Rinzel, J. and Rogawski, M. (1992) "A model of the
### T--type calcium current and the low threshold spike in thalamic
### neurons". J. Neurophys. 66: 839-850

# Parameter values
diam = 18.8
L    = 18.8
Ra   = 123.0

C_m      =    1e-3
E_Ca     =   126.0
E_Na     =    50.0
E_K      =   -77.0
E_L      =   -60.0

gbar_CaT = 0.002
gbar_Na  = 0.25
gbar_K   = 0.36
g_L      = 0.0001666 

I = -1e-6

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


function HH(v,I_Na,I_K,I_L)

    m   = Unknown(0.052, "m")
    h   = Unknown(0.596, "h")
    n   = Unknown(0.317, "n")

    g_Na = Unknown ()
    g_K  = Unknown ()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    {
     der(m) - ((amf(v) * (1-m)) - (bmf(v) * m))
     der(h) - ((ahf(v) * (1-h)) - (bhf(v) * h))
     der(n) - ((anf(v) * (1-n)) - (bnf(v) * n))

     g_Na - (m^3 * h * gbar_Na)
     g_K  - (n^4 * gbar_K)
    
     I_Na - (g_Na * (v - E_Na))
     I_K  - (g_K  * (v - E_K))
     I_L  - (g_L  * (v - E_L))

    }
end


function CaT(v,I_CaT)

    ralpha = Unknown ()
    rbeta  = Unknown ()

    salpha = Unknown ()
    sbeta  = Unknown ()

    bd     = Unknown ()
    dalpha = Unknown ()
    dbeta  = Unknown ()

    r   = Unknown("r")
    d   = Unknown("d")
    s   = Unknown("s")

   {
    der(r) - ((ralpha*(1-r)) - (rbeta*r))
    der(d) - ((dbeta*(1-s-d)) - (dalpha*d))
    der(s) - ((salpha*(1-s-d)) - (sbeta*s))
    
    I_CaT  - gbar_CaT*r*r*r*s*(v - E_Ca)

    ralpha - 1.0/(1.7+exp(-(v+28.2)/13.5))
    rbeta  - exp(-(v+63.0)/7.8)/(exp(-(v+28.8)/13.1)+1.7)

    salpha - exp(-(v+160.3)/17.8)
    sbeta  - (sqrt(0.25+exp((v+83.5)/6.3))-0.5) * (exp(-(v+160.3)/17.8))

    bd     - sqrt(0.25+exp((v+83.5)/6.3))
    dalpha - (1.0+exp((v+37.4)/30.0))/(240.0*(0.5+bd))
    dbeta  - (bd-0.5)*dalpha

    }
end



function WRR()
    v      = Voltage (-65.0, "V")
    I_Na   = Unknown ("I_Na")
    I_K    = Unknown ("I_K")
    I_L    = Unknown ("I_L")
    I_CaT  = Unknown ("I_CaT")
    {
     HH(v,I_Na,I_K,I_L)
     CaT(v,I_CaT)

     der(v) - ((I - (I_CaT + I_Na + I_K + I_L)) / C_m)
    }
end

wrr   = WRR()  # returns the hierarchical model
wrr_f = elaborate(wrr)    # returns the flattened model
wrr_s = create_sim(wrr_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 500.0
dt = 0.025
wrr_yout = sunsim(wrr_s, tf, int(tf/dt))

plot (wrr_yout.y[:,1], wrr_yout.y[:,3])

