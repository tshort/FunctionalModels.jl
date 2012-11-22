
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
    v = Voltage(value(n1) - value(n2))
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
    v = Voltage(value(n1) - value(n2))
    {
     Branch(n1, n2, v, i) 
     C .* der(v) - i      
     }
end

function Inductor(n1::ElectricalNode, n2::ElectricalNode, L::Signal) 
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    {
     Branch(n1, n2, v, i) 
     L .* der(i) - v
     }
end

function SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode,
                            Inom::Signal, Lnom::Signal, Linf::Signal, Lzer::Signal)
    @assert Lzer > Lnom
    @assert Linf < Lnom
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    Psi = Unknown(vals, "psi")
    Lact = Unknown(value(Linf), "Lact")
    ## Lact = Unknown(vals)
    # initial equation equivalent (uses John Myles White's optim package):
    Ipar = optimize(Ipar -> ((Lnom - Linf) - (Lzer - Linf)*Ipar[1]/Inom*(pi/2-atan2(Ipar[1],Inom))) ^ 2, [Inom]).minimum[1]
    println("Ipar: ", Ipar)
    {
     Branch(n1, n2, v, i)
     (Lact - Linf) .* i ./ Ipar - (Lzer - Linf) .* atan2(i, Ipar)
     Psi - Lact .* i
     der(Psi) - v
     }
end

SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode, Inom::Signal, Lnom::Signal) =
    SaturatingInductor(n1, n2, Inom, Lnom, Lnom ./ 2, Lnom .* 2)

function SaturatingInductor2(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    psi = Unknown(vals, "psi")
    {
     Branch(n1, n2, v, i)
     psi - a * tanh(b * i) + c * i
     v - der(psi)
     }
end

function SaturatingInductor3(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    psi = Unknown(vals, "psi")
    {
     Branch(n1, n2, v, i)
     i - a * sinh(b * psi) + c * psi
     v - der(psi)
     }
end

function SaturatingInductor4(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    psi = Unknown(vals, "psi")
    {
     Branch(n1, n2, v, i)
     a * sign(i) * abs(i) ^ b + c * i - psi
     v - der(psi)
     }
end

function Transformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode,
                     L1::Signal, L2::Signal, M::Signal)
    vals = compatible_values(compatible_values(p1, n1),
                             compatible_values(p2, n2)) 
    v1 = Voltage(value(p1) - value(n1))
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
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    off = Discrete(true)  # on/off state of each switch
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
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    off = Discrete(true)  # on/off state of each switch
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
