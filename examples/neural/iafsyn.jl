
## Modular integrate-and-fire model with synaptic dynamics.

using Sims
using Sims.Lib
using Winston
using Grid ## for interpolating input values
using SIUnits
using SIUnits.ShortUnits


include ("poisson_grid.jl")

##gL     = 0.2 * mS
##vL     = -70.0 * mV
##Isyn   = 20.0 * nA
##C      = 1.0 * uF
##theta  = 25.0 * mV
##vreset = -65.0 * mV
##trefractory = 5.0 * ms

gL     = 0.2
vL     = -70.0
Isyn   = 20.0
C      = 1.0
theta  = 25.0
vreset = -65.0
trefractory = 5.0


vsyn  = 80.0
alpha = 1.0
beta  = 0.25
gsmax = 0.1
taus  = 2.5
f     = -100.0
s0    = 0.5


##getindex(g::InterpGrid, x::Unknown) = mexpr(:quote,g[value(x)])

grid_input(g::CoordInterpGrid) = mexpr(:call,getindex,g,MTime)


function LeakyIaF(V,Isyn)

    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        der(V) = ( ((- gL) * (V - vL)) + Isyn) / C
   
        Event(V-theta,
             Equation[
                 reinit(V, vreset)
             ],    # positive crossing
             Equation[])

    end
    
end

function Syn(V,Isyn,input)

    S  = Unknown ("S")
    SS = Unknown ("SS")
    gsyn = Unknown ()
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin
        der(S)  = (alpha * (1 - S) - beta * S)
        der(SS) = ((s0 - SS) / taus)
        
        Isyn = (gsyn * (V - vsyn))
        gsyn = (gsmax * S * SS)

        Event(grid_input(input),
             Equation[
                 reinit(SS, SS + f * (1 - SS))
             ],
             Equation[])
        Event(V-theta,
             Equation[
                 reinit(S, 0.0)
                 reinit(SS, 0.0)
             ],
             Equation[])
    end
    
end


function Circuit(y)
    V     = Voltage (-35.0, "V")
    Isyn  = Unknown ("Isyn")
    Isyn1 = Unknown ()
    @equations begin
       LeakyIaF(V,Isyn)
       Syn(V,Isyn1,y)
       Isyn = Isyn1
    end
end


tf = 100.0 * ms
dt = 0.025 * ms
lambda = 50.0 * Hz

input = poisson_grid(lambda,tf,dt,ms)

iaf   = Circuit(input)

iaf_f = elaborate(iaf)    # returns the flattened model
iaf_s = create_sim(iaf_f) # returns a "Sim" ready for simulation

# runs the simulation and returns
# the result as an array plus column headings
@time iaf_yout = sunsim(iaf_s, tstop=tf / ms, Nsteps=int(tf/dt), reltol=1e-7, abstol=1e-7)

plot (iaf_yout.y[:,1], iaf_yout.y[:,2])

