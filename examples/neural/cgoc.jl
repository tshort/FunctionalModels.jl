##
## Model of a cerebellar Golgi cell from the paper:
##
##  _Computational reconstruction of pacemaking and intrinsic
##  electroresponsiveness in cerebellar Golgi cells_
##  Sergio M. Solinas, Lia Forti, Elisabetta Cesana, Jonathan Mapelli,
##  Erik De Schutter and Egidio D`Angelo,
##  Frontiers in Cellular Neuroscience 2:2 (2008)


using Sims
using Sims.Lib
using Winston


type UConductance <: UnknownCategory
end

typealias Gate Unknown{DefaultUnknown,NonNegative}
typealias Conductance Unknown{UConductance,NonNegative}

function sigm (x, y)
    return 1.0 / (exp (x / y) + 1)
end

function linoid (x, y) 
    return ifelse (abs (x / y) < 1e-6,
                   (y * (1 - ((x/y) / 2))),
                   (x / (exp (x/y) - 1)))
end

const F = 96485.3
const R = 8.31342

function ktf (celsius)
    return (1000.0 * R * (celsius + 273.15) / F )
end

function nernst (celsius, ci, co, z) 
    ifelse (ci <= 0, 1e6,
            ifelse (co <= 0, -1e6,
                    ktf (celsius) / z * (log (co / ci))))
end

const celsius = 23
const C_m = 1.0

## Soma dimensions

const L = 27
const diam = 27
const area = pi * L * diam

## Reversal potentials

const E_K  = -84.69
const E_Na  = 87.39


## Calcium concentration dynamics
const cai0  = 5e-5
const cao   = 2.0

function Ca_model(cai,I_Ca)

    const depth = 0.2
    const beta  = 1.3

    @equations begin
        der(cai) = ((- (I_Ca) / (2 * F * depth)) * 1e4 -
		    (beta * (ifelse(cai < cai0, cai0, cai) - cai0)))
    end
    
end

function Ca2_model(ca2i,I_Ca2)

    const depth = 0.2
    const beta  = 1.3

    @equations begin

        der(ca2i) = ((- (I_Ca2) / (2 * F * depth)) * 1e4 -
		     (beta * (ifelse(ca2i < cai0, cai0, ca2i) - cai0)))
    end
end

## Calcium reversal potential

function E_Ca_model(E_Ca, cai)
    @equations begin
        E_Ca = nernst(celsius, cai, cao, 2)
    end
end

function E_Ca2_model(E_Ca2, ca2i)
    @equations begin
        E_Ca2 = nernst(celsius, ca2i, cao, 2)
    end
end
    
## High-voltage activated calcium current 

function CaHVA_model(v,I_CaHVA,E_Ca)

    const Q10 = 3^((celsius - 20) / 10)

    const Aalpha_s  = 0.04944
    const Kalpha_s  =  15.87301587302
    const V0alpha_s = -29.06
	
    const Abeta_s  = 0.08298
    const Kbeta_s  =  -25.641
    const V0beta_s = -18.66

    const Aalpha_u  = 0.0013
    const Kalpha_u  =  -18.183
    const V0alpha_u = -48
			 
    const Abeta_u = 0.0013
    const Kbeta_u = 83.33
    const V0beta_u = -48

    const gbar_CaHVA  = 0.00046

    function alpha_s (v)
	return (Q10 * Aalpha_s * exp((v - V0alpha_s) / Kalpha_s))
    end

    function beta_s (v)
	return (Q10 * Abeta_s * exp((v - V0beta_s) / Kbeta_s))
    end

    function alpha_u (v)
	return (Q10 * Aalpha_u * exp((v - V0alpha_u) / Kalpha_u))
    end

    function beta_u (v)
	return (Q10 * Abeta_u * exp((v - V0beta_u) / Kbeta_u))
    end

    s = Gate (value(alpha_s(v) / (alpha_s(v) + beta_s(v))))
    u = Gate (value(alpha_u(v) / (alpha_u(v) + beta_u(v))))
    g_CaHVA = Conductance (value(s^2 * u * gbar_CaHVA))
    
    @equations begin
        der(s) =  alpha_s(v) * (1 - s) - beta_s(v) * s
        der(u) =  alpha_u(v) * (1 - s) - beta_u(v) * s

        g_CaHVA  = s^2 * u * gbar_CaHVA
	      
        I_CaHVA  = g_CaHVA  * (v - E_Ca)
    end
