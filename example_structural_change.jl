
load("sims.jl")

########################################
## Breaking pendulum                  ##
########################################

function FreeFall(x,y,vx,vy)
    {
     vx - der(x)
     vy - der(y)
     der(vx)
     der(vy) + 9.81
    }
end

function Pendulum(x,y,vx,vy)
    len = sqrt(x.value^2 + y.value^2)
    phi0 = atan2(x.value, -y.value) 
    phi = Unknown(phi0)
    phid = Unknown()
    {
     phid - der(phi)
     vx - der(x)
     vy - der(y)
     x - len * sin(phi)
     y + len * cos(phi)
     der(phid) + 9.81 / len * sin(phi)
    }
end

function BreakingPendulum()
    x = Unknown(cos(pi/4), "x")
    y = Unknown(-cos(pi/4), "y")
    vx = Unknown()
    vy = Unknown()
    {
     StructuralEvent(MTime - 5.0,     # when time hits 5 sec, switch to FreeFall
         {MExpr(:(FreeFall($x,$y,$vx,$vy)))},
         Pendulum(x,y,vx,vy))
    }
end

println("**** Breaking Pendulum ****")
p = BreakingPendulum()
p_f = elaborate(p)
p_s = create_sim(p_f) 
p_y = sim(p_s, 6.0)  






########################################
## Diode                              ##
########################################

#
# This is another test of discontinuities with an ideal diode.
# 
type UVoltage <: UnknownCategory
end
type UCurrent <: UnknownCategory
end
typealias ElectricalNode Unknown{UVoltage}
typealias Voltage Unknown{UVoltage}
typealias Current Unknown{UCurrent}

function Resistor(n1, n2, R::Real) 
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i)
     R * i - v   # == 0 is implied
     }
end

# These models are locally balanced; the number of unknowns matches
# the number of equations. It's pretty easy to match unknowns and
# equations as shown below:
function Capacitor(n1, n2, C::Real) 
    i = Current()              # Unknown #1
    v = Voltage()              # Unknown #2
    {
     Branch(n1, n2, v, i)      # Equation #1 - this returns n1 - n2 - v
     C * der(v) - i            # Equation #2
     }
end



function Inductor(n1, n2, L::Real) 
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i)
     L * der(i) - v
     }
end

#
# Nodes or parameters can be weakly typed or strongly typed. The
# following is used to more strongly type the input nodes. With this
# approach, one could define different characteristics for a device
# with different node inputs. It will also help prevent connection of
# types that shouldn't be connected.
#
typealias NumberOrUnknown{T} Union(AbstractArray, Number, Unknown{T})



function VSource(n1::NumberOrUnknown{UVoltage}, n2::NumberOrUnknown{UVoltage}, V::Real, f::Real)  
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i) 
     v - V * sin(2 * pi * f * MTime + pi/32)
     }
end

function VConst(n1, n2, V::Real)  
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i) 
     v - V
     }
end

function SeriesProbe(n1, n2, name::String) 
    i = Unknown(base_value(n1, n2), name)   
    Branch(n1, n2, base_value(n1, n2), i)
end

function IdealDiode(n1, n2)
    i = Current()
    v = Voltage()
    s = Unknown(1.0)  # dummy variable - needs a nonzero initial value for some reason
    openswitch = Discrete(false)  # on/off state of diode
    {
     Branch(n1, n2, i, v)
     BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative
     v - ifelse(openswitch, s, 0.0) 
     i - ifelse(openswitch, 0.0, s) 
     ## v - s * ifelse(openswitch, 1.0, 1e-5) 
     ## i - s * ifelse(openswitch, 1e-5, 1.0) 
     }
end

function OpenDiode(n1, n2)
    v = Voltage(-1e-6)
    StructuralEvent(v+0.0,     # when V goes positive, this changes to a ClosedDiode
        {MExpr(:(ClosedDiode($n1, $n2)))},
        Branch(n1, n2, v, 0.0))
end

function ClosedDiode(n1, n2)
    i = Current(1e-5)
    StructuralEvent(-i,     # when I goes negative, this changes to an OpenDiode
        {MExpr(:(OpenDiode($n1, $n2)))},
        Branch(n1, n2, 0.0, i))
end

# Cellier, fig 9.27
function HalfWaveRectifier()
    nsrc = ElectricalNode("Source voltage")
    n2 = ElectricalNode("Mid voltage")
    nout = ElectricalNode("Output voltage")
    g = 0.0 
    {
     VSource(nsrc, g, 1.0, 60.0)
     Resistor(nsrc, n2, 1.0)
     IdealDiode(n2, nout)
     Capacitor(nout, g, 0.001)
     Resistor(nout, g, 50.0)
     }
end


println("**** Non-structural Half Wave Rectifier ****")
rct = HalfWaveRectifier()
rct_f = elaborate(rct)
rct_s = create_sim(rct_f) 
rct_y = sim(rct_s, 0.1)  

# The same circuit with a structurally variable diode.
function StructuralHalfWaveRectifier()
    nsrc = ElectricalNode("Source voltage")
    n2 = ElectricalNode("Mid voltage")
    nout = ElectricalNode("Output voltage")
    Vdiode = Unknown("Vdiode")
    g = 0.0 
    {
     Vdiode - (n2 - nout)
     VSource(nsrc, g, 1.0, 60.0)
     Resistor(nsrc, n2, 1.0)
     ClosedDiode(n2, nout)
     Capacitor(nout, g, 0.001)
     Resistor(nout, g, 50.0)
     }
end

println("**** Structural Half Wave Rectifier ****")
sct = StructuralHalfWaveRectifier()
sct_f = elaborate(sct)
sct_s = create_sim(sct_f) 
sct_y = sim(sct_s, 0.1)  



stophere()
