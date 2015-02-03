##
## Model of a cerebellar Purkinje cell from the paper:
##
## Cerebellar Purkinje Cell: resurgent Na current and high frequency
## firing (Khaliq et al 2003).
##

using Sims
using Sims.Lib
using Winston



const F = 96485.3
const R =  8.3145

function ghk (v, ci, co)
    let T = 22.0 + 273.19
        Z = 2.0
        E = (1e-3) * v
        k0 = ((Z * (F * E)) / (R * T))
        k1 = exp (- k0)
        k2 = ((Z ^ 2) * (E * (F ^ 2))) / (R * T)
        return (1e-6) * (ifelse (abs (1 - k1) < 1e-6,
                                 (Z * F * (ci - (co * k1)) * (1 - k0)),
                                 (k2 * (ci - (co * k1)) / (1 - k1))))
    end
end

const C_m = 1.0

## Soma dimensions

const L = 20.0
const diam = 20.0
const area = pi * L * diam

## Reversal potentials
const E_Na = 60
const E_K = -88


## Calcium concentration dynamics
const cai0 = 1e-4
const cao   = 2.4

function Ca_model(cai,I_Ca)

    depth = 0.1
    beta  = 1.0

    @equations begin

        der(cai) = ((- (I_Ca) / (2 * cai0 * F * depth)) * 1e4 -
		    (beta * (ifelse(cai < cai0, cai0, cai))))
    end
end

## HH P-type Calcium current
function CaP_model(v,cai,I_CaP)
              
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

    pcabar  = 0.00005
    
    m_inf = Unknown(value(minf(v)))
    tau_m = Unknown(value(mtau(v)))
    m = Unknown(value(minf(v)))

    @equations begin

        der(m) = (m_inf - m) / tau_m

	m_inf =  minf(v)
	tau_m =  mtau(v)

        I_CaP  = m * pcabar * ghk(v,cai,cao)
        
    end

end


    
## BK-type Purkinje calcium-activated potassium current
function CaBK_model(v,cai,I_CaBK)

    
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

    gbar_CaBK  = 0.007

    m_inf = Unknown(value(minf(CaBK_v)))
    tau_m = Unknown(value(mtau(CaBK_v)))
    m = Unknown (value(minf(CaBK_v)))
    
    h_inf = Unknown(value(hinf(CaBK_v)))
    tau_h = Unknown(value(htau(CaBK_v)))
    h = Unknown (value(hinf(CaBK_v)))

    ztau = 1.0
    zk = 0.001
    z_alpha = Unknown(value(zinf(cai) / ztau))
    z_beta = Unknown(value(1 - zinf(cai)) / ztau)
    z = Unknown (1 / (1 + zk / cai0))

    zO = NonNegativeUnknown(0.5)
    zC = NonNegativeUnknown(0.5)

    g_CaBK  = NonNegativeUnknown(value(m^3 * h * z^2 * gbar_CaBK))

    z_reactions = parse_reactions (Any
                                   [
                                    [ :-> zO zC z_alpha ]
                                    [ :-> zC zO z_beta ]
                                   ])
    ## TODO: conservation equation zO + zC = 1

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
        
        z = zO
        
        g_CaBK  = m^3 * h * z^2 * gbar_CaBK
	      
        I_CaBK  = g_CaBK  * (v - E_K)

    end
end

## HH TEA-sensitive Purkinje potassium current
function K1_model(v,I_K1)
    
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

    gbar_K1  = 0.004

    m_inf = Unknown(value(minf(K1_v)))
    tau_m = Unknown(value(mtau(K1_v)))
    m = Unknown (value(minf(K1_v)))
    
    h_inf = Unknown(value(hinf(K1_v)))
    tau_h = Unknown(value(htau(K1_v)))
    h = Unknown (value(hinf(K1_v)))

    g_K1  = NonNegativeUnknown(value(m^3 * h * gbar_K1))


    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m
        der(h) =  (h_inf - h) / tau_h

        m_inf = minf(K1_v)
        tau_m = mtau(K1_v)
        
        h_inf = hinf(K1_v)
        tau_h = htau(K1_v)
        
        g_K1  = m^3 * h * gbar_K1
	      
        I_K1  = g_K1  * (v - E_K)

    end
end

## HH Low TEA-sensitive Purkinje potassium current
function K2_model(v,I_K2)
    
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

    gbar_K2  = 0.002

    m_inf = Unknown(value(minf(K2_v)))
    tau_m = Unknown(value(mtau(K2_v)))
    m = Unknown (value(minf(K2_v)))
    
    g_K2  = NonNegativeUnknown(value(m^4 * gbar_K2))

    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m

        m_inf = minf(K2_v)
        tau_m = mtau(K2_v)
        
        g_K2  = m^4 * gbar_K2
	      
        I_K2  = g_K2  * (v - E_K)

    end
