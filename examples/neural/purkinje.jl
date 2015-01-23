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



function Purkinje(I)

    v   = Voltage (-70.0, "v")   

    cai = Unknown (cai0, "cai")
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        
        der(v) = ((I * (100.0 / area)) - 1e3 * (I_L)) / C_m
        
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