end

## Low-voltage activated calcium current 

function CaLVA_model(v,I_CaLVA,E_Ca2)

    const shift = 2
    
    const v0_m_inf = -50
    const v0_h_inf = -78
    const k_m_inf  = -7.4
    const k_h_inf  = 5.0
	
    const C_tau_m   = 3
    const A_tau_m   = 1.0
    const v0_tau_m1 = -25
    const v0_tau_m2 = -100
    const k_tau_m1  = 10
    const k_tau_m2 = -15
		 
    const C_tau_h   = 85
    const A_tau_h   = 1.0
    const v0_tau_h1 = -46
    const v0_tau_h2 = -405
    const k_tau_h1  = 4
    const k_tau_h2  = -50

    const phi_m = 5.0^((celsius - 24) / 10)
    const phi_h = 3.0^((celsius - 24) / 10)

    const gbar_CaLVA  = 2.5e-4

    m_inf = Unknown(value(1.0 / ( 1 + exp ((v + shift - v0_m_inf) / k_m_inf))))
    h_inf = Unknown(value(1.0 / ( 1 + exp ((v + shift - v0_h_inf) / k_h_inf))))
    tau_m = Unknown(value((C_tau_m + A_tau_m / ( exp ((v + shift - v0_tau_m1) / k_tau_m1) + exp ((v + shift - v0_tau_m2) / k_tau_m2) ) ) / phi_m ))
    tau_h = Unknown(value((C_tau_h + A_tau_h / ( exp ((v + shift - v0_tau_h1 ) / k_tau_h1) + exp ((v + shift - v0_tau_h2) / k_tau_h2) ) ) / phi_h))

    m = Gate (value(m_inf))
    h = Gate (value(h_inf))
    g_CaLVA = Conductance (value(m^2 * h * gbar_CaLVA))
    
    @equations begin


        der(m) =  (m_inf - m) / tau_m
        der(h) =  (h_inf - h) / tau_h

        m_inf = 1.0 / ( 1 + exp ((v + shift - v0_m_inf) / k_m_inf))
        h_inf = 1.0 / ( 1 + exp ((v + shift - v0_h_inf) / k_h_inf))
		 
        tau_m = (C_tau_m + A_tau_m / ( exp ((v + shift - v0_tau_m1) / k_tau_m1) + exp ((v + shift - v0_tau_m2) / k_tau_m2) ) ) / phi_m 
        tau_h = (C_tau_h + A_tau_h / ( exp ((v + shift - v0_tau_h1 ) / k_tau_h1) + exp ((v + shift - v0_tau_h2) / k_tau_h2) ) ) / phi_h

        g_CaLVA  = m^2 * h * gbar_CaLVA
	      
        I_CaLVA  = g_CaLVA  * (v - E_Ca2)
    end

    
end



