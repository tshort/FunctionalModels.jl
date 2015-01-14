##
## Model of a cerebellar granule cell from the paper:
##
## _Theta-Frequency Bursting and Resonance in Cerebellar Granule Cells:
## Experimental Evidence and Modeling of a Slow K+-Dependent
## Mechanism_.  E. D'Angelo, T. Nieus, A. Maffei, S. Armano, P. Rossi,
## V. Taglietti, A. Fontana and G. Naldi.
##


using Sims
using Sims.Lib
using Winston


function sigm (x, y)
    return 1.0 / (exp (x / y) + 1)
end

function linoid (x, y) 
    return ifelse (abs (x / y) < 1e-6, (y * (1 - ((x/y) / 2))), (x / (exp (x/y) - 1)))
end

F = 96485.3

celsius = 30
C_m = 1.0

## Soma dimensions

L = 11.8
diam = 11.8
area = pi * L * diam

## Reversal potentials

E_Ca = 129.33
E_K  = -84.69
E_Na  = 87.39


## Calcium concentration dynamics
cai0  = 1e-4

function Ca_model(cai,I_Ca)

    depth = 0.2
    cao   = 2.0
    beta  = 1.5

    @equations begin

        der(cai) = ((- (I_Ca) / (2 * F * depth)) * 1e4 -
		    (beta * (ifelse(cai < cai0, cai0, cai) - cai0)))
    end
end

## High-voltage activated calcium current 

function CaHVA_model(v,I_CaHVA)

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

    gbar_CaHVA  = 0.00046

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

    s = Unknown (value(alpha_s(v) / (alpha_s(v) + beta_s(v))))
    u = Unknown (value(alpha_u(v) / (alpha_u(v) + beta_u(v))))
    g_CaHVA = Unknown (value(s^2 * u * gbar_CaHVA))
    
    @equations begin
        der(s) =  alpha_s(v) * (1 - s) - beta_s(v) * s
        der(u) =  alpha_u(v) * (1 - s) - beta_u(v) * s

        g_CaHVA  = s^2 * u * gbar_CaHVA
	      
        I_CaHVA  = g_CaHVA  * (v - E_Ca)
    end
end

## KA current

function KA_model(v,I_KA)

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

    gbar_KA = 0.004
			 
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

    a = Unknown(value(1 / (1 + exp ((v - V0_ainf) / K_ainf))))
    b = Unknown(value(1 / (1 + exp ((v - V0_binf) / K_binf))))

    a_inf   = Unknown(value(1 / (1 + exp ((v - V0_ainf) / K_ainf))))
    b_inf   = Unknown(value(1 / (1 + exp ((v - V0_binf) / K_binf))))

    tau_a   = Unknown(value(1 / (alpha_a (v) + beta_a (v))))
    tau_b   = Unknown(value(1 / (alpha_b (v) + beta_b (v))))

    g_KA = Unknown (value(a^3 * b * gbar_KA))

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

    Q10 = 3^((celsius - 30) / 10)
		 
    Aalpha_c = 2.5
    Balpha_c = 1.5e-3
		 
    Kalpha_c =  -11.765
		 
    Abeta_c = 1.5
    Bbeta_c = 0.15e-3

    Kbeta_c = -11.765

    function alpha_c (v, cai)
	(Q10 * Aalpha_c / (1 + (Balpha_c * exp(v / Kalpha_c) / cai)))
    end
		 
    function beta_c (v, cai)
	(Q10 * Abeta_c / (1 + (cai / (Bbeta_c * exp (v / Kbeta_c))) ))
    end

    gbar_KCa  = 0.003

    c = Unknown(value(alpha_c (v, cai) / (alpha_c (v, cai) + beta_c (v, cai))))
    g_KCa = Unknown (value(c * gbar_KCa))
    
    @equations begin
        der(c) =  alpha_c(v, cai) * (1 - c) - beta_c(v, cai) * c

        g_KCa  = c * gbar_KCa
	      
        I_KCa  = g_KCa  * (v - E_K)
    end
    
