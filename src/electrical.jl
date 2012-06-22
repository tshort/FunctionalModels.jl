
########################################
## Electrical library                 ##
########################################



########################################
## Probes
########################################

function SeriesProbe(n1, n2, name::String) 
    i = Unknown(compatible_values(n1, n2), name)   
    Branch(n1, n2, compatible_values(n1, n2), i)
end



########################################
## General
########################################

function BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,
                        model::Function, args...)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    n = Voltage(vals)
    PowerLoss = HeatFlow(compatible_values(hp))
    {
     if length(value(hp)) > 1  # hp is an array
         PowerLoss - v .* i
     else
         PowerLoss - sum(v .* i)
     end
     RefBranch(hp, -PowerLoss)
     n1 - n2 - v
     Branch(n1, n, 0.0, i)
     model(n, n2, args...)
     }
end



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

Resistor(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort, R::Signal) = 
    BranchHeatPort(n1, n2, hp, Resistor, R)

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

function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, support_flange::Flange, k::Real)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    tau = Torque(compatible_values(flange, support_flange))
    w = AngularVelocity(compatible_values(flange, support_flange))
    {
     Branch(n1, n2, i, v)
     Branch(flange, support_flange, phi, tau)
     w - der(flange)
     v - k * w
     tau + k * i
     }
end
EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, k::Real) =
    EMF(n1, n2, flange, 0.0, k::Real)




########################################
## Ideal
########################################




function IdealDiode(n1::ElectricalNode, n2::ElectricalNode, Vknee::Signal, Ron::Signal, Goff::Signal)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    openswitch = Discrete(fill(true, length(vals)))  # on/off state of each diode
    {
     Branch(n1, n2, v, i)
     BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative
     s .* ifelse(openswitch, 1.0, Ron) + Vknee - v
     s .* ifelse(openswitch, Goff, 1.0) + Goff .* Vknee - i
     }
end

IdealDiode(n1::ElectricalNode, n2::ElectricalNode) = IdealDiode(n1, n2, 0.0, 1e-5, 1e-5)
IdealDiode(n1::ElectricalNode, n2::ElectricalNode, Vknee::Signal) = IdealDiode(n1, n2, Vknee, 1e-5, 1e-5)


function IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, Vknee::Signal, Ron::Signal, Goff::Signal)
    # BROKEN
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    off = Discrete(false)  # on/off state of each switch
    addhook!(fire, 
             ifelse(fire, reinit(off, false)))
    {
     Branch(n1, n2, v, i)
     Event(-s, reinit(off, true)) 
     s .* ifelse(off, 1.0, Ron) + Vknee - v
     s .* ifelse(off, Goff, 1.0) + Goff .* Vknee - i
     }
end
IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete) = IdealThyristor(n1, n2, fire, 0.0, 1e-5, 1e-5)
IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, Vknee::Signal) = IdealThyristor(n1, n2, fire, Vknee, 1e-5, 1e-5)

  
function IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, Vknee::Signal, Ron::Signal, Goff::Signal)
    # BROKEN
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    off = Discrete(false)  # on/off state of each switch
    addhook!(fire, reinit(off, !fire))
    {
     Branch(n1, n2, v, i)
     Event(-s, reinit(off, true)) 
     s .* ifelse(off, 1.0, Ron) + Vknee - v
     s .* ifelse(off, Goff, 1.0) + Goff .* Vknee - i
     }
end
IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete) = IdealGTOThyristor(n1, n2, fire, 0.0, 1e-5, 1e-5)
IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, Vknee::Signal) = IdealGTOThyristor(n1, n2, fire, Vknee, 1e-5, 1e-5)

  
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


function ControlledIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                      level::Signal, Ron::Real, Goff::Real)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    openswitch = Discrete(fill(true, length(vals)))  # on/off state of diode
    {
     Branch(n1, n2, v, i)
     BoolEvent(openswitch, control - level)  # openswitch becomes false when control goes below level
     s .* ifelse(openswitch, 1.0, Ron) - v
     s .* ifelse(openswitch, Goff, 1.0) - i
     }
end
ControlledIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                      level::Signal) =
    ControlledIdealOpeningSwitch(n1, n2, control, level, 1e-5, 1e-5)
                                      

ControlledIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                             level::Signal, Ron::Real, Goff::Real) =
    ControlledIdealOpeningSwitch(n1, n2, level, control, Ron, Goff)
ControlledIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                      level::Signal) =
    ControlledIdealClosingSwitch(n1, n2, control, level, 1e-5, 1e-5)


function ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                 level::Signal, Ron::Real, Goff::Real, V0::Real, dVdt::Real, Vmax::Real)
    i = Current("i")
    v = Voltage()
    on = Discrete(false)  # on/off state of switch
    quenched = Discrete(true)  # whether the arc is quenched or not
    tSwitch = Discrete(0.0)  # time of last open initiation
    ipositive = Discrete(true)  # whether the current is positive
    {
     Branch(n1, n2, v, i)
     Event(level - control,
           reinit(on, true),
           {
               reinit(on, false)
               reinit(quenched, false)
               reinit(tSwitch, MTime)
           })
     Event(i,
           {
            reinit(i, 0.0)
            reinit(ipositive, true)
            ifelse(!quenched, reinit(quenched, true))
           },
           {
            reinit(i, 0.0)
            reinit(ipositive, false)
            ifelse(!quenched, reinit(quenched, true))
           })
     ifelse(on,
            v - Ron .* i,
            ifelse(quenched,
                   i - Goff .* v,
                   v - min(Vmax, V0 + dVdt .* (MTime - tSwitch))) .* sign(i))
     }
end

ControlledCloserWithArc(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                        level::Signal, Ron::Real, Goff::Real, V0::Real, dVdt::Real, Vmax::Real) = 
    ControlledOpenerWithArc(n1, n2, level, control, Ron, Goff, V0, dVdt, Vmax)

    
########################################
## Semiconductors
########################################


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

SineVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal, f::Signal, ang::Signal, offset::Signal) = 
    SignalVoltage(n1, n2, V .* sin(2pi .* f .* MTime + ang) + offset)

SineVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal, f::Signal, ang::Signal) =
    SineVoltage(n1, n2, V, f, ang, 0.0) 

SineVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal, f::Signal) =
    SineVoltage(n1, n2, V, f, 0.0, 0.0) 

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

