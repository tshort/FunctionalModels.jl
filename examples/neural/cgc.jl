
###########################################
## Cerebellar granule cell neuron model 
###########################################

module CGC

using Sims, Sims.Lib
using Sims.Examples.Neural, Sims.Examples.Neural.Lib
using Docile

function sigm(x, y)
    return 1.0 / (exp(x / y) + 1)
end

function linoid(x, y) 
    return ifelse(abs(x / y) < 1e-6, (y * (1 - ((x/y) / 2))), (x / (exp(x/y) - 1)))
end

## Calcium concentration dynamics
const cai0  = 1e-4

function CaConcentration(cai,I_Ca)

    depth = 0.2
    cao   = 2.0
    beta  = 1.5

    @equations begin

        der(cai) = ((- (I_Ca) / (2 * F * depth)) * 1e4 -
		    (beta * (ifelse(cai < cai0, cai0, cai) - cai0)))
    end
end

## High-voltage activated calcium conductance 

function CaHVAConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 20) / 10)

    Aalpha_s  = 0.04944
    Kalpha_s  =  15.87301587302
    V0alpha_s = -29.06
	
    Abeta_s  = 0.08298
    Kbeta_s  =  -25.641
    V0beta_s = -18.66

    Aalpha_u  = 0.0013
    Kalpha_u  =  -18.183
    V0alpha_u = -48
			 
    Abeta_u = 0.0013
    Kbeta_u = 83.33
    V0beta_u = -48


    function alpha_s(v)
	return (Q10 * Aalpha_s * exp((v - V0alpha_s) / Kalpha_s))
    end

    function beta_s(v)
	return (Q10 * Abeta_s * exp((v - V0beta_s) / Kbeta_s))
    end

    function alpha_u(v)
	return (Q10 * Aalpha_u * exp((v - V0alpha_u) / Kalpha_u))
    end

    function beta_u(v)
	return (Q10 * Abeta_u * exp((v - V0beta_u) / Kbeta_u))
    end

    s = Gate(value(alpha_s(v) / (alpha_s(v) + beta_s(v))))
    u = Gate(value(alpha_u(v) / (alpha_u(v) + beta_u(v))))
    
    @equations begin
        der(s) =  alpha_s(v) * (1 - s) - beta_s(v) * s
        der(u) =  alpha_u(v) * (1 - u) - beta_u(v) * u

        g  = s^2 * u * gbar
    end
end

## KA current

function KAConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 20) / 10)

    Aalpha_a  = 4.88826
    Kalpha_a  = -23.32708
    V0alpha_a = -9.17203
    Abeta_a   = 0.99285
    Kbeta_a   = 19.47175
    V0beta_a  = -18.27914

    Aalpha_b  = 0.11042
    Kalpha_b  = 12.8433
    V0alpha_b = -111.33209
    Abeta_b   = 0.10353
    Kbeta_b   = -8.90123
    V0beta_b  = -49.9537

    V0_ainf = -46.7
    K_ainf = -19.8

    V0_binf   = -78.8
    K_binf    = 8.4

    function alpha_a(v)
	return (Q10 * Aalpha_a * sigm((v - V0alpha_a), Kalpha_a))
    end

    function beta_a(v)
	return (Q10 * (Abeta_a / exp((v - V0beta_a) / Kbeta_a)))
    end

    function alpha_b(v)
	return (Q10 * Aalpha_b * sigm((v - V0alpha_b), Kalpha_b))
    end

    function beta_b(v)
	(Q10 * Abeta_b * sigm((v - V0beta_b), Kbeta_b))
    end

    a = Gate(value(1 / (1 + exp((v - V0_ainf) / K_ainf))))
    b = Gate(value(1 / (1 + exp((v - V0_binf) / K_binf))))

    a_inf   = Unknown(value(1 / (1 + exp((v - V0_ainf) / K_ainf))))
    b_inf   = Unknown(value(1 / (1 + exp((v - V0_binf) / K_binf))))

    tau_a   = Unknown(value(1 / (alpha_a(v) + beta_a(v))))
    tau_b   = Unknown(value(1 / (alpha_b(v) + beta_b(v))))

    @equations begin

        der(a) =  (a_inf - a) / tau_a
        der(b) =  (b_inf - b) / tau_b

        a_inf = (1 / (1 + exp((v - V0_ainf) / K_ainf)))
	tau_a = (1 / (alpha_a(v) + beta_a(v)) )
	b_inf = (1 / (1 + exp((v - V0_binf) / K_binf)))
	tau_b = (1 / (alpha_b(v) + beta_b(v)) )

        g  = a^3 * b * gbar

    end
