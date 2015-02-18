module HodgkinHuxleyModule

using Sims, Sims.Lib, Sims.Examples.Neural.Lib

##
## Modular implementation of the Hodgkin-Huxley neuron model.
##

function NaConductance(v,gbar,g)

    amf (v) = (0.1 * (v + 40) / (1.0 - exp (- (v + 40) / 10)))
    bmf (v) = (4.0 * exp (- (v + 65) / 18))
    ahf (v) = (0.07 * (exp (- (v + 65.0) / 20.0)))
    bhf (v) = (1.0 / (1.0 + (exp (- (v + 35.0) / 10.0))))

    m   = Gate(0.052, "m")
    h   = Gate(0.596, "h")

    @equations begin
        der(m) = (amf(v) * (1-m)) - (bmf(v) * m)
        der(h) = (ahf(v) * (1-h)) - (bhf(v) * h)
   
        g = m^3 * h * gbar
    end
end


function KConductance(v,gbar,g)

    anf (v) = (0.01 * (v + 55) / (1 - (exp ((- (v + 55)) / 10))))
    bnf (v) = (0.125 * (exp ((- (v + 65)) / 80)))

    n   = Gate(0.317, "n")

    @equations begin
        der(n) = (anf(v) * (1 - n)) - (bnf(v) * n)

        g  = n^4 * gbar
    end
end
    
function Main(;
              I       =   10.0,
              C_m     =    1.0,
              E_Na    =   50.0,
              E_K     =  -77.0,
              E_L     =  -54.4,
              gbar_Na =  120.0,
              gbar_K  =   36.0,
              g_L     =    0.3,
              v::Unknown  = Voltage(-65.0, "v")   
              )


    I_Na = Current ()
    I_K  = Current ()
    I_L  = Current ()
    
    g_Na = Conductance ()
    g_K  = Conductance ()
    
    @equations begin

        MembranePotential(v, Equation[-I,I_Na,I_K,I_L], C_m)

        NaConductance (v, gbar_Na, g_Na)
        KConductance (v, gbar_K, g_K)

        OhmicCurrent (v, I_Na, g_Na, E_Na)
        OhmicCurrent (v, I_K, g_K, E_K)
        OhmicCurrent (v, I_L, g_L, E_L)
        
    end
end

end # module HodgkinHuxley