function HCN1_model(v,I_HCN1)

    const Ehalf = -72.49
    const c = 0.11305
	      
    const rA = 0.002096
    const rB = 0.97596

    const gbar_HCN1 = 5e-5
    const E_HCN1 = -20
    
    function r (potential)
   	return ((rA * potential) + rB)
    end
	      
    function tau (potential, t1, t2, t3)
   	return exp (((t1 * potential) - t2) * t3)
    end
	      
    function o_inf (potential, Ehalf, c)
   	(1 / (1 + exp ((potential - Ehalf) * c)))
    end


    function slow_gate(o_slow_inf,o_slow)
                         
        const tCs = 0.01451
        const tDs = -4.056
        const tEs = 2.302585092

        tau_s = Unknown(value(tau(v, tCs, tDs, tEs)))

        @equations begin

            o_slow_inf = (1 - r(v)) * o_inf(v, Ehalf, c)
			
            tau_s =  tau(v, tCs, tDs, tEs)

            der(o_slow) = ((o_slow_inf - o_slow) / tau_s)
            
        end
    end

    function fast_gate(o_fast_inf,o_fast)
    	
        const tCf = 0.01371
        const tDf = -3.368
        const tEf = 2.302585092

        tau_f = Unknown(value(tau(v, tCf, tDf, tEf)))

        @equations begin

            o_fast_inf = r(v) * o_inf (v, Ehalf, c)
			
            tau_f =  tau (v, tCf, tDf, tEf)
        
            der(o_fast) = ((o_fast_inf - o_fast) / tau_f)
            
        end
    end

    o_slow_inf = Unknown(value((1 - r(v)) * o_inf(v, Ehalf, c)))
    o_slow = Gate(value(o_slow_inf))

    o_fast_inf = Unknown(value(r(v) * o_inf(v, Ehalf, c)))
    o_fast = Gate(value(o_fast_inf))

    g_HCN1 = Conductance (value((o_slow + o_fast) * gbar_HCN1))

    @equations begin

        slow_gate(o_slow_inf,o_slow)
        fast_gate(o_fast_inf,o_fast)

        g_HCN1  = (o_slow + o_fast) * gbar_HCN1
	      
        I_HCN1  = g_HCN1  * (v - E_HCN1)

    end
    
end


function HCN2_model(v,I_HCN2)

    const Ehalf = -81.95
    const c = 0.1661

    const rA = -0.0227
    const rB = -1.4694

    const gbar_HCN2 = 8e-5
    const E_HCN2 = -20
    
    function r (potential, r1, r2)
   	ifelse (potential >= -64.70,
   	        0.0,
   		ifelse (potential <= -108.70,
   			1.0,
   			(r1 * potential) + r2))
    end
	      
    function tau (potential, t1, t2, t3)
   	return exp (((t1 * potential) - t2) * t3)
    end
	      
    function o_inf (potential, Ehalf, c)
   	(1 / (1 + exp ((potential - Ehalf) * c)))
    end


    function slow_gate(o_slow_inf,o_slow)
                         
        const tCs = 0.0152
        const tDs = -5.2944
        const tEs = 2.3026

        tau_s = Unknown(value(tau(v, tCs, tDs, tEs)))

        @equations begin

            o_slow_inf = (1 - r(v, rA, rB)) * o_inf(v, Ehalf, c)
			
            tau_s =  tau(v, tCs, tDs, tEs)

            der(o_slow) = ((o_slow_inf - o_slow) / tau_s)
            
        end
    end

    function fast_gate(o_fast_inf,o_fast)
    	
        const tCf = 0.0269
        const tDf = -5.6111
        const tEf = 2.3026

        tau_f = Unknown(value(tau(v, tCf, tDf, tEf)))

        @equations begin

            o_fast_inf = r(v, rA, rB) * o_inf (v, Ehalf, c)
			
            tau_f =  tau (v, tCf, tDf, tEf)
        
            der(o_fast) = ((o_fast_inf - o_fast) / tau_f)
            
        end
    end

    o_slow_inf = Unknown(value((1 - r(v, rA, rB)) * o_inf(v, Ehalf, c)))
    o_slow = Gate(value(o_slow_inf))

    o_fast_inf = Unknown(value(r(v, rA, rB) * o_inf(v, Ehalf, c)))
    o_fast = Gate(value(o_fast_inf))

    g_HCN2 = Conductance (value((o_slow + o_fast) * gbar_HCN2))

    @equations begin

        slow_gate(o_slow_inf,o_slow)
        fast_gate(o_fast_inf,o_fast)

        g_HCN2  = (o_slow + o_fast) * gbar_HCN2
	      
        I_HCN2  = g_HCN2  * (v - E_HCN2)

    end
    
end



## KA current