function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  
    ## i = Current(compatible_values(n1, n2))
    ## v = Voltage(compatible_values(n1, n2))
    {
     RefBranch(n1, I) 
     RefBranch(n2, -I) 
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
     StepVoltage(n[1], g, -1.0, 1.0, 0.0)
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
     StepVoltage(n1, g, -1.0, 1.0, 0.0)
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

# m = ex_CauerLowPassOPV()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 20.0)
# # _ex1 = copy(_ex)


# m2 = ex_CauerLowPassOPV2()
# f2 = elaborate(m2)
# s2 = create_sim(f2)
# y2 = sim(s2, 20.0)
# # _ex2 = copy(_ex)

function ex_CharacteristicIdealDiodes()
    s1 = Voltage("s1")
    s2 = Voltage("s2")
    s3 = Voltage("s3")
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    g = 0.0
    {
     SineVoltage(s1, g, 10.0, 1.0, -pi/10.0) 
     SineVoltage(s2, g, 10.0, 1.0, -pi/15.0, -9.0) 
     SineVoltage(s3, g, 10.0, 1.0, -pi/20.0) 
     Resistor(n1, g, 1e-3) 
     Resistor(n2, g, 1e-3) 
     Resistor(n3, g, 1e-3) 
     IdealDiode(s1, n1, 0.0, 0.0, 0.0)
     IdealDiode(s2, n2, 0.0, 0.1, 0.1) 
     IdealDiode(s3, n3, 5.0, 0.2, 0.2) 
     }
end

function sim_CharacteristicIdealDiodes()
    y = sim(ex_CharacteristicIdealDiodes(), 1.0)
    wplot(y, "CharacteristicIdealDiodes.pdf")
end

# function ex_CharacteristicIdealDiodes1()
#     s1 = Voltage("s1")
#     n1 = Voltage("n1")
#     g = 0.0
#     {
#      SineVoltage(s1, g, 10.0, 1.0, -pi/10.0, 0.0) 
#      Resistor(n1, g, 1e-3) 
#      IdealDiode(s1, n1, 0.0, 0.0, 0.0)
#      }
# end

# m = ex_CharacteristicIdealDiodes()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 1.0)


function ex_ChuaCircuit()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage(4.0, "n3")
    g = 0.0
    function NonlinearResistor(n1::ElectricalNode, n2::ElectricalNode, Ga, Gb, Ve)
        i = Current(compatible_values(n1, n2))
        v = Voltage(compatible_values(n1, n2))
        {
         Branch(n1, n2, v, i)
         i - ifelse(v < -Ve, Gb .* (v + Ve) - Ga .* Ve,
                    ifelse(v > Ve, Gb .* (v - Ve) + Ga*Ve, Ga*v))
         }
    end
    {
     Resistor(n1, g, 12.5e-3) 
     Inductor(n1, n2, 18.0)
     Resistor(n2, n3, 1 / 0.565) 
     Capacitor(n2, g, 100.0)
     Capacitor(n3, g, 10.0)
     NonlinearResistor(n3, g, -0.757576, -0.409091, 1.0)
     }
end

function sim_ChuaCircuit()
    y = sim(ex_ChuaCircuit(), 1.0)
    wplot(y, "ChuaCircuit.pdf")
end

function ex_HeatingResistor()
    n1 = Voltage("n1")
    hp1 = Temperature("hp1")
    hp2 = Temperature("hp2")
    g = 0.0
    {
     SineVoltage(n1, g, 220, 1.0)
     Resistor(n1, g, hp1, 100.0, 20 + 273.15, 1e-3)
     ThermalConductor(hp1, hp2, 50.0)
     FixedTemperature(hp2, 20 + 273.15)
     }
end

function sim_HeatingResistor()
    y = sim(ex_HeatingResistor(), 5.0)
    wplot(y, "HeatingResistor.pdf")
end

function ex_HeatingRectifier()
    n1 = Voltage("n1")
    hp1 = Temperature("hp1")
    hp2 = Temperature("hp2")
    g = 0.0
    {
     SineVoltage(n1, g, 1.0, 1.0)
     HeatingDiode(n1, n2, hp1, morejunkXX)
     Capacitor(n2, g, 1.0)
     Resistor(n2, g, 1.0)
     ThermalConductor(hp1, hp2, 10.0)
     HeatCapacitor(hp2, 20 + 273.15)
     }
end

function sim_HeatingRectifier(BROKEN)
    y = sim(ex_HeatingRectifier(), 5.0)
    wplot(y, "HeatingRectifier.pdf")
end

function ex_Rectifier()
    n = Voltage("n")
    VAC = 400.0
    n1 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vs")
    n2 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vl")
    ## np = Voltage("Vp")
    ## nn = Voltage("Vn")
    np = Voltage( VAC*sqrt(2)/2, "Vp")
    nn = Voltage(-VAC*sqrt(2)/2, "Vn")
    nout = Voltage("Vout")
    g = 0.0
    f = 50.0
    LAC = 60e-6
    Ron = 1e-3
    Goff = 1e-3
    Vknee = 2.0
    CDC = 15e-3
    IDC = 500.0
    {
     SineVoltage(n1, g, VAC .* sqrt(2/3), f, [0.0, -2pi/3, 2pi/3])
     Inductor(n1, n2, LAC)
     ## Resistor(n2, np, 1e3)
     ## Resistor(n2, nn, 1e3)
     IdealDiode(n2, np, Vknee, Ron, Goff)
     IdealDiode(nn, n2, Vknee, Ron, Goff)
     ## Capacitor(np, nn, CDC)
     Capacitor(np, g, 2 * CDC)
     Capacitor(nn, g, 2 * CDC)
     ## SignalCurrent(np, nn, IDC)
     }
end

function ex_Rectifier()
    n = Voltage("n")
    VAC = 400.0
    n1 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vs")
    n2 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vl")
    ## np = Voltage("Vp")
    ## nn = Voltage("Vn")
    np = Voltage( VAC*sqrt(2)/2, "Vp")
    nn = Voltage(-VAC*sqrt(2)/2, "Vn")
    nout = Voltage("Vout")
    g = 0.0
    f = 50.0
    LAC = 60e-6
    Ron = 1e-3
    Goff = 1e-3
    Vknee = 2.0
    CDC = 15e-3
    IDC = 500.0
    {
     SineVoltage(n1, g, VAC .* sqrt(2/3), f, [0.0, -2pi/3, 2pi/3])
     Inductor(n1, n2, LAC)
     ## Resistor(n2, np, 1e3)
     ## Resistor(n2, nn, 1e3)
     IdealDiode(n2[1], np, Vknee, Ron, Goff)
     IdealDiode(n2[2], np, Vknee, Ron, Goff)
     IdealDiode(n2[3], np, Vknee, Ron, Goff)
     IdealDiode(nn, n2[1], Vknee, Ron, Goff)
     IdealDiode(nn, n2[2], Vknee, Ron, Goff)
     IdealDiode(nn, n2[3], Vknee, Ron, Goff)
     ## Capacitor(np, nn, CDC)
     Capacitor(np, g, 2 * CDC)
     Capacitor(nn, g, 2 * CDC)
     ## SignalCurrent(np, nn, IDC)
     Resistor(np, nn, 400 / IDC)
     }
end

function sim_Rectifier(BROKEN)
    y = sim(ex_Rectifier(), 0.1)
    wplot(y, "Rectifier.pdf")
end


## m = ex_Rectifier()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 0.1)



function ex_ShowSaturatingInductor()
    n1 = Voltage("V")
    g = 0.0
    Lzer = 2.0
    Lnom = 1.0
    Inom = 1.0
    Linf = 0.5
    U = 1.25
    f = 1/(2pi)
    phase = pi/2
    {
     SineVoltage(n1, g, U, f, phase)
     SaturatingInductor(n1, g, Inom, Lnom, Lzer, Linf)
     Inductor(n1, g, Inom, Lnom, Lzer, Linf)
     Inductor(n1, n2, Lnom)
     }
end

function sim_ShowSaturatingInductor()
    y = sim(ex_ShowSaturatingInductor(), 6.2832)
    wplot(y, "ShowSaturatingInductor.pdf")
end

function ex_ShowVariableResistor()
    n = Voltage("Vs")
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    n4 = Voltage("n4")
    n5 = Voltage("n5")
    isig1 = Voltage("Ir1")
    isig2 = Voltage("Ir2")
    vres = Voltage("Vres")
    g = 0.0
    {
     n2 - n3 - isig1    # current monitor
     n5 - n3 - isig2    # current monitor
     n5 - n4 - vres 
     SineVoltage(n, g, 1.0, 1.0)
     Resistor(n, n1, 1.0)
     Resistor(n1, n2, 1.0)
     Resistor(n2, n3, 1.0)
     Resistor(n, n4, 1.0)
     VariableResistor(n4, n5, 2 + 2.5 * MTime)
     Resistor(n5, n3, 1.0)
     }
end

function sim_ShowVariableResistor()
    y = sim(ex_ShowVariableResistor(), 6.2832)
    wplot(y, "ShowVariableResistor.pdf")
end


function ex_ControlledSwitchWithArc()
    a1 = Voltage("a1")
    a2 = Voltage("a2")
    a3 = Voltage("a3")
    b1 = Voltage("b1")
    b2 = Voltage("b2")
    b3 = Voltage("b3")
    vs = Voltage("vs")
    g = 0.0
    {
     SineVoltage(vs, g, 1.0, 1.0)
     ## SignalVoltage(a1, g, 50.0)
     ## ControlledIdealClosingSwitch(a1, a2, vs, 0.5, 1e-5, 1e-5)
     ## Inductor(a2, a3, 0.1)
     ## Resistor(a3, g, 1.0)
     SignalVoltage(b1, g, 50.0)
     ## ControlledCloserWithArc(b1, b2, vs, 0.5, 1e-5, 1e-5, 30.0, 1e4, 60.0)
     ControlledCloserWithArc(b1, b2, vs, 0.5, 1e-5, 1e-5, 60.0, 1e-2, 60.0)
     Inductor(b2, b3, 0.1)
     Resistor(b3, g, 1.0)
     }
end

function sim_ControlledSwitchWithArc()
    y = sim(ex_ControlledSwitchWithArc(), 6)
    wplot(y, "ex_ControlledSwitchWithArc.pdf")
end

## m = ex_ControlledSwitchWithArc()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 6.1)

function ex_dc()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    g = 0.0
    {
     SignalVoltage(n1, g, 50.0)
     Resistor(n1, n2, 0.1)
     Inductor(n2, g, 0.1)
     }
end

## m = ex_dc()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, .1)

function ex_CharacteristicThyristors()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    sig = Discrete(false)
    g = 0.0
    {
     SineVoltage(n1, g, 10.0, 1.0, 0.002) 
     IdealThyristor(n1, n2, sig, 5.0)
     IdealGTOThyristor(n1, n3, sig, 0.0)
     BoolEvent(sig, MTime - 1.25)  
     Resistor(n2, g, 1e-3)
     Resistor(n3, g, 1e-3)
    }
end

BooleanStep(ns::Discrete, t::Real) = BoolEvent(ns, MTime - t)  

m = ex_CharacteristicThyristors()
f = elaborate(m)
s = create_sim(f)
y = sim(s, 2.0)


function test_BoolEventHook()
    n1 = Voltage("n1")
    sig2 = Discrete(true)
    sig = Discrete(false)
    addhook!(sig, 
             reinit(sig2, false))
    g = 0.0
    {
     SineVoltage(n1, g, ifelse(sig2, 10.0, 5.0), ifelse(sig, 1.0, 2.0)) 
     BoolEvent(sig, MTime - 0.25)  
     Resistor(n1, g, 1e-3)
    }
end

## m = test_BoolEventHook()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 2.0)
