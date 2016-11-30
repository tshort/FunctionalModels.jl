
###########################################
## Cerebellar Purkinje neuron model 
###########################################

module Purkinje

using Sims, Sims.Lib
using Sims.Examples.Neural, Sims.Examples.Neural.Lib
using Docile


## Calcium concentration dynamics
const cai0 = 1e-4
const cao   = 2.4

function CaConcentration(cai,I_Ca)

    depth = 0.1
    beta  = 1.0

    @equations begin

        der(cai) = ((- (I_Ca) / (2 * cai0 * F * depth)) * 1e4 -
		    (beta * (ifelse(cai < cai0, cai0, cai))))
    end
end

## HH P-type Calcium permeability
function CaPPermeability(v,cai,pcabar,p)
              
    function minf (v)
        let cv = -19.0
            ck =  5.5
	    (1.0 / (1.0 + exp (- ((v - cv) / ck))))
        end
    end

    function mtau (v)
        ((1e3) * (ifelse(v > -50.0,
                         (0.000191 + (0.00376 * exp (- (((v + 41.9) / 27.8) ^ 2)))),
                         (0.00026367 + (0.1278 * exp (0.10327 * v))))))
    end

    
    m_inf = Unknown(value(minf(v)))
    tau_m = Unknown(value(mtau(v)))
    m = Gate(value(minf(v)))

    @equations begin

        der(m) = (m_inf - m) / tau_m

	m_inf =  minf(v)
	tau_m =  mtau(v)

        p  = m * pcabar
    end

end


    
## BK-type Purkinje calcium-activated potassium current
function CaBKConductance(v,cai,gbar,g)
    
    function minf (v) 
        let vh = -28.9
	    k  =  6.2
            (1.0 / (1.0 + exp (- ((v - vh) / k))))
        end
    end

    function mtau (v) 
        let y0  = 0.000505
            vh1 = -33.3
            k1  = -10.0
            vh2 = 86.4
            k2  =   10.1
	    ((1e3) * (y0 + 1 / (exp ((v + vh1) / k1) + 
                                exp ((v + vh2) / k2))))
        end
    end

    
    function hinf (v) 
        let 
            y0 = 0.085
            vh =  -32.0
            k  =  5.8
	    (y0 + (1 - y0) / (1 + exp ((v - vh) / k)))
        end
    end
                              
               
    function htau (v) 
        let
            y0  = 0.0019
            vh1 =  -54.2
            k1  =  -12.9
            vh2 =   48.5
            k2  =    5.2
	    ((1e3) * (y0 + 1 / (exp ((v + vh1) / k1) + exp ((v + vh2) / k2))))
        end
    end

    function zinf (cai)
        let k = 0.001
            
	    (1 / (1 + (k / cai)))
        end
    end
    
    CaBK_v = (v + 5)

    m_inf = Unknown(value(minf(CaBK_v)))
    tau_m = Unknown(value(mtau(CaBK_v)))
    m = Gate(value(minf(CaBK_v)))
    
    h_inf = Unknown(value(hinf(CaBK_v)))
    tau_h = Unknown(value(htau(CaBK_v)))
    h = Gate(value(hinf(CaBK_v)))

    ztau = 1.0
    zk = 0.001
    z_alpha = Unknown(value(zinf(cai) / ztau))
    z_beta = Unknown(value(1 - zinf(cai)) / ztau)
    z = Gate(1 / (1 + zk / cai0))

    zO = Gate(0.5)
    zC = Gate(0.5)

    z_reactions = parse_reactions (Any
                                   [
                                    [ :-> zO zC z_alpha ]
                                    [ :-> zC zO z_beta ]
                                   ])
    conservation = Unknown()

    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m
        der(h) =  (h_inf - h) / tau_h

        m_inf = minf(CaBK_v)
        tau_m = mtau(CaBK_v)
        
        h_inf = hinf(CaBK_v)
        tau_h = htau(CaBK_v)

        z_alpha = zinf(cai) / ztau
        z_beta  = (1 - zinf(cai)) / ztau

        z_reactions
        conservation = (zO + zC) - 1
        
        z = zO
        
        g  = m^3 * h * z^2 * gbar
	      
    end
end

## HH TEA-sensitive Purkinje potassium current
function K1Conductance(v,gbar,g)
    
    function minf (v)
        let mivh = -24
	    mik =  15.4
            (1 / (1 + exp (- (v - mivh) / mik)))
        end
    end

    function mtau (v)
        let mty0  = 0.00012851
	    mtvh1 = 100.7
	    mtk1  = 12.9
	    mtvh2 = -56.0
	    mtk2  = -23.1
            return 1e3 * (ifelse (v < -35, 
                                  (3.0 * (3.4225e-5 + 0.00498 * exp (- (v) / -28.29))),
                                  (mty0 + 1.0 / (exp ((v + mtvh1) / mtk1) + exp ((v + mtvh2) / mtk2)))))
        end
    end

    function hinf (v) 
        let hiy0 =  0.31
	    hiA  =   0.78
	    hivh =  -5.802
	    hik  =   11.2
            return hiy0 + hiA / (1 + exp ((v - hivh) / hik))
        end
    end

    function htau (v)
        1e3 * (ifelse (v > 0,
                       0.0012 + 0.0023 * exp (-0.141 * v),
                       1.2202e-05 + 0.012 * exp (- (((v - (-56.3)) / 49.6) ^ 2))))
    end

    
    K1_v = (v + 11)


    m_inf = Unknown(value(minf(K1_v)))
    tau_m = Unknown(value(mtau(K1_v)))
    m = Gate(value(minf(K1_v)))
    
    h_inf = Unknown(value(hinf(K1_v)))
    tau_h = Unknown(value(htau(K1_v)))
    h = Gate(value(hinf(K1_v)))

    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m
        der(h) =  (h_inf - h) / tau_h

        m_inf = minf(K1_v)
        tau_m = mtau(K1_v)
        
        h_inf = hinf(K1_v)
        tau_h = htau(K1_v)
        
        g  = m^3 * h * gbar
	      
    end