end


## HH slow TEA-insensitive Purkinje potassium current
function K3_model(v,I_K3)
    
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

    gbar_K3  = 0.004

    m_inf = Unknown(value(minf(K3_v)))
    tau_m = Unknown(value(mtau(K3_v)))
    m = Unknown (value(minf(K3_v)))
    
    g_K3  = NonNegativeUnknown(value(m^4 * gbar_K3))

    @equations begin
                               
        der(m) =  (m_inf - m) / tau_m

        m_inf = minf(K3_v)
        tau_m = mtau(K3_v)
        
        g_K3  = m^4 * gbar_K3
	      
        I_K3  = g_K3  * (v - E_K)

    end
end

## Resurgent sodium current
function Narsg_model(v,I_Na)

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

    gbar_Na  = 0.015
                         
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

    #I1 = Unknown(0.012)
    #I2 = Unknown(0.023)
    #I3 = Unknown(0.03)
    #I4 = Unknown(0.03)
    #I5 = Unknown(0.1)
    #I6 = Unknown(5e-6)
    #C1 = Unknown(0.62)
    #C2 = Unknown(0.21)
    #C3 = Unknown(0.027)
    #C4 = Unknown(0.001)
    #C5 = Unknown(3.3e-5)
    #O  = Unknown(1.7e-4)
    #B  = Unknown(0.007)

    I1 = NonNegativeUnknown()
    I2 = NonNegativeUnknown()
    I3 = NonNegativeUnknown()
    I4 = NonNegativeUnknown()
    I5 = NonNegativeUnknown()
    I6 = NonNegativeUnknown()
    C1 = NonNegativeUnknown(0.5)
    C2 = NonNegativeUnknown(0.2)
    C3 = NonNegativeUnknown(0.1)
    C4 = NonNegativeUnknown(0.1)
    C5 = NonNegativeUnknown(0.1)
    O  = NonNegativeUnknown()
    B  = NonNegativeUnknown()
    
    reaction = parse_reactions (Any [
                                     
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
    
    g_Na = NonNegativeUnknown(value(O * gbar_Na))
    
    @equations begin

        reaction

        ## TODO:  1 = (I1 + I2 + I3 + I4 + I5 + I6 + C1 + C2 + C3 + C4 + C5 + O + B)
        
        g_Na  = O * gbar_Na
	      
        I_Na  = g_Na  * (v - E_Na)

    end

end


function Ih_model(v,Ih)
              
                        
    function minf (v)
        1.0 / (1.0 + exp ((v + 90.1) / 9.9))
    end
			 
    function mtau (v)
        (1e3) * (0.19 + 0.72 * exp (- (((v - (-81.5)) / 11.9) ^ 2)))
    end

    gbar_Ih = 0.0001
    E_Ih = -30

    m = Unknown(value(minf(v)))
    g_Ih = NonNegativeUnknown(value(m * gbar_Ih))
    
    @equations begin

        der(m) =  (minf(v) - m) / mtau(v)

        g_Ih = m * gbar_Ih
        Ih  = g_Ih  * (v - E_Ih)
   end
    
end


function Leak_model(v,I_Leak)

    g_Leak  = 5e-5
    E_Leak = -65

    @equations begin
       I_Leak  = g_Leak  * (v - E_Leak)
   end
end


function Purkinje(I)

    v   = Voltage (-65.0, "v")   
    cai = Unknown (cai0, "cai")

    I_Ca    = Current ()
    I_CaP   = Current ()
    I_CaBK  = Current ()
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

        Ca_model(cai,I_Ca)
        CaP_model(v,cai,I_CaP)
        CaBK_model(v,cai,I_CaBK)
        K1_model(v,I_K1)
        K2_model(v,I_K2)
        K2_model(v,I_K3)
        Narsg_model(v,I_Na)
        Ih_model(v,Ih)
        Leak_model(v,I_Leak)

        I_Ca = I_CaP
        der(v) = ((I * (100.0 / area)) - 1e3 * (I_Leak + Ih + I_Na + I_K1 + I_K2 + I_K3 + I_CaBK + I_Ca)) / C_m
        
    end
end


cell   = Purkinje(5.0)  # returns the hierarchical model
cell_f = elaborate(cell)    # returns the flattened model
cell_s = create_sim(cell_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 500.0
dt = 0.025

@time cell_yout = dasslsim(cell_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-1, abstol=1e-4)