function KA_model(v,I_KA)

    const Q10 = 3^((celsius - 25.5) / 10)

    const Aalpha_a  = 0.8147
    const Kalpha_a  = -23.32708
    const V0alpha_a = -9.17203
    const Abeta_a   = 0.1655
    const Kbeta_a   = 19.47175
    const V0beta_a  = -18.27914
    
    const Aalpha_b  = 0.0368
    const Kalpha_b  = 12.8433
    const V0alpha_b = -111.33209
    const Abeta_b   = 0.0345
    const Kbeta_b   = -8.90123
    const V0beta_b  = -49.9537
    
    const V0_ainf = -38
    const  K_ainf = -17
    
    const V0_binf   = -78.8
    const K_binf    = 8.4

    const gbar_KA = 0.008
			 
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

    a = Gate(value(1 / (1 + exp ((v - V0_ainf) / K_ainf))))
    b = Gate(value(1 / (1 + exp ((v - V0_binf) / K_binf))))

    a_inf   = Unknown(value(1 / (1 + exp ((v - V0_ainf) / K_ainf))))
    b_inf   = Unknown(value(1 / (1 + exp ((v - V0_binf) / K_binf))))

    tau_a   = Unknown(value(1 / (alpha_a (v) + beta_a (v))))
    tau_b   = Unknown(value(1 / (alpha_b (v) + beta_b (v))))

    g_KA = Conductance (value(a^3 * b * gbar_KA))

    @equations begin

        der(a) =  (a_inf - a) / tau_a
        der(b) =  (b_inf - b) / tau_b

        a_inf = (1 / (1 + exp ((v - V0_ainf) / K_ainf)))
	tau_a = (1 / (alpha_a (v) + beta_a (v)) )
	b_inf = (1 / (1 + exp ((v - V0_binf) / K_binf)))
	tau_b = (1 / (alpha_b (v) + beta_b (v)) )

        g_KA  = a^3 * b * gbar_KA
	      
        I_KA  = g_KA  * (v - E_K)

    end
end


## Calcium-modulated potassium current

function KCa_model(v,cai,I_KCa)

    const Q10 = 3^((celsius - 30) / 10)

    const Aalpha_c = 7.0
    const Balpha_c = 1.5e-3
		 
    const Kalpha_c =  -11.765
		 
    const Abeta_c = 1.0
    const Bbeta_c = 0.15e-3

    const Kbeta_c = -11.765

    const gbar_KCa  = 0.003

    function alpha_c (v, cai)
	(Q10 * Aalpha_c / (1 + (Balpha_c * exp(v / Kalpha_c) / cai)))
    end
		 
    function beta_c (v, cai)
	(Q10 * Abeta_c / (1 + (cai / (Bbeta_c * exp (v / Kbeta_c))) ))
    end

    c_inf   = Unknown(value(alpha_c (v, cai) / (alpha_c (v, cai) + beta_c (v, cai))))
    tau_c   = Unknown(value(1 / (alpha_c (v, cai) + beta_c (v, cai))))

    c = Gate(value(c_inf))
    g_KCa = Conductance (value(c * gbar_KCa))
    
    @equations begin
        der(c) =  (c_inf - c) / tau_c

        c_inf = (alpha_c (v, cai)) / (alpha_c (v, cai) + beta_c (v, cai))
        tau_c = 1 / (alpha_c (v, cai) + beta_c (v, cai))

        g_KCa  = c * gbar_KCa
	      
        I_KCa  = g_KCa  * (v - E_K)
    end
    
end

## KM current

