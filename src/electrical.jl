
########################################
## Electrical library                 ##
########################################

## Patterned after Modelica.Electrical.Analog


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
    @equations begin
        if length(value(hp)) > 1  # hp is an array
            PowerLoss = v .* i
        else
            PowerLoss = sum(v .* i)
        end
        RefBranch(hp, -PowerLoss)
        v = n1 - n2
        Branch(n1, n, 0.0, i)
        model(n, n2, args...)
    end
end



########################################
## Basic
########################################

function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    @equations begin
        Branch(n1, n2, v, i)
        v = R .* i
    end
end
function Resistor(n1::ElectricalNode, n2::ElectricalNode, 
                  R = 1.0, T = 293.15, T_ref = 300.15, alpha = 0.0)
    Resistor(n1, n2, T, R .* (1 + alpha .* (T - T_ref)), T_ref, alpha)
end
function Resistor(n1::ElectricalNode, n2::ElectricalNode; 
                  R = 1.0, T = 293.15, T_ref = 300.15, alpha = 0.0)
    Resistor(n1, n2, T, R, T, T_ref, alpha)
end
function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal, hp::Temperature, T_ref::Signal, alpha::Signal) 
    BranchHeatPort(n1, n2, hp, Resistor, R .* (1 + alpha .* (hp - T_ref)))
end


function Capacitor(n1::ElectricalNode, n2::ElectricalNode, C::Signal = 1.0) 
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    @equations begin
        Branch(n1, n2, v, i) 
        C .* der(v) = i      
    end
end
function Capacitor(n1::ElectricalNode, n2::ElectricalNode; C::Signal = 1.0) 
    Capacitor(n1, n2, C)
end


function Inductor(n1::ElectricalNode, n2::ElectricalNode, L::Signal = 1.0) 
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    @equations begin
        Branch(n1, n2, v, i) 
        L .* der(i) = v
    end
end
function Inductor(n1::ElectricalNode, n2::ElectricalNode; L::Signal = 1.0)
    Inductor(n1, n2, L)
end

function SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode, 
                            Inom = 1.0,
                            Lnom = 1.0,
                            Linf = Lnom ./ 2,
                            Lzer = Lnom .* 2)
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
    @equations begin
        Branch(n1, n2, v, i)
        (Lact - Linf) .* i ./ Ipar = (Lzer - Linf) .* atan2(i, Ipar)
        Psi = Lact .* i
        der(Psi) = v
    end
end
function SaturatingInductor(n1::ElectricalNode, n2::ElectricalNode; 
                            Inom = 1.0,
                            Lnom = 1.0,
                            Linf = Lnom ./ 2,
                            Lzer = Lnom .* 2)
    SaturatingInductor(n1, n2, Inom, Lnom, Linf, Lzer)
end

function SaturatingInductor2(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    psi = Unknown(vals, "psi")
    @equations begin
        Branch(n1, n2, v, i)
        psi = a * tanh(b * i) + c * i
        v = der(psi)
    end
end

function SaturatingInductor3(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    psi = Unknown(vals, "psi")
    @equations begin
        Branch(n1, n2, v, i)
        i = a * sinh(b * psi) - c * psi
        v = der(psi)
    end
end

function SaturatingInductor4(n1::ElectricalNode, n2::ElectricalNode,
                             a, b, c)
    vals = compatible_values(n1, n2) 
    i = Current(vals, "i_s")
    v = Voltage(value(n1) - value(n2), "v_s")
    psi = Unknown(vals, "psi")
    @equations begin
        Branch(n1, n2, v, i)
        psi = a * sign(i) * abs(i) ^ b + c * i
        der(psi) = v
    end
end

function Transformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode, 
                     L1 = 1.0, L2 = 1.0, M = 1.0)
    vals = compatible_values(compatible_values(p1, n1),
                             compatible_values(p2, n2)) 
    v1 = Voltage(value(p1) - value(n1))
    i1 = Current(vals)
    v2 = Voltage(vals)
    i2 = Current(vals)
    @equations begin
        Branch(p1, n1, v1, i1)
        Branch(p2, n2, v2, i2)
        v1 = L1 .* der(i1) + M .* der(i2)
        v2 = M .* der(i1) + L2 .* der(i2)
    end
end
function Transformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode; 
                     L1 = 1.0, L2 = 1.0, M = 1.0)
    Transformer(p1, n1, p2, n2, L1, L2, M)
end

function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange,
             support_flange = 0.0, k = 1.0)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    phi = Angle(compatible_values(flange, support_flange))
    tau = Torque(compatible_values(flange, support_flange))
    w = AngularVelocity(compatible_values(flange, support_flange))
    @equations begin
        Branch(n1, n2, i, v)
        Branch(flange, support_flange, phi, tau)
        w = der(phi)
        v = k * w
        tau = -k * i
    end
end
function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange;
             support_flange = 0.0, k = 1.0)
    EMF(n1, n2, flange, support_flange, k)
end


########################################
## Ideal
########################################