end

## HH Low TEA-sensitive Purkinje potassium current
function K2Conductance(v,gbar,g)
    
    function minf (v)
        let mivh = -24
	    mik =  20.4
            (1 / (1 + exp (- (v - mivh) / mik)))
        end
    end

    function mtau (v)
        return (1e3) * (ifelse (v < -20,
                                (0.000688 + 1 / (exp ((v + 64.2) / 6.5) + exp ((v - 141.5) / -34.8))),
                                (0.00016 + 0.0008 * exp (-0.0267 * v))))
    end
    
    K2_v = (v + 11)


    m_inf = Unknown(value(minf(K2_v)))
    tau_m = Unknown(value(mtau(K2_v)))
    m = Gate (value(minf(K2_v)))
    
    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m

        m_inf = minf(K2_v)
        tau_m = mtau(K2_v)
        
        g  = m^4 * gbar

    end
end


## HH slow TEA-insensitive Purkinje potassium current
function K3Conductance(v,gbar,g)
    
    function minf (v)
        let mivh = -16.5
	    mik  =  18.4
            (1 / (1 + exp (- (v - mivh) / mik)))
        end
    end

    function mtau (v)
        return (1e3) * (0.000796 + 1.0 / (exp ((v + 73.2) / 11.7) + exp ((v - 306.7) / -74.2)))
    end
    
    K3_v = (v + 11)

    m_inf = Unknown(value(minf(K3_v)))
    tau_m = Unknown(value(mtau(K3_v)))
    m = Gate (value(minf(K3_v)))
    
    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m

        m_inf = minf(K3_v)
        tau_m = mtau(K3_v)
        
        g  = m^4 * gbar
    end
end

## Resurgent sodium current
function NarsgConductance(v,gbar,g)

    const Con   = 0.005
    const Coff  = 0.5
    const Oon   = 0.75
    const Ooff  = 0.005

    const alfac = ((Oon / Con) ^ (1.0 / 4.0))
    const btfac = (((Ooff / Coff) ^ (1.0 / 4.0)))
                         
    const alpha = 150
    const beta  = 3
    const gamma = 150
    const delta = 40
    const epsilon = 1.75
    const zeta = 0.03
    const x1 = 20
    const x2 = -20
    const x3 = 1e12
    const x4 = -1e12
    const x5 = 1e12
    const x6 = -25

                         
    f01 = (4.0 * alpha * exp (v / x1))
    f02 = (3.0 * alpha * exp (v / x1))
    f03 = (2.0 * alpha * exp (v / x1))
    f04 = (alpha * exp (v / x1))
    f0O = (gamma * exp (v / x3))
    fip = (epsilon * exp (v / x5))
    f11 = (4.0 * alpha * alfac * exp (v / x1))
    f12 = (3.0 * alpha * alfac * exp (v / x1))
    f13 = (2.0 * alpha * alfac * exp (v / x1))
    f14 = (alpha * alfac * exp (v / x1))
    f1n = (gamma * exp (v / x3))
                         
    fi1 = (Con)
    fi2 = (Con * alfac)
    fi3 = (Con * alfac * alfac)
    fi4 = (Con * alfac * alfac * alfac)
    fi5 = (Con * alfac * alfac * alfac * alfac)
    fin = (Oon)
		 
    b01 = (beta * exp (v / x2))
    b02 = (2.0 * beta * exp (v / x2))
    b03 = (3.0 * beta * exp (v / x2))
    b04 = (4.0 * beta * exp (v / x2))
    b0O = (delta * exp (v / x4))
    bip = (zeta * exp (v / x6))
                         
    b11 = (beta * btfac * exp (v / x2))
    b12 = (2.0 * beta * btfac * exp (v / x2))
    b13 = (3.0 * beta * btfac * exp (v / x2))
    b14 = (4.0 * beta * btfac * exp (v / x2))
    b1n = (delta * exp (v / x4))
                         
    bi1 = (Coff)
    bi2 = (Coff * btfac)
    bi3 = (Coff * btfac * btfac)
    bi4 = (Coff * btfac * btfac * btfac)
    bi5 = (Coff * btfac * btfac * btfac * btfac)
    bin = (Ooff)

    I1 = Gate()
    I2 = Gate()
    I3 = Gate()
    I4 = Gate()
    I5 = Gate()
    I6 = Gate()
    C1 = Gate(0.5)
    C2 = Gate(0.2)
    C3 = Gate(0.1)
    C4 = Gate(0.1)
    C5 = Gate(0.1)
    O  = Gate()
    B  = Gate()
    
    z_reactions = parse_reactions (Any [
                                     
                                     [ :⇄ C1 C2 f01 b01 ]
                                     [ :⇄ C2 C3 f02 b02 ]
                                     [ :⇄ C3 C4 f03 b03 ]
                                     [ :⇄ C4 C5 f04 b04 ]
                                     [ :⇄ C5 O  f0O b0O ]
                                     [ :⇄ O  B  fip bip ]
                                     [ :⇄ O  I6 fin bin ]
                                     [ :⇄ C1 I1 fi1 bi1 ]
                                     [ :⇄ C2 I2 fi2 bi2 ]
                                     [ :⇄ C3 I3 fi3 bi3 ]
                                     [ :⇄ C4 I4 fi4 bi4 ]
                                     [ :⇄ C5 I5 fi5 bi5 ]
                                     [ :⇄ I1 I2 f11 b11 ]
                                     [ :⇄ I2 I3 f12 b12 ]
                                     [ :⇄ I3 I4 f13 b12 ]
                                     [ :⇄ I4 I5 f14 b14 ]
                                     [ :⇄ I5 I6 f1n b1n ]
                                     
                                     ])
    conservation = Unknown()
    
    @equations begin

        z_reactions

        conservation = (I1 + I2 + I3 + I4 + I5 + I6 + C1 + C2 + C3 + C4 + C5 + O + B) - 1
        
        g  = O * gbar
	      
    end