function KM_model(v,I_KM)

    const Q10 = 3^((celsius - 22) / 10)

    const Aalpha_n = 0.0033

    const Kalpha_n  = 40
    const V0alpha_n = -30
    const Abeta_n   = 0.0033

    const Kbeta_n  = -20
    const V0beta_n = -30
    const V0_ninf  = -35
    const   B_ninf = 6
			 
    const gbar_KM  = 0.001

    function alpha_n (v)
	(Q10 * Aalpha_n * exp((v - V0alpha_n) / Kalpha_n) )
    end

    function beta_n (v)
	(Q10 * Abeta_n * exp((v - V0beta_n) / Kbeta_n) )
    end

    n   = Gate(value(alpha_n (v) / (alpha_n(v) + beta_n(v))))
    g_KM = Conductance (value(n * gbar_KM))
    
    n_inf   = Unknown(value(1 / (alpha_n(v) + beta_n(v))))
    tau_n   = Unknown(value(1 / (1 + exp((-(v - V0_ninf)) / B_ninf))))
    
    @equations begin
        der(n) = (n_inf - n) / tau_n

        tau_n = 1 / (alpha_n(v) + beta_n(v))
	n_inf = 1 / (1 + exp((-(v - V0_ninf)) / B_ninf))

        g_KM  = n * gbar_KM
	      
        I_KM  = g_KM  * (v - E_K)
    end
    
end


## KV current

function KV_model(v,I_KV)

    const Q10 = 3^((celsius - 6.3) / 10)

    const Aalpha_n = -0.01
    const Kalpha_n = -10
    const V0alpha_n = -26
    const Abeta_n = 0.125
	
    const Kbeta_n = -80
    const V0beta_n = -36
    
    const gbar_KV  = 0.032

    function alpha_n(v) 
	(Q10 * Aalpha_n * linoid ((v - V0alpha_n), Kalpha_n))
    end
    
    function beta_n (v) 
	(Q10 * Abeta_n * exp((v - V0beta_n) / Kbeta_n) )
    end

    n   = Gate(value(alpha_n (v) / (alpha_n (v) + beta_n (v))))
    g_KV = Conductance (value(n^4 * gbar_KV))
    
    @equations begin
        der(n) =  alpha_n(v) * (1 - n) - beta_n(v) * n

        g_KV  = n^4 * gbar_KV
	      
        I_KV  = g_KV  * (v - E_K)
    end
    
end


function SK2_model(v,cai,I_SK2)

    const Q10 = 3^((celsius - 23) / 10)
		 
    const diff = 3
		 
    const invc1 = 80e-3
    const invc2 = 80e-3
    const invc3 = 200e-3

    const invo1 = 1
    const invo2 = 100e-3
    const diro1 = 160e-3
    const diro2 = 1.2

    const dirc2 = 200
    const dirc3 = 160
    const dirc4 = 80

    const invc1_t = invc1 * Q10
    const invc2_t = invc2 * Q10
    const invc3_t = invc3 * Q10
    const invo1_t = invo1 * Q10
    const invo2_t = invo2 * Q10
    const diro1_t = diro1 * Q10
    const diro2_t = diro2 * Q10
    const dirc2_t = dirc2 * Q10
    const dirc3_t = dirc3 * Q10
    const dirc4_t = dirc4 * Q10

    const gbar_SK2 = 0.038
    
    dirc2_t_ca = Unknown(value(dirc2_t * (cai / diff)))
    dirc3_t_ca = Unknown(value(dirc3_t * (cai / diff)))
    dirc4_t_ca = Unknown(value(dirc4_t * (cai / diff)))

    c1 = Gate(0.2)
    c2 = Gate(0.2)
    c3 = Gate(0.2)
    c4 = Gate(0.2)
    o1 = Gate(0.1)
    o2 = Gate(0.1)
    
    z_reactions = parse_reactions (Any [
                                     
                                        [ :⇄ c1 c2 dirc2_t_ca invc1_t ]
                                        [ :⇄ c2 c3 dirc3_t_ca invc2_t ]
                                        [ :⇄ c3 c4 dirc4_t_ca invc3_t ]
                                        [ :⇄ c3 o1 diro1_t invo1_t ]
                                        [ :⇄ c4 o2 diro2_t invo2_t ]
                                        
                                        ])

    conservation = Unknown()
    
    g_SK2 = Conductance (value((o1 + o2) * gbar_SK2))

    @equations begin

        dirc2_t_ca = (dirc2_t * (cai / diff))
        dirc3_t_ca = (dirc3_t * (cai / diff)) 
        dirc4_t_ca = (dirc4_t * (cai / diff))

        z_reactions

        conservation = (c1 + c2 + c3 + c4 + o2 + o1) - 1
        
        g_SK2  = (o1 + o2) * gbar_SK2
	      
        I_SK2  = g_SK2  * (v - E_K)
        
    end

    