end

## Kir current

function Kir_model(v,I_Kir)

    Q10 = 3^((celsius - 20) / 10)

    Aalpha_d = 0.13289
    Kalpha_d = -24.3902

    V0alpha_d = -83.94
    Abeta_d   = 0.16994
    
    Kbeta_d = 35.714
    V0beta_d = -83.94
   
    function alpha_d (v)
	(Q10 * Aalpha_d * exp((v - V0alpha_d) / Kalpha_d))
    end
			 
    function beta_d (v)
	(Q10 * Abeta_d * exp((v - V0beta_d) / Kbeta_d) )
    end

    gbar_Kir  = 0.0009

    d   = Unknown(value(alpha_d (v) / (alpha_d(v) + beta_d(v))))
    g_Kir = Unknown (value(d * gbar_Kir))
    
    @equations begin
        der(d) =  alpha_d(v) * (1 - d) - beta_d(v) * d

        g_Kir  = d * gbar_Kir
	      
        I_Kir  = g_Kir  * (v - E_K)
    end
    
end

## KM current

function KM_model(v,I_KM)

    Q10 = 3^((celsius - 22) / 10)

    Aalpha_n = 0.0033

    Kalpha_n  = 40
    V0alpha_n = -30
    Abeta_n   = 0.0033
    
    Kbeta_n  = -20
    V0beta_n = -30
    V0_ninf  = -30
    B_ninf = 6

    gbar_KM  = 0.00035

    function alpha_n (v)
	(Q10 * Aalpha_n * exp((v - V0alpha_n) / Kalpha_n) )
    end

    function beta_n (v)
	(Q10 * Abeta_n * exp((v - V0beta_n) / Kbeta_n) )
    end

    n   = Unknown(value(alpha_n (v) / (alpha_n(v) + beta_n(v))))
    g_KM = Unknown (value(n * gbar_KM))

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

    Q10 = 3^((celsius - 6.3) / 10)


    Aalpha_n = -0.01
    Kalpha_n = -10
    V0alpha_n = -25
    Abeta_n = 0.125
	
    Kbeta_n = -80
    V0beta_n = -35
    
    gbar_KV  = 0.003

    function alpha_n(v) 
	(Q10 * Aalpha_n * linoid ((v - V0alpha_n), Kalpha_n))
    end
    
    function beta_n (v) 
	(Q10 * Abeta_n * exp((v - V0beta_n) / Kbeta_n) )
    end

    n   = Unknown(value(alpha_n (v) / (alpha_n (v) + beta_n (v))))
    g_KV = Unknown (value(n^4 * gbar_KV))
    
    @equations begin
        der(n) =  alpha_n(v) * (1 - n) - beta_n(v) * n

        g_KV  = n^4 * gbar_KV
	      
        I_KV  = g_KV  * (v - E_K)
    end
    
end


## Sodium current
function Na_model(v,I_Na)

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

    gbar_Na  = 0.013
    
    function alpha_m (v)	
	(Q10 * Aalpha_m * linoid((v - V0alpha_m), Kalpha_m) )
    end

    function beta_m (v)
	(Q10 * Abeta_m * exp((v - V0beta_m) / Kbeta_m) )
    end

    function alpha_h (v)
	(Q10 * Aalpha_h * exp((v - V0alpha_h) / Kalpha_h) )
    end
				
    function beta_h (v)
	(Q10 * Abeta_h / (1 + exp((v - V0beta_h) / Kbeta_h) ))
    end
    
    m   = Unknown(value(alpha_m (v) / (alpha_m(v) + beta_m(v))))
    h   = Unknown(value(alpha_h (v) / (alpha_h(v) + beta_h(v))))
    g_Na = Unknown (value(m^3 * h * gbar_Na))
    
    @equations begin
        der(m) =  alpha_m(v) * (1 - m) - beta_m(v) * m
        der(h) =  alpha_h(v) * (1 - h) - beta_h(v) * h

        g_Na  = m^3 * h * gbar_Na
	      
        I_Na  = g_Na  * (v - E_Na)
    end