end


function IhConductance(v,gbar,g)
              
    function minf (v)
        1.0 / (1.0 + exp ((v + 90.1) / 9.9))
    end
			 
    function mtau (v)
        (1e3) * (0.19 + 0.72 * exp (- (((v - (-81.5)) / 11.9) ^ 2)))
    end


    m = Gate(value(minf(v)))
    
    @equations begin

        der(m) =  (minf(v) - m) / mtau(v)

        g = m * gbar
   end
    
end



"""
Model of a cerebellar Purkinje cell from the paper:

Cerebellar Purkinje Cell: resurgent Na current and high frequency
firing (Khaliq et al 2003).
"""

function Soma(;
              I   = 0.01,
              C_m = 1e-3,

              celsius = 22.0,
              
              ## Soma dimensions
              L = 20.0,
              diam = 20.0,
              area = pi * L * diam,

              ## Reversal potentials
              E_Na   = 60,
              E_K    = -88,
              E_Ih   = -30,
              E_Leak = -65,

              pcabar    = 0.00005,
              gbar_CaBK = 0.007,
              gbar_K1   = 0.004,
              gbar_K2   = 0.002,
              gbar_K3   = 0.004,
              gbar_Ih   = 0.0001,
              gbar_Na   = 0.015,
              g_Leak    = 5e-5,

              v::Unknown = Voltage (-65.0, "v"))
    
    cai = Unknown (cai0, "cai")

    p_CaP  = Unknown ()
    g_CaBK = Conductance ()
    g_K1   = Conductance ()
    g_K2   = Conductance ()
    g_K3   = Conductance ()
    g_Na   = Conductance ()
    g_Ih   = Conductance ()

    I_Ca    = Current ()
    I_CaP   = Current ()
    I_CaBK  = Current ()
    I_K     = Current ()
    I_K1    = Current ()
    I_K2    = Current ()
    I_K3    = Current ()
    I_Na    = Current ()
    I_Leak  = Current ()
    Ih      = Current ()

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        MembranePotential(v, Equation[-(I * (100.0 / area)),I_Leak,Ih,I_Na,I_K,I_Ca], C_m)

        CaConcentration(cai,I_Ca)
        CaPPermeability(v,cai,pcabar,p_CaP)
        CaBKConductance(v,cai,gbar_CaBK,g_CaBK)
        K1Conductance(v,gbar_K1,g_K1)
        K2Conductance(v,gbar_K2,g_K2)
        K2Conductance(v,gbar_K3,g_K3)
        NarsgConductance(v,gbar_Na,g_Na)
        IhConductance(v,gbar_Ih,g_Ih)

        I_Ca = I_CaP
        I_K  = I_K1 + I_K2 + I_K3 + I_CaBK

        GHKCurrent (celsius, v, I_CaP, p_CaP, cai, cao, 2.0)
        OhmicCurrent (v, I_CaBK, g_CaBK, E_K)
        OhmicCurrent (v, I_K1, g_K1, E_K)
        OhmicCurrent (v, I_K2, g_K2, E_K)
        OhmicCurrent (v, I_K3, g_K3, E_K)
        OhmicCurrent (v, I_Na, g_Na, E_Na)
        OhmicCurrent (v, Ih, g_Ih, E_Ih)
        OhmicCurrent (v, I_Leak, g_Leak, E_Leak)
        
    end
end

end # module Purkinje