function IdealDiode(n1::ElectricalNode, n2::ElectricalNode, 
                    Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    openswitch = Discrete(fill(true, length(vals)))  # on/off state of each diode
    @equations begin
        Branch(n1, n2, v, i)
        BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative
        v = s .* ifelse(openswitch, 1.0, Ron) + Vknee
        i = s .* ifelse(openswitch, Goff, 1.0) + Goff .* Vknee
    end
end
function IdealDiode(n1::ElectricalNode, n2::ElectricalNode; 
                    Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    IdealDiode(n1, n2, Vknee, Ron, Goff)
end

function IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, 
                        Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    off = Discrete(true)  # on/off state of each switch
    addhook!(fire, 
             ifelse(fire, reinit(off, false)))
    @equations begin
        Branch(n1, n2, v, i)
        Event(-s, reinit(off, true)) 
        v = s .* ifelse(off, 1.0, Ron) + Vknee
        i = s .* ifelse(off, Goff, 1.0) + Goff .* Vknee
    end
end
function IdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete; 
                        Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    IdealThyristor(n1, n2, fire, Vknee, Ron, Goff)
end

  
function IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, 
                           Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    off = Discrete(true)  # on/off state of each switch
    addhook!(fire, reinit(off, !fire))
    @equations begin
        Branch(n1, n2, v, i)
        Event(-s, reinit(off, true)) 
        v = s .* ifelse(off, 1.0, Ron) + Vknee
        i = s .* ifelse(off, Goff, 1.0) + Goff .* Vknee
    end
end
function IdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete; 
                           Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)
    IdealGTOThyristor(n1, n2, fire, Vknee, Ron, Goff)
end

  
function IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode)
    i = Current(compatible_values(p2, n2))
    v = Voltage(compatible_values(p2, n2))
    @equations begin
        p1 = n1      # voltages at the input are equal
                     # currents at the input are zero, so leave out
        Branch(p2, n2, v, i) # at the output, make the currents equal
    end
end
function IdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode)
    i = Current(compatible_values(p2))
    @equations begin
        p1 = n1
        RefBranch(p2, i)
    end
end

function IdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete,
                            Ron = 1e-5, Goff = 1e-5)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    @equations begin
        Branch(n1, n2, v, i)
        v = s .* ifelse(control, 1.0, Ron)
        i = s .* ifelse(control, Goff, 1.0)
    end
end
function IdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete;
                            Ron = 1e-5, Goff = 1e-5)
    IdealOpeningSwitch(n1, n2, control, Ron, Goff)
end
  
function IdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete,
                            Ron = 1e-5,  Goff = 1e-5)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    @equations begin
        Branch(n1, n2, v, i)
        v = s .* ifelse(control, Ron, 1.0)
        i = s .* ifelse(control, 1.0, Goff)
    end
end
function IdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete;
                            Ron = 1e-5,  Goff = 1e-5)
    IdealClosingSwitch(n1, n2, control, Ron, Goff)
end
  
function ControlledIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                      level = 0.0,  Ron = 1e-5,  Goff = 1e-5)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    s = Unknown(vals)  # dummy variable
    openswitch = Discrete(fill(true, length(vals)))  # on/off state of diode
    @equations begin
        Branch(n1, n2, v, i)
        BoolEvent(openswitch, control - level)  # openswitch becomes false when control goes below level
        v = s .* ifelse(openswitch, 1.0, Ron)
        i = s .* ifelse(openswitch, Goff, 1.0)
    end
end
function ControlledIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal;
                                      level = 0.0,  Ron = 1e-5,  Goff = 1e-5)
    ControlledIdealOpeningSwitch(n1, n2, control, level, Ron, Goff)
end
                                      

function ControlledIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                      level = 0.0,  Ron = 1e-5,  Goff = 1e-5)
    ControlledIdealOpeningSwitch(n1, n2, control, level, Ron, Goff)
end
function ControlledIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Signal;
                                      level = 0.0,  Ron = 1e-5,  Goff = 1e-5)
    ControlledIdealClosingSwitch(n1, n2, control, level, Ron, Goff)
end


function ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control::Signal,
                                 level = 0.0,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
    i = Current("i")
    v = Voltage()
    on = Discrete(false)  # on/off state of switch
    quenched = Discrete(true)  # whether the arc is quenched or not
    tSwitch = Discrete(0.0)  # time of last open initiation
    ipositive = Discrete(true)  # whether the current is positive
    @equations begin
        Branch(n1, n2, v, i)
        Event(level - control,
              reinit(on, true),
              Equation[
                  reinit(on, false)
                  reinit(quenched, false)
                  reinit(tSwitch, MTime)
              ])
        Event(i,
              Equation[
                  reinit(i, 0.0)
                  reinit(ipositive, true)
                  ifelse(!quenched, reinit(quenched, true))
              ],
              Equation[
                  reinit(i, 0.0)
                  reinit(ipositive, false)
                  ifelse(!quenched, reinit(quenched, true))
              ])
        ifelse(on,
               v - Ron .* i,
               ifelse(quenched,
                      i - Goff .* v,
                      v - min(Vmax, V0 + dVdt .* (MTime - tSwitch))) .* sign(i))
    end
