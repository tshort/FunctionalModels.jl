
################################
## Wang-Buzsaki neuron model
################################

module WangBuzsaki

using Sims, Sims.Lib
using Sims.Examples.Neural, Sims.Examples.Neural.Lib
using Docile

        
minf(v)=am(v)/(am(v)+bm(v))
am(v)=0.1*(v+35.0)/(1.0-exp(-(v+35.0)/10.0))
bm(v)=4.0*exp(-(v+60.0)/18.0)

ah(v)=0.07*exp(-(v+58.0)/20.0)
bh(v)=1.0/(1.0+exp(-(v+28.0)/10.0))

an(v)=0.01*(v+34.0)/(1.0-exp(-(v+34.0)/10.0))
bn(v)=0.125*exp(-(v+44.0)/80.0)


@doc* """
Wang, X.-J. and Buzsaki G. (1996) Gamma oscillations by synaptic
inhibition in a hippocampal interneuronal network.
J. Neurosci. 16, 6402-6413.
""" ->
function Main(;
              I = 0.5,

              diam = 5.6419,
              L = 5.6419,

              C_m = 1,

              gbar_Na = 0.035,
              gbar_K  = 0.009,
              g_L     = 0.0001,

              E_Na = 55,
              E_K  = -90,
              E_L  = -65,
              
              v::Unknown = Voltage(-20.0, "v"))

    area = pi * L * diam
    
    h   = Gate(0.283)
    n   = Gate(0.265)

    I_Na = Current()
    I_K  = Current()
    I_L  = Current()

    g_Na = Conductance()
    g_K  = Conductance()
    
    @equations begin

        C_m * der(v) = ((I * (100.0 / area)) - 1e3 * (I_K + I_Na + I_L))

        der(n) = 5.0 * (an(v)*(1-n) - bn(v)*n)
        der(h) = 5.0 * (ah(v)*(1-h) - bh(v)*h)

        g_Na = minf(v)^3 * h * gbar_Na
        g_K  = n^4 * gbar_K
    
        I_Na = g_Na * (v - E_Na)
        I_K  = g_K  * (v - E_K)
        I_L  = g_L  * (v - E_L)
        
    end
end

end # module WangBuzsaki