end


## Sodium current
function Na_model(v,I_Na)

    function linoid (x, y) 
	ifelse (abs (x / y) < 1e-6,
	        y * (1 - ((x / y) / 2)),
	        x / (1 - exp (x / y) ))
    end

    const Q10 = 3^((celsius - 20) / 10)

    const Aalpha_u  = 0.3
    const Kalpha_u  = -10
    const V0alpha_u = -25
	
    const Abeta_u  = 12
    const Kbeta_u  = -18.182
    const V0beta_u = -50

    const Aalpha_v  = 0.21
    const Kalpha_v  = -3.333
    const V0alpha_v = -50
 
    const Abeta_v  = 3
    const Kbeta_v  = -5
    const V0beta_v = -17

    gbar_Na  = 0.048
    
    function alpha_m (v)	
	(Q10 * Aalpha_u * linoid((v - V0alpha_u), Kalpha_u) )
    end

    function beta_m (v)
	(Q10 * Abeta_u * exp((v - V0beta_u) / Kbeta_u) )
    end

    function alpha_h (v)
	(Q10 * Aalpha_v * exp((v - V0alpha_v) / Kalpha_v) )
    end
				
    function beta_h (v)
	(Q10 * Abeta_v / (1 + exp((v - V0beta_v) / Kbeta_v) ))
    end
    
    m   = Gate(value(alpha_m (v) / (alpha_m(v) + beta_m(v))))
    h   = Gate(value(alpha_h (v) / (alpha_h(v) + beta_h(v))))
    g_Na = Conductance (value(m^3 * h * gbar_Na))
    
    @equations begin
        der(m) =  alpha_m(v) * (1 - m) - beta_m(v) * m
        der(h) =  alpha_h(v) * (1 - h) - beta_h(v) * h

        g_Na  = m^3 * h * gbar_Na
	      
        I_Na  = g_Na  * (v - E_Na)
    end
end


## pNa current

function pNa_model(v,I_pNa)

    const Q10 = 3^((celsius - 30) / 10)
    
    const Aalpha_m  = -0.91
    const Kalpha_m  = -5
    const V0alpha_m = -40
    const Abeta_m   = 0.62
    const Kbeta_m   = 5
    const V0beta_m  = -40
    const V0_minf   = -43
    const B_minf    = 5
    
    const gbar_pNa  = 0.00019

    function alpha_m (v)
	(Q10 * Aalpha_m * linoid( (v - V0alpha_m), Kalpha_m))
    end

    function beta_m (v)
	(Q10 * Abeta_m * linoid ( (v - V0beta_m), Kbeta_m) )
    end
    
    m   = Gate(value(1 / (1 + exp ((- (v - V0_minf)) / B_minf))))
    g_pNa = Conductance (value(m * gbar_pNa))

    m_inf   = Unknown(value(1 / (1 + exp((- (v - V0_minf)) / B_minf))))
    tau_m   = Unknown(value(5 / (alpha_m(v) + beta_m(v))))
    
    @equations begin
        
        der(m) = (m_inf - m) / tau_m

	m_inf =  (1 / (1 + exp((- (v - V0_minf)) / B_minf)))
	tau_m =  (5 / (alpha_m(v) + beta_m(v)))

        g_pNa  = m * gbar_pNa
	      
        I_pNa  = g_pNa  * (v - E_Na)
    end
end

## NaR current

