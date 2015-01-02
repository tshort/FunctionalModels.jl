
using Sims
using Winston

## Disable history recording by default
Sims.Unknown(label::String) = Sims.Unknown{Sims.DefaultUnknown}(gensym(), 0.0, label, false, false)

# Pinsky-Rinzel CA3 neuron model
# Intrinsic and Network Rhythmogenesis in a Reduced Traub Model for CA3 Neurons

# Parameter values
J     = 0.75
gLs   = 0.1
gLd   = 0.1
gNa   = 30
gKdr  = 15
gCa   = 10
gKahp = 0.8
gKC   = 15
VNa   = 60
VCa   = 80
VK    = -75
VL    = -60
Vsyn  = 0
betaqd =  0.001


gc = 2.1
As = 0.5
Ad = 1-As
Cm = 3  


# Pyramidal cell functions

function alphams (v)
    return 0.32*(-46.9-v)/(exp((-46.9-v)/4.0)-1.0)
end

function betams(v)
    return 0.28*(v+19.9)/(exp((v+19.9)/5.0)-1.0)
end

function Minfs(v)
    return alphams(v)/(alphams(v)+betams(v))
end

function alphans(v)
    return 0.016*(-24.9-v)/(exp((-24.9-v)/5.0)-1.0)
end

function betans(v)
    return 0.25*exp(-1.0-0.025*v)
end

function alphahs(v)
    return 0.128*exp((-43.0-v)/18.0)
end

function betahs(v)
    return 4.0/(1.0+exp((-20.0-v)/5.0))
end

function alphasd(v)
    return 1.6/(1.0+exp(-0.072*(v-5.0)))
end

function betasd(v)
    return 0.02*(v+8.9)/(exp((v+8.9)/5.0)-1.0)
end

function heav(x)
    return ifelse (x > 0.0, 1.0, 0.0)
end

function alphacd(v)
    return (1.0-heav(v+10.0))*exp((v+50.0)/11-(v+53.5)/27)/18.975+heav(v+10.0)*2.0*exp((-53.5-v)/27.0)
end

function betacd(v)
    return (1.0-heav(v+10.0))*(2.0*exp((-53.5-v)/27.0)-alphacd(v))
end


function Soma(V,I)
   h = Unknown ("h")
   n = Unknown ("n")

   @equations begin
       der(V) = (-gLs * (V - VL) - gNa * (Minfs(V)^2) * h * (V - VNa) - gKdr * n * (V - VK) + I + J/As) / Cm
       der(h) = alphahs(V) - (alphahs(V) + betahs(V)) * h
       der(n) = alphans(V) - (alphans(V) + betans(V)) * n
   end
end


function Dendrite(V,I)
    ICad  = Unknown ("ICad")
    IKahp = Unknown ("IKahp")
    IK    = Unknown ("IK")
    Cad   = Unknown ("Cad")
    s     = Unknown ("s")
    c     = Unknown ("c")
    q     = Unknown ("q")
    chid  = Unknown ("chid")
    alphaqd = Unknown ("alphaqd")

    @equations begin
        der(V)  = (-gLd * (V - VL) - ICad - IKahp - IK + I) / Cm
        der(s)  = alphasd(V) - (alphasd(V) + betasd(V))*s
        der(c)  = alphacd(V) - (alphacd(V) + betacd(V))*c
        der(q)  = alphaqd - (alphaqd + betaqd) * q
        der(Cad) = -0.13 * ICad - 0.075 * Cad
        ICad     = gCa * s * s * (V - VCa)
        IKahp    = gKahp * q * (V - VK)
        IK       = gKC * c * chid * (V - VK)
        alphaqd  = min(0.00002 * Cad, 0.01)
        chid     = min(Cad / 250.0,1.0)
    end

end


function Connect(I,g,n1,n2)
   @equations begin
       g * I = n2 - n1
   end
end


function PRCircuit()
    Is  = Current("Is")
    Id  = Current("Id")
    Vs  = Voltage(-60.0,"Vs")
    Vd  = Voltage(-60.0,"Vd")
    V
    @equations begin
        Soma(Vs,Is)
        Dendrite(Vd,Id)
        Connect(Is,(As/gc),Vs,Vd)
        Connect(Id,(Ad/gc),Vd,Vs)
    end
end

pr   = PRCircuit()  # returns the hierarchical model
pr_f = elaborate(pr)    # returns the flattened model
pr_s = create_sim(pr_f) # returns a "Sim" ready for simulation

tf = 5000.0
dt = 0.025

pr_ptr = setup_sunsim (pr_s, 1e-7, 1e-7)

# runs the simulation and returns
# the result as an array plus column headings
@time pr_yout = sunsim(pr_ptr, tf, int(tf/dt))

plot (pr_yout.y[:,1], pr_yout.y[:,2])