end


## Calcium-modulated potassium current

function KCaConductance(celsius,v,cai,gbar,g)

    Q10 = 3^((celsius - 30) / 10)
		 
    Aalpha_c = 2.5
    Balpha_c = 1.5e-3
		 
    Kalpha_c =  -11.765
		 
    Abeta_c = 1.5
    Bbeta_c = 0.15e-3

    Kbeta_c = -11.765

    function alpha_c(v, cai)
	(Q10 * Aalpha_c / (1 + (Balpha_c * exp(v / Kalpha_c) / cai)))
    end
		 
    function beta_c(v, cai)
	(Q10 * Abeta_c / (1 + (cai / (Bbeta_c * exp(v / Kbeta_c))) ))
    end

    c = Gate(value(alpha_c(v, cai) / (alpha_c(v, cai) + beta_c(v, cai))))
    
    @equations begin
        der(c) =  alpha_c(v, cai) * (1 - c) - beta_c(v, cai) * c

        g  = c * gbar
    end
    
end

## Kir current

function KirConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 20) / 10)

    Aalpha_d = 0.13289
    Kalpha_d = -24.3902

    V0alpha_d = -83.94
    Abeta_d   = 0.16994
    
    Kbeta_d = 35.714
    V0beta_d = -83.94
   
    function alpha_d(v)
	(Q10 * Aalpha_d * exp((v - V0alpha_d) / Kalpha_d))
    end
			 
    function beta_d(v)
	(Q10 * Abeta_d * exp((v - V0beta_d) / Kbeta_d) )
    end

    d = Gate(value(alpha_d(v) / (alpha_d(v) + beta_d(v))))
    
    @equations begin
        der(d) =  alpha_d(v) * (1 - d) - beta_d(v) * d

        g  = d * gbar
    end
    
end

## KM current

function KMConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 22) / 10)

    Aalpha_n = 0.0033

    Kalpha_n  = 40
    V0alpha_n = -30
    Abeta_n   = 0.0033
    
    Kbeta_n  = -20
    V0beta_n = -30
    V0_ninf  = -30
    B_ninf = 6

    function alpha_n(v)
	(Q10 * Aalpha_n * exp((v - V0alpha_n) / Kalpha_n) )
    end

    function beta_n(v)
	(Q10 * Abeta_n * exp((v - V0beta_n) / Kbeta_n) )
    end

    n   = Gate(value(alpha_n(v) / (alpha_n(v) + beta_n(v))))
    
    n_inf   = Unknown(value(1 / (alpha_n(v) + beta_n(v))))
    tau_n   = Unknown(value(1 / (1 + exp((-(v - V0_ninf)) / B_ninf))))
    
    @equations begin
        der(n) = (n_inf - n) / tau_n

        tau_n = 1 / (alpha_n(v) + beta_n(v))
	n_inf = 1 / (1 + exp((-(v - V0_ninf)) / B_ninf))

        g  = n * gbar
    end
    
end


## KV current

function KVConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 6.3) / 10)


    Aalpha_n = -0.01
    Kalpha_n = -10
    V0alpha_n = -25
    Abeta_n = 0.125
	
    Kbeta_n = -80
    V0beta_n = -35
    

    function alpha_n(v) 
	(Q10 * Aalpha_n * linoid((v - V0alpha_n), Kalpha_n))
    end
    
    function beta_n(v) 
	(Q10 * Abeta_n * exp((v - V0beta_n) / Kbeta_n) )
    end

    n   = Gate(value(alpha_n(v) / (alpha_n(v) + beta_n(v))))
    
    @equations begin
        der(n) =  alpha_n(v) * (1 - n) - beta_n(v) * n

        g  = n^4 * gbar
    end
    
end


