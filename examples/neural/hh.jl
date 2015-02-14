
########################################
## Hidgkin-Huxley neuron model        ##
########################################


export HodgkinHuxley

type UConductance <: UnknownCategory
end

typealias Gate Unknown{DefaultUnknown,NonNegative}
typealias Conductance Unknown{UConductance,NonNegative}



## Rate functions

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


@doc* """
This model is used to calculate the membrane potential of a
neuron. The calculation is based on sodium ion flow, potassium ion
flow and leakage ion flow. (Hodgkin, A. L. and Huxley, A. F. (1952)
"A Quantitative Description of Membrane Current and its Application
to Conduction and Excitation in Nerve" Journal of Physiology 117:
500-544)
""" ->
function HodgkinHuxley(;
                       I = Parameter(10.0),
                       C_m = Parameter(1.0),

                       gbar_Na = Parameter(120.0),
                       gbar_K  = Parameter(36.0),
                       g_L     = Parameter(0.3),

                       E_Na    = Parameter(50.0),
                       E_K     = Parameter(-77.0),
                       E_L     = Parameter(-54.4),

                       v   = Voltage(-65.0, "v")   
                       )
    
    m   = Gate(0.052, "m")
    h   = Gate(0.596, "h")
    n   = Gate(0.317, "n")

    g_Na = Conductance()
    g_K  = Conductance()

    I_Na = Current()
    I_K  = Current()
    I_L  = Current()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately.
    @equations begin

        der(v) = (I - (I_Na + I_K + I_L)) / C_m
        der(m) = (amf(v) * (1 - m)) - (bmf(v) * m)
        der(h) = (ahf(v) * (1 - h)) - (bhf(v) * h)
        der(n) = (anf(v) * (1 - n)) - (bnf(v) * n)

        g_Na = m^3 * h * gbar_Na
        g_K  = n^4 * gbar_K
    
        I_Na = g_Na * (v - E_Na)
        I_K  = g_K  * (v - E_K)
        I_L  = g_L  * (v - E_L)

    end
end

