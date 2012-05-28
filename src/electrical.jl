

    


########################################
## General Signals
########################################


function Step(result, x::Real, start::Real, offset::Real)
    {
    Event(MTime - start,
          {reinit(result, x + offset)},    # positive crossing
          {-1})      # dummy
     }
end
Step(x::Real, start::Real) = Step(x, start, 0.0)
Step(x::Real) = Step(x, 0.0, 0.0)
Step() = Step(1.0, 0.0, 0.0)


########################################
## Electrical library                 ##
########################################


########################################
## Types
########################################

# typealias NumberOrUnknown{T} Union(AbstractArray, Number, Unknown{T})
typealias NumberOrUnknown{T} Union(AbstractArray, Number,
                                   RefUnknown{T}, Unknown{T})

type UVoltage <: UnknownCategory
end
type UCurrent <: UnknownCategory
end
type UHeatPort <: UnknownCategory
end
typealias ElectricalNode NumberOrUnknown{UVoltage}
# typealias Signal NumberOrUnknown{DefaultUnknown}
typealias Signal Any
typealias HeatPort NumberOrUnknown{UHeatPort}
typealias Voltage Unknown{UVoltage}
typealias Current Unknown{UCurrent}


########################################
## Basic
########################################

function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    {
     Branch(n1, n2, v, i)
     R .* i - v   # == 0 is implied
     }
end

function Resistor(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort, R::Signal)
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    LossPower = Power(compatible_values(hp))
    {
     if length(hp) > 1
         PowerLoss - v .* i
     else
         PowerLoss - sum(v .* i)
     end
     RefBranch(hp, -PowerLoss) 
     Branch(n1, n2, v, i)
     R .* i - v   # == 0 is implied
     }
end

Resistor(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort, R::Signal, T_ref::Signal, alpha::Signal) =
    Resistor(n1, n2, hp, R * (1 + alpha * (hp - T_ref)))

Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal, T_ref::Signal, alpha::Signal) =
    Resistor(n1, n2, R * (1 + alpha * (hp - T_ref)))


function Capacitor(n1::ElectricalNode, n2::ElectricalNode, C::Signal) 
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    {
     Branch(n1, n2, v, i) 
     C .* der(v) - i      
     }
end

function Inductor(n1::ElectricalNode, n2::ElectricalNode, L::Signal) 
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    {
     Branch(n1, n2, v, i) 
     L .* der(i) - v
     }
end

function SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode,
                            Inom::Signal, Lnom::Signal, Linf::Signal, Lzer::Signal)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    Psi = Unknown(vals)
    Lact = Unknown(vals)
    Ipar = Unknown(vals)
# initial equation 
#   (Lnom - Linf) = (Lzer - Linf)*Ipar/Inom*(Modelica.Constants.pi/2-Modelica.Math.atan(Ipar/Inom));
    {
     # @assert Lzer > Lnom + eps() "Lzer has to be > Lnom"
     # @assert Linf < Lnom + eps() "Linf has to be < Lnom"
     Branch(n1, n2, v, i)
     (Lact - Linf) .* i ./ Ipar - (Lzer - Linf) .* atan(i ./ Ipar)
     Psi - Lact .* i
     der(Psi) - v
     }
end

SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode, Inom::Signal, Lnom::Signal) =
    SaturatingInductor(n1, n2, Inom, Lnom, 2 * Lnom, Lnom / 2)

function Transformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode,
                     L1::Signal, L2::Signal, M::Signal)
    vals = compatible_values(compatible_values(p1, n1),
                             compatible_values(p2, n2)) 
    v1 = Voltage(vals)
    i1 = Current(vals)
    v2 = Voltage(vals)
    i2 = Current(vals)
    {
     Branch(p1, n1, v1, i1)
     Branch(p2, n2, v2, i2)
     L1 .* der(i1) + M .* der(i2) - v1
     M .* der(i1) + L2 .* der(i2) - v2
     }
end



########################################
## Ideal
########################################




function IdealDiode(n1::ElectricalNode, n2::ElectricalNode, Vknee::Signal, Ron::Signal, Goff::Signal)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    openswitch = Discrete(fill(false, length(vals)))  # on/off state of diode
    {
     Branch(n1, n2, v, i)
     BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative
     s .* ifelse(openswitch, 1.0, Ron) + Vknee - v
     s .* ifelse(openswitch, Goff, 1.0) + Goff .* Vknee - i
     }
end