end


## NaR current

function NaR_model(v,I_NaR)

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
    
    gbar_NaR  = 0.0005
    
    s   = Unknown(value(alpha_s (v) / (alpha_s(v) + beta_s(v))))
    f   = Unknown(value(alpha_f (v) / (alpha_f(v) + beta_f(v))))
    g_NaR = Unknown (value(s * f * gbar_NaR))
    
    @equations begin
        der(s) =  alpha_s(v) * (1 - s) - beta_s(v) * s
        der(f) =  alpha_f(v) * (1 - f) - beta_f(v) * f

        g_NaR  = s * f * gbar_NaR
	      
        I_NaR  = g_NaR  * (v - E_Na)
    end
end



## pNa current

function pNa_model(v,I_pNa)

    Q10 = 3^((celsius - 30) / 10)
    
    Aalpha_m  = -0.091
    Kalpha_m  = -5
    V0alpha_m = -42
    Abeta_m   = 0.062
    Kbeta_m   = 5
    V0beta_m  = -42
    V0_minf   = -42
    B_minf    = 5
    
    gbar_pNa  = 2e-5

    function alpha_m (v)
	(Q10 * Aalpha_m * linoid( (v - V0alpha_m), Kalpha_m))
    end

    function beta_m (v)
	(Q10 * Abeta_m * linoid ( (v - V0beta_m), Kbeta_m) )
    end
    
    m   = Unknown(value(1 / (1 + exp ((- (v - V0_minf)) / B_minf))))
    g_pNa = Unknown (value(m * gbar_pNa))

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

## Leak currents

g_Leak1  = 5.68e-5
E_Leak1 = -16.5

g_Leak2  = 3e-5
E_Leak2 = -65


function Lkg1_model(v,I_Leak1)
   @equations begin
       I_Leak1  = g_Leak1  * (v - E_Leak1)
   end
end

function Lkg2_model(v,I_Leak2)
   @equations begin
       I_Leak2  = g_Leak2  * (v - E_Leak2)
   end
end

function CGC(I)

    v   = Voltage (-70.0, "v")   

    cai = Unknown (cai0, "cai")

    I_Ca = Current ()
    I_K  = Current ()
    I_L  = Current ()

    I_CaHVA = Current ()

    I_KCa  = Current ()
    I_KA   = Current ()
    I_KV   = Current ()
    I_KM   = Current ()
    I_Kir  = Current ()

    I_Na   = Current ()
    I_NaR  = Current ()
    I_pNa  = Current ()

    I_Leak1  = Current ()
    I_Leak2  = Current ()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        Ca_model(cai,I_Ca)
        CaHVA_model(v,I_CaHVA)

        KA_model(v,I_KA)
        KV_model(v,I_KV)
        KCa_model(v,cai,I_KCa)
        Kir_model(v,I_Kir)
        KM_model(v,I_KM)

        Na_model(v,I_Na)
        NaR_model(v,I_NaR)
        pNa_model(v,I_pNa)

        Lkg1_model(v,I_Leak1)
        Lkg2_model(v,I_Leak2)

        I_Ca = I_CaHVA
        I_K = I_KA + I_KV + I_KCa + I_Kir  + I_KM
        I_L = I_Leak1 + I_Leak2
        
        der(v) = ((I * (100.0 / area)) - 1e3 * (I_Ca + I_K + I_Na + I_NaR + I_pNa + I_L)) / C_m
        
    end
end


cgc   = CGC(18.75)  # returns the hierarchical model
cgc_f = elaborate(cgc)    # returns the flattened model
cgc_s = create_sim(cgc_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 500.0
dt = 0.025

@time cgc_yout = sunsim(cgc_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-7, abstol=1e-7)

##@time cgc_yout = sim(cgc_s, tf, int(tf/dt))

plot (cgc_yout.y[:,1], cgc_yout.y[:,3])