## Sodium current
function NaConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 20) / 10)
    
    Aalpha_m  = -0.3
    Kalpha_m  = -10
    V0alpha_m = -19
	
    Abeta_m = 12
    Kbeta_m = -18.182
    V0beta_m = -44

    Aalpha_h = 0.105
    Kalpha_h = -3.333
    V0alpha_h = -44
 
    Abeta_h = 1.5
    Kbeta_h = -5
    V0beta_h = -11

    function alpha_m(v)	
	(Q10 * Aalpha_m * linoid((v - V0alpha_m), Kalpha_m) )
    end

    function beta_m(v)
	(Q10 * Abeta_m * exp((v - V0beta_m) / Kbeta_m) )
    end

    function alpha_h(v)
	(Q10 * Aalpha_h * exp((v - V0alpha_h) / Kalpha_h) )
    end
				
    function beta_h(v)
	(Q10 * Abeta_h / (1 + exp((v - V0beta_h) / Kbeta_h) ))
    end
    
    m   = Gate(value(alpha_m(v) / (alpha_m(v) + beta_m(v))))
    h   = Gate(value(alpha_h(v) / (alpha_h(v) + beta_h(v))))
    
    @equations begin
        der(m) =  alpha_m(v) * (1 - m) - beta_m(v) * m
        der(h) =  alpha_h(v) * (1 - h) - beta_h(v) * h

        g  = m^3 * h * gbar
    end
end


## NaR current

function NaRConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 20) / 10)

    Aalpha_s     = -0.00493
    V0alpha_s    = -4.48754
    Kalpha_s     = -6.81881
    Shiftalpha_s = 0.00008

    Abeta_s     = 0.01558
    V0beta_s    = 43.97494
    Kbeta_s     =  0.10818
    Shiftbeta_s = 0.04752

    Aalpha_f  = 0.31836
    V0alpha_f = -80
    Kalpha_f  = -62.52621

    Abeta_f  = 0.01014
    V0beta_f = -83.3332
    Kbeta_f  = 16.05379

    function alpha_s(v) 
	(Q10 * (Shiftalpha_s + (Aalpha_s * ((v + V0alpha_s) / (exp((v + V0alpha_s) / Kalpha_s) - 1)))))
    end

    function beta_s(v) 
	(Q10 * (Shiftbeta_s + Abeta_s * ((v + V0beta_s) / (exp((v + V0beta_s) / Kbeta_s) - 1))))
    end

    function alpha_f(v) 
	(Q10 * Aalpha_f * exp( ( v - V0alpha_f ) / Kalpha_f))
    end

    function beta_f(v) 
	(Q10 * Abeta_f * exp( ( v - V0beta_f ) / Kbeta_f )  )
    end
    
    
    s   = Gate(value(alpha_s(v) / (alpha_s(v) + beta_s(v))))
    f   = Gate(value(alpha_f(v) / (alpha_f(v) + beta_f(v))))
    
    @equations begin
        der(s) =  alpha_s(v) * (1 - s) - beta_s(v) * s
        der(f) =  alpha_f(v) * (1 - f) - beta_f(v) * f

        g  = s * f * gbar
    end
end



## pNa conductance

function pNaConductance(celsius,v,gbar,g)

    Q10 = 3^((celsius - 30) / 10)
    
    Aalpha_m  = -0.091
    Kalpha_m  = -5
    V0alpha_m = -42
    Abeta_m   = 0.062
    Kbeta_m   = 5
    V0beta_m  = -42
    V0_minf   = -42
    B_minf    = 5
    

    function alpha_m(v)
	(Q10 * Aalpha_m * linoid( (v - V0alpha_m), Kalpha_m))
    end

    function beta_m(v)
	(Q10 * Abeta_m * linoid( (v - V0beta_m), Kbeta_m) )
    end
    
    m   = Gate(value(1 / (1 + exp((- (v - V0_minf)) / B_minf))))

    m_inf   = Unknown(value(1 / (1 + exp((- (v - V0_minf)) / B_minf))))
    tau_m   = Unknown(value(5 / (alpha_m(v) + beta_m(v))))
    
    @equations begin
        
        der(m) = (m_inf - m) / tau_m

	m_inf =  (1 / (1 + exp((- (v - V0_minf)) / B_minf)))
	tau_m =  (5 / (alpha_m(v) + beta_m(v)))

        g  = m * gbar
    end
end