IdealDiode(n1::ElectricalNode, n2::ElectricalNode) = IdealDiode(n1, n2, 0.0, 1e5, 1e5)
IdealDiode(n1::ElectricalNode, n2::ElectricalNode, Vknee::Signal) = IdealDiode(n1, n2, Vknee, 1e5, 1e5)

function Diode(n1::ElectricalNode, n2::ElectricalNode,
               Ids::Signal, Vt::Signal, Maxexp::Signal, R::Signal)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    {
     Branch(n1, n2, v, i)
     i - ifelse(v ./ Vt > Maxexp,
                Ids .* exp(Maxexp) .* (1 + v ./ Vt - Maxexp) - 1 + v ./ R,
                Ids .* (exp(v ./ Vt) - 1) + v ./ R)
     }
end
Diode(n1::ElectricalNode, n2::ElectricalNode) = Diode(n1, n2, 1e-6, 0.04, 15.0, 1e8)

Diode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
      Ids::Signal, Vt::Signal, Maxexp::Signal, R::Signal) =
    BranchHeatPort(n1, n2, hp, Diode, Ids, Vt, Maxexp, R)


function IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode)
    i = Current(compatible_values(p2, n2))
    v = Voltage(compatible_values(p2, n2))
    {
     p1 - n1      # voltages at the input are equal
                  # currents at the input are zero, so leave out
     Branch(p2, n2, v, i) # at the output, make the currents equal
     }
end
function IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode)
    i = Current(compatible_values(p2))
    {
     p1 - n1
     RefBranch(p2, i)
     }
end


function BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
                        model::Function, args...)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    LossPower = Power(compatible_values(hp))
    {
     if length(value(hp)) > 1  # an array
         PowerLoss - v .* i
     else
         PowerLoss - sum(v .* i)
     end
     n1 - n2 - v
     Branch(n1, n, 0.0, i)
     model(n, n2, args...)
     }
end


########################################
## Sources
########################################


function SignalVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal)  
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    {
     Branch(n1, n2, v, i) 
     v - V
     }
end

SineVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal, f::Signal, ang::Signal) = 
    SignalVoltage(n1, n2, sin(2pi .* f .* MTime + ang))

SineVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal, f::Signal) =
    SineVoltage(n1, n2, V, f, 0.0) 

function StepVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Real, start::Real, offset::Real)
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    v_mag = Discrete(offset)
    {
     Branch(n1, n2, v, i) 
     v - v_mag
     Event(MTime - start,
           {reinit(v_mag, offset + V)},        # positive crossing
           {reinit(v_mag, offset)})            # negative crossing
     }
end
    
function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    {
     Branch(n1, n2, v, i) 
     i - I
     }
end


########################################
## Examples
########################################

function ex_CauerLowPassAnalog()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    n4 = Voltage("n4")
    g = 0.0
    {
     StepVoltage(n1, g, 1.0, 1.0, 0.0)
     Resistor(n1, n2, 1.0)
     Capacitor(n2, g, 1.072)
     Capacitor(n2, n3, 1/(1.704992^2 * 1.304))
     Inductor(n2, n3, 1.304)
     Capacitor(n3, g, 1.682)
     Capacitor(n3, n4, 1/(1.179945^2 * 0.8586))
     Inductor(n3, n4, 0.8565)
     Capacitor(n4, g, 0.7262)
     Resistor(n4, g, 1.0)
     }
end

function sim_CauerLowPassAnalog()
    y = sim(ex_CauerLowPassAnalog(), 60.0)
    wplot(y, "CauerLowPassAnalog.pdf")
end

# m = ex_CauerLowPassAnalog()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 60.0)
# y = sim(ex_CauerLowPassAnalog(), 60.0)
# _ex1 = copy(_ex)

function ex_CauerLowPassAnalog2()
    n = Voltage(zeros(4), "n")
    g = 0.0
    {
     StepVoltage(n[1], g, 1.0, 1.0, 0.0)
     Resistor(n[1], n[2], 1.0)
     Capacitor(n[2], g, 1.072)
     Capacitor(n[2], n[3], 1/(1.704992^2 * 1.304))
     Inductor(n[2], n[3], 1.304)
     Capacitor(n[3], g, 1.682)
     Capacitor(n[3], n[4], 1/(1.179945^2 * 0.8586))
     Inductor(n[3], n[4], 0.8565)
     Capacitor(n[4], g, 0.7262)
     Resistor(n[4], g, 1.0)
     }
end

