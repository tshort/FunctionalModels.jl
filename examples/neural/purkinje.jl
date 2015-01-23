##
## Model of a cerebellar Purkinje cell from the paper:
##
## Cerebellar Purkinje Cell: resurgent Na current and high frequency
## firing (Khaliq et al 2003).
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

const F = 96485.3
const C_m = 1.0

## Soma dimensions

const L = 20.0
const diam = 20.0
const area = pi * L * diam

## Reversal potentials
const E_Na = 60
const E_K = -88


## Calcium concentration dynamics
const ca0 = 1e-4

function Ca_model(cai,I_Ca)

    depth = 0.1
    cao   = 2.4
    beta  = 1.0

    @equations begin

        der(cai) = ((- (I_Ca) / (2 * ca0 * F * depth)) * 1e4 -
		    (beta * (ifelse(cai < ca0, ca0, cai))))
    end
end

## BK-type Purkinje calcium-activated potassium current

function CaBK_model(v,I_CaBK)

    function minf (v) =
        let vh = -28.9
	    k  =  6.2
            (1.0 / (1.0 + exp (- ((v - vh) / k))))
        end
    end

    function mtau (v) =
        let
            y0  = 0.000505
            vh1 = -33.3
            k1  = -10.0
            vh2 = 86.4
            k2  =   10.1
	    ((1e3) * (y0 + 1 / (exp ((v + vh1) / k1) + 
                                exp ((v + vh2) / k2))))
        end
    end

    
    function hinf (v) =
        let 
            y0 = 0.085
            vh =  -32.0
            k  =  5.8
	    (y0 + (1 - y0) / (1 + exp ((v - vh) / k)))
        end
    end
                              
               
    function htau (v) =
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

    ztau = 1.0

    CaBK_v = (v + 5)

    z = parseReactionSystem
                        (reaction
			  (z
                           (transitions (<-> O C z_alpha z_beta))
                           (conserve  ((1 = (O + C))))
                           (initial   (let ((k 0.001)) 
                                        (1 / (1 + k / ca0))))
                           (open O)
                           (power 2)))
			 
                        (output z)
    
    @equations begin
                               
                               
        der(m) =  (m_inf - m) / tau_m
        der(h) =  (h_inf - h) / tau_h

        m_inf = minf(CaBK_v)
        m_tau = mtau(CaBK_v)
        
        h_inf = hinf(CaBK_v)
        h_tau = htau(CaBK_v)

        z_alpha = zinf / ztau
        z_beta  = (1 - zinf(cai)) / ztau
                               
        g_CaBK  = m^3 * h * z^2 * gbar_CaBK
	      
        I_CaBK  = g_CaBK  * (v - E_K)

    end
end


function Purkinje(I)

    v   = Voltage (-70.0, "v")   
    cai = Unknown (cai0, "cai")

    I_Ca    = Current ()
    I_CaBK  = Current ()
    I_Leak  = Current ()

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        CaBK_model(v,I_CaBK)
        Ca_model(cai,I_Ca)

        
        der(v) = ((I * (100.0 / area)) - 1e3 * (I_CaBK + I_Leak)) / C_m
        
    end
end


cell   = Purkinje(18.75)  # returns the hierarchical model
cell_f = elaborate(cell)    # returns the flattened model
cell_s = create_sim(cell_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
tf = 500.0
dt = 0.025

@time cell_yout = sunsim(cell_s, tstop=tf, Nsteps=int(tf/dt), reltol=1e-7, abstol=1e-7)

##@time cell_yout = sim(cell_s, tf, int(tf/dt))

plot (cell_yout.y[:,1], cell_yout.y[:,3])