@doc """
Model of a cerebellar granule cell soma from the paper:

_Theta-Frequency Bursting and Resonance in Cerebellar Granule Cells:
Experimental Evidence and Modeling of a Slow K+-Dependent
Mechanism_.  E. D'Angelo, T. Nieus, A. Maffei, S. Armano, P. Rossi,
V. Taglietti, A. Fontana and G. Naldi.
""" ->

function Soma(;
              I = 0.01875,

              celsius = 30,
              C_m = 1e-3,

              ## Soma dimensions

              L = 11.8,
              diam = 11.8,

              ## Reversal potentials

              E_Ca = 129.33,
              E_K  = -84.69,
              E_Na  = 87.39,
              E_Leak1 = -16.5,
              E_Leak2 = -65,

              ## Maximal conductances
              
              gbar_CaHVA = 0.00046,
              gbar_KA  = 0.004,
              gbar_KCa = 0.003,
              gbar_Kir = 0.0009,
              gbar_KM  = 0.00035,
              gbar_KV  = 0.003,
              gbar_Na  = 0.013,
              gbar_NaR = 0.0005,
              gbar_pNa  = 2e-5,
              g_Leak1  = 5.68e-5,
              g_Leak2  = 3e-5,
              
              v::Unknown  = Voltage(-70.0, "v")   
              )

    area = pi * L * diam

    cai = Unknown(cai0, "cai")

    g_CaHVA = Conductance()

    g_KCa  = Conductance()
    g_KA   = Conductance()
    g_KV   = Conductance()
    g_KM   = Conductance()
    g_Kir  = Conductance()

    g_Na   = Conductance()
    g_NaR  = Conductance()
    g_pNa  = Conductance()

    I_stim = Discrete(0.0)

    I_Ca = Current()
    I_K  = Current()
    I_L  = Current()

    I_CaHVA = Current()

    I_KCa  = Current()
    I_KA   = Current()
    I_KV   = Current()
    I_KM   = Current()
    I_Kir  = Current()

    I_Na   = Current()
    I_NaR  = Current()
    I_pNa  = Current()

    I_Leak1  = Current()
    I_Leak2  = Current()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        MembranePotential(v, Equation[-(I_stim * (100.0 / area)),I_Na,I_NaR,I_pNa,I_K,I_Ca,I_L], C_m)

        CaConcentration(cai,I_Ca)
        CaHVAConductance(celsius,v,gbar_CaHVA,g_CaHVA)

        KAConductance(celsius,v,gbar_KA,g_KA)
        KVConductance(celsius,v,gbar_KV,g_KV)
        KCaConductance(celsius,v,cai,gbar_KCa,g_KCa)
        KirConductance(celsius,v,gbar_Kir,g_Kir)
        KMConductance(celsius,v,gbar_KM,g_KM)

        NaConductance(celsius,v,gbar_Na,g_Na)
        NaRConductance(celsius,v,gbar_NaR,g_NaR)
        pNaConductance(celsius,v,gbar_pNa,g_pNa)

        I_Ca = I_CaHVA
        I_K = I_KA + I_KV + I_KCa + I_Kir  + I_KM
        I_L = I_Leak1 + I_Leak2

        OhmicCurrent(v, I_CaHVA, g_CaHVA, E_Ca)
        OhmicCurrent(v, I_Na, g_Na, E_Na)
        OhmicCurrent(v, I_NaR, g_NaR, E_Na)
        OhmicCurrent(v, I_pNa, g_pNa, E_Na)
        OhmicCurrent(v, I_KA, g_KA, E_K)
        OhmicCurrent(v, I_KV, g_KV, E_K)
        OhmicCurrent(v, I_KM, g_KM, E_K)
        OhmicCurrent(v, I_KCa, g_KCa, E_K)
        OhmicCurrent(v, I_Kir, g_Kir, E_K)

        OhmicCurrent(v, I_Leak1, g_Leak1, E_Leak1)
        OhmicCurrent(v, I_Leak2, g_Leak2, E_Leak2)
        
        Event(MTime - 250.0,     # Start injecting current after 250 ms
              Equation[
                  reinit(I_stim, I)
              ],
              Equation[])

        Event(MTime - 800.0,     # Stop injecting current after 800 ms
              Equation[
                  reinit(I_stim, 0.0)
              ],
              Equation[])
        
    end
end

end # module CGC