# m2 = ex_CauerLowPassAnalog2()
# f2 = elaborate(m2)
# s2 = create_sim(f2)
# y2 = sim(s2, 60.0)

function ex_CauerLowPassOPV()
    n = Voltage(zeros(11), "n")
    g = 0.0
    l1 = 1.304
    l2 = 0.8586
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    c3 = 1.682
    c4 = 1 / (1.179945^2 + l2)
    c5 = 0.7262
    {
     StepVoltage(n[1], g, 1.0, 1.0, 0.0)
     IdealOpAmp(g, n[2], n[3])
     IdealOpAmp(g, n[4], n[5])
     IdealOpAmp(g, n[6], n[7])
     IdealOpAmp(g, n[8], n[9])
     IdealOpAmp(g, n[10], n[11])
     Resistor(n[1], n[2], 1.0)
     Resistor(n[3], n[4], -1.0)
     Resistor(n[5], n[6], 1.0)
     Resistor(n[7], n[8], -1.0)
     Resistor(n[9], n[10], 1.0)
     Capacitor(n[2], n[3], c1 + c2)
     Capacitor(n[4], n[5], l1)
     Capacitor(n[6], n[7], c2 + c3 + c4)
     Capacitor(n[8], n[9], l2)
     Capacitor(n[10], n[11], c4 + c5)
     Resistor(n[2], n[3], 1.0)
     Resistor(n[2], n[5], 1.0)
     Resistor(n[4], n[7], -1.0)
     Resistor(n[6], n[9], 1.0)
     Resistor(n[8], n[11], -1.0)
     Resistor(n[10], n[11], 1.0)
     Capacitor(n[2], n[7], c2)
     Capacitor(n[3], n[6], c2)
     Capacitor(n[6], n[11], c4)
     Capacitor(n[7], n[10], c4)
     }
end
function ex_CauerLowPassOPV2()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    n4 = Voltage("n4")
    n5 = Voltage("n5")
    n6 = Voltage("n6")
    n7 = Voltage("n7")
    n8 = Voltage("n8")
    n9 = Voltage("n9")
    n10 = Voltage("n10")
    n11 = Voltage("n11")
    g = 0.0
    l1 = 1.304
    l2 = 0.8586
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    c3 = 1.682
    c4 = 1 / (1.179945^2 + l2)
    c5 = 0.7262
    {
     StepVoltage(n1, g, 1.0, 1.0, 0.0)
     IdealOpAmp(g, n2, n3)
     IdealOpAmp(g, n4, n5)
     IdealOpAmp(g, n6, n7)
     IdealOpAmp(g, n8, n9)
     IdealOpAmp(g, n10, n11)
     Resistor(n1, n2, 1.0)
     Resistor(n3, n4, -1.0)
     Resistor(n5, n6, 1.0)
     Resistor(n7, n8, -1.0)
     Resistor(n9, n10, 1.0)
     Capacitor(n2, n3, c1 + c2)
     Capacitor(n4, n5, l1)
     Capacitor(n6, n7, c2 + c3 + c4)
     Capacitor(n8, n9, l2)
     Capacitor(n10, n11, c4 + c5)
     Resistor(n2, n3, 1.0)
     Resistor(n2, n5, 1.0)
     Resistor(n4, n7, -1.0)
     Resistor(n6, n9, 1.0)
     Resistor(n8, n11, -1.0)
     Resistor(n10, n11, 1.0)
     Capacitor(n2, n7, c2)
     Capacitor(n3, n6, c2)
     Capacitor(n6, n11, c4)
     Capacitor(n7, n10, c4)
     }
end

function sim_CauerLowPassOPV()
    y = sim(ex_CauerLowPassOPV(), 60.0)
    wplot(y.y[:,1], y.y[:,12], "CauerLowPassOPV.pdf")
end

m = ex_CauerLowPassOPV()
f = elaborate(m)
s = create_sim(f)
y = sim(s, 20.0)
# _ex1 = copy(_ex)


m2 = ex_CauerLowPassOPV2()
f2 = elaborate(m2)
s2 = create_sim(f2)
y2 = sim(s2, 20.0)
# _ex2 = copy(_ex)


function ex_OpAmp()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    l1 = 1.304
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    g = 0.0
    {
     StepVoltage(n1, g, 1.0, 1.0, 0.0)
     IdealOpAmp(g, n2, n3)
     Resistor(n1, n2, 1.0)
     Capacitor(n2, n3, c1 + c2)
     }
end

# m = ex_OpAmp()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 20.0)
# # _ex1 = copy(_ex)