end
function ControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control::Signal;
                                 level = 0.0,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)
    ControlledOpenerWithArc(n1, n2, control, level, Ron, Goff, V0, dVdt, Vmax)
end

ControlledCloserWithArc = ControlledOpenerWithArc

    
########################################
## Semiconductors
########################################


function Diode(n1::ElectricalNode, n2::ElectricalNode, 
               Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    @equations begin
        Branch(n1, n2, v, i)
        i = ifelse(v ./ Vt > Maxexp,
                   Ids .* exp(Maxexp) .* (1 + v ./ Vt - Maxexp) - 1 + v ./ R,
                   Ids .* (exp(v ./ Vt) - 1) + v ./ R)
    end
end
function Diode(n1::ElectricalNode, n2::ElectricalNode; 
               Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)
    Diode(n1, n2, Ids, Vt, Maxexp, R)
end

Diode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort, args...) =
    BranchHeatPort(n1, n2, hp, Diode, args...)
Diode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort; args...) =
    BranchHeatPort(n1, n2, hp, Diode, args...)

function ZDiode(n1::ElectricalNode, n2::ElectricalNode,
                Ids = 1e-6,  Vt = 0.04,  Maxexp = 30.0,  R = 1e8,  Bv = 5.1, Ibv = 0.7,  Nbv = 0.74)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    @equations begin
        Branch(n1, n2, v, i)
        i = ifelse(v ./ Vt > Maxexp,
                   Ids .* exp(Maxexp) .* (1 + v ./ Vt - Maxexp) - 1 + v ./ R,
                   ifelse((v + Bv) < -Maxexp .* (Nbv .* Vt),
                          -Ids - Ibv .* exp(Maxexp) .* (1 - (v+Bv) ./ (Nbv .* Vt) - Maxexp) + v ./ R,
                          Ids .* (exp(v ./ Vt)-1) - Ibv .* exp(-(v + Bv)/(Nbv .* Vt)) + v ./ R))
    end
end
function ZDiode(n1::ElectricalNode, n2::ElectricalNode;
                Ids = 1e-6,  Vt = 0.04,  Maxexp = 30.0,  R = 1e8,  Bv = 5.1, Ibv = 0.7,  Nbv = 0.74)
    ZDiode(n1, n2, Ids, Vt, Maxexp, R, Bv, Ibv, Nbv)
end

ZDiode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort, args...) =
    BranchHeatPort(n1, n2, hp, ZDiode, args...)
ZDiode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort; args...) =
    BranchHeatPort(n1, n2, hp, ZDiode, args...)


function HeatingDiode(n1::ElectricalNode, n2::ElectricalNode, 
                      T = 293.15,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)
    vals = compatible_values(n1, n2)
    i = Current(vals)
    v = Voltage(vals)
    k = 1.380662e-23  # Boltzmann's constant, J/K
    q = 1.6021892e-19 # Electron charge, As
    @equations begin
        Branch(n1, n2, v, i)
        i = ifelse(v ./ Vt > Maxexp,
                   Ids .* exp(Maxexp) .* (1 + v ./ Vt - Maxexp) - 1 + v ./ R,
                   Ids .* (exp(v ./ Vt) - 1) + v ./ R)
    end
end
function HeatingDiode(n1::ElectricalNode, n2::ElectricalNode; 
                      T = 293.15,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)
    HeatingDiode(n1, n2, T, Ids, Maxexp, R, EG, N, TNOM, XTI)                  
end



########################################
## Sources
########################################


function SignalVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal)  
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    @equations begin
        Branch(n1, n2, v, i) 
        v = V
    end
end

function SineVoltage(n1::ElectricalNode, n2::ElectricalNode, 
                     V = 1.0,  f = 1.0,  ang = 0.0,  offset = 0.0)
    SignalVoltage(n1, n2, V .* sin(2pi .* f .* MTime + ang) + offset)
end
function SineVoltage(n1::ElectricalNode, n2::ElectricalNode; 
                     V = 1.0,  f = 1.0,  ang = 0.0,  offset = 0.0)
    SineVoltage(n1, n2, V, f, ang, offset) 
end

function StepVoltage(n1::ElectricalNode, n2::ElectricalNode, 
                     V = 1.0,  start = 0.0,  offset = 0.0)
    i = Current(compatible_values(n1, n2))
    v = Voltage(compatible_values(n1, n2))
    v_mag = Discrete(offset)
    @equations begin
        Branch(n1, n2, v, i) 
        v = v_mag
        Event(MTime - start,
              Equation[reinit(v_mag, offset + V)],        # positive crossing
              Equation[reinit(v_mag, offset)])            # negative crossing
    end
end
function StepVoltage(n1::ElectricalNode, n2::ElectricalNode; 
                     V = 1.0,  start = 0.0,  offset = 0.0)
    StepVoltage(n1, n2, V, f, ang, offset) 
end
    


function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  
    @equations begin
        RefBranch(n1, I) 
        RefBranch(n2, -I) 
    end
end
