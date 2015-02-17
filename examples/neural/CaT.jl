
################################
## T-type calcium current model
################################

module CaT

using Sims, Sims.Lib
using Sims.Examples.Neural, Sims.Examples.Neural.Lib
using Sims.Examples.Neural.HodgkinHuxleyModule 
using Docile


function CaTConductance(v,gbar,g)

    ralpha = Unknown ()
    rbeta  = Unknown ()

    salpha = Unknown ()
    sbeta  = Unknown ()

    bd     = Unknown ()
    dalpha = Unknown ()
    dbeta  = Unknown ()

    r   = Gate()
    d   = Gate()
    s   = Gate()

    @equations begin
        der(r) = ralpha*(1-r) - rbeta*r
        der(d) = dbeta*(1-s-d) - dalpha*d
        der(s) = salpha*(1-s-d) - sbeta*s
        
        g  = gbar*r*r*r*s

        ralpha = 1.0/(1.7+exp(-(v+28.2)/13.5))
        rbeta  = exp(-(v+63.0)/7.8)/(exp(-(v+28.8)/13.1)+1.7)

        salpha = exp(-(v+160.3)/17.8)
        sbeta  = (sqrt(0.25+exp((v+83.5)/6.3))-0.5) * exp(-(v+160.3)/17.8)

        bd     = sqrt(0.25+exp((v+83.5)/6.3))
        dalpha = (1.0+exp((v+37.4)/30.0))/(240.0*(0.5+bd))
        dbeta  = (bd-0.5)*dalpha

    end
end


@doc* """
Wang, X., Rinzel, J. and Rogawski, M. (1992) "A model of the
T--type calcium current and the low threshold spike in thalamic
neurons". J. Neurophys. 66: 839-850
""" ->
    
function Soma(;
              I    = 85.0,
              
              diam = 18.8,
              L    = 18.8,
              Ra   = 123.0,

              C_m  = 1e-3,
              E_Ca = 126.0,
              E_Na = 50.0,
              E_K  = -77.0,
              E_L  = -60.0,

              gbar_CaT = 0.002,
              gbar_Na  = 0.25,
              gbar_K   = 0.36,
              g_L      = 0.0001666,

              v = Voltage (-65.0, "v"))
    
    area = pi * L * diam
    
    I_Na   = Current ("I_Na")
    I_K    = Current ("I_K")
    I_L    = Current ("I_L")
    I_CaT  = Current ("I_CaT")

    g_Na  = Conductance ()
    g_K   = Conductance ()
    g_CaT = Conductance ()

    @equations begin

        MembranePotential(v, Equation[-I * (1.0 / area),I_Na,I_K,I_CaT,I_L], C_m)

        HodgkinHuxleyModule.NaConductance (v, gbar_Na, g_Na)
        HodgkinHuxleyModule.KConductance (v, gbar_K, g_K)

        CaTConductance(v, gbar_CaT, g_CaT)

        OhmicCurrent (v, I_Na, g_Na, E_Na)
        OhmicCurrent (v, I_K, g_K, E_K)
        OhmicCurrent (v, I_L, g_L, E_L)
        OhmicCurrent (v, I_CaT, g_CaT, E_Ca)

    end
end

end ## module CaT