function NaR_model(v,I_NaR)

    const Q10 = 3^((celsius - 20) / 10)

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

    function alpha_s (v) 
	(Q10 * (Shiftalpha_s + (Aalpha_s * ((v + V0alpha_s) / (exp ((v + V0alpha_s) / Kalpha_s) - 1)))))
    end

    function beta_s (v) 
	(Q10 * (Shiftbeta_s + Abeta_s * ((v + V0beta_s) / (exp((v + V0beta_s) / Kbeta_s) - 1))))
    end

    function alpha_f (v) 
	(Q10 * Aalpha_f * exp( ( v - V0alpha_f ) / Kalpha_f))
    end

    function beta_f (v) 
	(Q10 * Abeta_f * exp( ( v - V0beta_f ) / Kbeta_f )  )
    end
    
    gbar_NaR  = 0.0017
    
    s   = Gate(value(alpha_s (v) / (alpha_s(v) + beta_s(v))))
    f   = Gate(value(alpha_f (v) / (alpha_f(v) + beta_f(v))))
    g_NaR = Conductance (value(s * f * gbar_NaR))
    
    @equations begin
        der(s) =  alpha_s(v) * (1 - s) - beta_s(v) * s
        der(f) =  alpha_f(v) * (1 - f) - beta_f(v) * f

        g_NaR  = s * f * gbar_NaR
	      
        I_NaR  = g_NaR  * (v - E_Na)
    end
end



## Leak current

function Lkg_model(v,I_Leak)
    g_Leak  = 21e-6
    E_Leak = -55
   @equations begin
       I_Leak  = g_Leak  * (v - E_Leak)
   end
end

function CGoC(I)

    v = Voltage (-65.0, "v")   

    cai = Unknown (cai0, "cai")
    ca2i = Unknown (cai0, "ca2i")
    E_Ca = Unknown ()
    E_Ca2 = Unknown ()
    
    I_stim = Discrete (0.0)

    I_Ca  = Current ()
    I_Ca2 = Current ("I_Ca2")
    I_K   = Current ()
    I_L   = Current ()
    I_H   = Current ()

    I_CaHVA = Current ()
    I_CaLVA = Current ()

    I_KCa  = Current ()
    I_KA   = Current ()
    I_KV   = Current ()
    I_KM   = Current ()
    I_SK2  = Current ()

    I_Na   = Current ()
    I_NaR  = Current ()
    I_pNa  = Current ()

    I_HCN1  = Current ()
    I_HCN2  = Current ()
    I_Leak  = Current ()

    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        Ca_model(cai,I_Ca)
        Ca2_model(ca2i,I_Ca2)
        E_Ca_model(E_Ca,cai)
        E_Ca2_model(E_Ca2,ca2i)
        CaHVA_model(v,I_CaHVA,E_Ca)
        CaLVA_model(v,I_CaLVA,E_Ca2)

        KA_model(v,I_KA)
        KV_model(v,I_KV)
        KM_model(v,I_KM)
        KCa_model(v,cai,I_KCa)
        SK2_model(v,cai,I_SK2)

        Na_model(v,I_Na)
        NaR_model(v,I_NaR)
        pNa_model(v,I_pNa)

        HCN1_model(v,I_HCN1)
        HCN2_model(v,I_HCN2)
        Lkg_model(v,I_Leak)

        I_Ca = I_CaHVA
        I_Ca2 = I_CaLVA
        I_K = I_KV + I_KA + I_KM + I_SK2 + I_KCa
        I_L = I_Leak
        I_H = I_HCN1 + I_HCN2
        
        der(v) = ((I_stim * (100.0 / area)) - 1e3 * (I_Ca + I_Ca2 + I_K + I_Na + I_NaR + I_pNa + I_H )) / C_m

        Event(MTime - 250.0,     # Start injecting current after 250 ms
              Equation[
                   reinit(I_stim, I)
               ],
               Equation[])

    end
end


cgoc   = CGoC(0.0)  # returns the hierarchical model
cgoc_f = elaborate(cgoc)    # returns the flattened model
cgoc_s = create_sim(cgoc_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 1500.0
dt = 0.025

@time cgoc_yout = sunsim(cgoc_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-6, abstol=1e-6)

##@time cgoc_yout = sim(cgoc_s, tf, int(tf/dt))

wplot (cgoc_yout)
