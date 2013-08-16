

########################################
## Electrical machines library        ##
########################################

## Patterned after Modelica.Electrical.Machines
## NOTE: NOT WORKING, YET!!!!!!!


type CoreParameters  # Parameter record for core losses
    m       # Number of phases (1 for DC, 3 for induction machines)
    PRef    # Reference core losses at reference inner voltage VRef
    VRef    # Reference inner RMS voltage that reference core losses PRef refer to
    wRef    # Reference angular velocity that reference core losses PRef refer to
    # In the current implementation ratioHysterisis = 0 since hysteresis losses are not implemented yet
    ratioHysteresis  # Ratio of hysteresis losses with respect to the total core losses at VRef and fRef
    GcRef   # Reference conductance at reference frequency and voltage
    wMin
end
CoreParameters(m, PRef, VRef, wRef) =
    CoreParameters(m, PRef, VRef, wRef, 0.0, PRef <= 0 ? 0 : PRef / VRef^2 / m, 1e-6 * wRef)
CoreParameters() =
    CoreParameters(3, 0.0, 100.0, 2*pi*60)

type FrictionParameters  # Parameter record for friction losses
    PRef  # Reference friction losses at wRef
    wRef  # Reference angular velocity that the PRef refer to
    power_w  # Exponent of friction torque w.r.t. angular velocity
    tauRef  # Reference friction torque at reference angular velocity
    linear  # Linear angular velocity range with respect to reference angular velocity
    wLinear # Linear angular velocity range
    tauLinear  # Torque corresponding with linear angular velocity range
end 
FrictionParameters(PRef, wRef, power_w) =
    FrictionParameters(PRef, wRef, power_w, 
                       PRef <= 0 ? 0 : PRef / wRef,
                       0.001,
                       0.001 * wRef,
                       PRef <= 0 ? 0 : tauRef * (wLinear/wRef)^power_w)
FrictionParameters() = FrictionParameters(0.0, 2*pi*60/2, 2.0)

type StrayLoadParameters  # Parameter record for stray load  losses
    PRef  # Reference stray load losses at IRef and wRef
    IRef  # Reference RMS current that PRef refers to
    wRef  # Reference angular velocity that PRef refers to
    power_w  # Exponent of stray load loss torque w.r.t. angular velocity
    tauRef   # Reference friction torque at reference angular velocity and reference current
end 
StrayLoadParameters(PRef, IRef, wRef, power_w) =
    StrayLoadParameters(PRef, IRef, wRef, power_w, PRef <= 0 ? 0 : PRef / wRef)
StrayLoadParameters() = StrayLoadParameters(0.0, 100.0, 2*pi*60/2, 1.0)

function convertAlpha(alpha1, T2, T1)
    "Converts alpha from temperature 1 (default 20 degC) to temperature 2"
    alpha1 / (1 + alpha1*(T2 - T1));
end
convertAlpha(alpha1, T2) = convertAlpha(alpha1, T2, 291.15)

function AIMSquirrelCage(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, support::Flange, T::HeatPort,
                         p::Int, fsNominal::Float64, Jr, Js, 
                         TsOperational, TrOperational,
                         Rs, TsRef, alpha20s, Lszero, Lssigma, Lm, Lrsigma, Rr, TrRef, alpha20r,
                         frictionParameters, statorCoreParameters, strayLoadParameters)
    vals = compatible_values(n1, n2)
    n3 = Voltage(vals)
    n4 = Voltage(vals)
    sp_in = Voltage(zeros(2))
    sp_gap1 = Voltage(zeros(2))
    sp_gap2 = Voltage(zeros(2))
    zero = Voltage()
    gap_flange = Angle(compatible_values(flange))
    m = 3
    gnd = 0.0
    {
     SpacePhasorConvertor(n4, n2, sp_in, zero, 1.0)
     SquirrelCage(sp_gap2,
                  T,
                  Lrsigma, # Rotor stray inductance (equivalent three-phase winding)
                  Rr, # Rotor resistance (equivalent three-phase winding)
                  TrRef, # Reference temperature of rotor resistance
                  convertAlpha(alpha20r, TrRef))
     AirGapS(sp_gap1, sp_gap2, gap_flange, support,
             Lm, m, p)
     Inertia(gap_flange, gnd, Jr) # inertiaRotor
     if isa(support, Angle)
         Inertia(support, gnd, Js) # inertiaStator
     end
     Resistor(n3, n4, 
              fill(Rs, m),
              T,
              fill(TsRef, m), 
              fill(convertAlpha(alpha20s, TsRef), m))
     Inductor(sp_in, sp_gap1, fill(Lssigma, 2))
     Inductor(zero, gnd, Lszero)
     Core(sp_in, T, statorCoreParameters)
     Friction(flange, gnd, T, frictionParameters)
     StrayLoad(n1, n3, flange, gnd, T, strayLoadParameters)
    }
end

function AIMSquirrelCage(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, support::Flange, T::HeatPort;
        p = 2, # Number of pole pairs
        fsNominal = 50.0, # Nominal frequency, Hz
        Jr = 0.29, # Rotor's moment of inertia
        Js = 0.29, # Stator's moment of inertia
        TsOperational = 293.15, # Operational temperature of stator resistance
        TrOperational = 293.15, # Operational temperature of rotor resistance
        Rs = 0.03,  # Stator resistance per phase at TRef
        TsRef = 293.15,  # Reference temperature of stator resistance
        alpha20s = 0.0,  # Temperature coefficient of stator resistance at 20 degC
        Lssigma = 3 * (1 - sqrt(1 - 0.0667) / (2*pi*fsNominal)), # Stator stray inductance per phase
        Lszero = Lssigma,  # Stator zero-sequence inductance
        Lm = 3*sqrt(1 - 0.0667)/(2*pi*fsNominal), # Main field inductance
        # following are wrong...
        Lrsigma = 0.0, # Rotor stray inductance per phase translated to stator
        Rr = 0.0, # Rotor resitance per phase translated to stator at T_ref
        TrRef = 293.15, # Reference temperature
        alpha20r = 0.0, # Temperature coefficient of rotor resistance at 20 degC
        frictionParameters = FrictionParameters(),
        statorCoreParameters = CoreParameters(),
        strayLoadParameters = StrayLoadParameters())
    AIMSquirrelCage(n1, n2, flange, support, T, 
                    p, fsNominal, Jr, Js, 
                    TsOperational, TrOperational,
                    Rs, TsRef, alpha20s, Lszero, Lssigma, Lm, Lrsigma, Rr, TrRef, alpha20r,
                    frictionParameters, statorCoreParameters, strayLoadParameters)
end
AIMSquirrelCage(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, ...) =
    AIMSquirrelCage(n1, n2, flange, 0.0, 293.15, ...)


function AirGapS(sp_s::ElectricalNode, sp_r::ElectricalNode, flange::Flange, support::Flange,
                 Lm, m, p)
    vals = compatible_values(sp_r, sp_s)
    i_ms = Current(vals)
    i_ss = Current(vals)
    i_rr = Current(vals)
    i_rs = Current(vals)
    i_sr = Current(vals)
    psi_ms = Unknown(vals)
    psi_mr = Unknown(vals)
    phi = Angle(compatible_values(flange, support))
    gamma = Angle(compatible_values(flange, support))
    flange_tau = Torque(compatible_values(flange, support))
    support_tau = Torque(compatible_values(flange, support))
    tauElectrical = Torque(compatible_values(flange, support))
    RotationMatrix = Unknown(zeros(2,2))
    L = [Lm 0;0 Lm]
    {
     # mechanical angle of the rotor of an equivalent 2-pole machine
     gamma - p*(flange-support)
     RotationMatrix - [+cos(gamma) -sin(gamma); +sin(gamma) +cos(gamma)]
     RefBranch(sp_s, i_ss)
     i_ss - RotationMatrix * i_sr
     RefBranch(sp_r, i_rr)
     i_rs - RotationMatrix * i_rr
     RefBranch(flange, flange_tau)
     RefBranch(support, support_tau)
     # Magnetizing current with respect to the stator reference frame
     i_ms - i_ss - i_rs
     # Magnetizing flux linkage with respect to the stator reference frame
     psi_ms - L*i_ms;
     # Magnetizing flux linkage with respect to the rotor reference frame
     psi_mr - RotationMatrix' * psi_ms
     # Stator voltage induction
     sp_s - der(psi_ms)
     # Rotor voltage induction
     sp_r - der(psi_mr)
     # Electromechanical torque (cross product of current and flux space phasor)
     tauElectrical - m/2*p*(i_ss[2]*psi_ms[1] - i_ss[1]*psi_ms[2])
     flange_tau + tauElectrical
     support_tau - tauElectrical
    }
end

function quasiRMS(x)   # Calculate quasi-RMS value of input
    const m=3  # Number of phases
    h = zeros(2)
    for k in 1:m
        h += 2/m*[+cos((k - 1)/m*2*pi), +sin(+(k - 1)/m*2*pi)] * x[k]
    end
    sqrt(h[1]^2 + h[2]^2)/sqrt(2)
end
quasiRMS(x::ModelType) = mexpr(:call, :quasiRMS, _expr(x))

function StrayLoad(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, support::Flange, T::HeatPort, strayLoadParameters::StrayLoadParameters)
    vals = compatible_values(n1, n2)
    v = Voltage(vals)
    i = Current(vals)
    powerLoss = HeatFlow(compatible_values(T))
    phi = Angle(compatible_values(flange, support))
    w = AngularVelocity(compatible_values(flange, support))
    tau = Torque(compatible_values(flange, support))
    m = length(n1)
    {
     Branch(n1, n2, v, i) 
     Branch(flange, support, phi, tau)
     RefBranch(T, -powerLoss)
     v
     if isa(T, Temperature)
         powerLoss - tau .* w
     end
     tau - ifelse(strayLoadParameters.PRef <= 0.0,
                  0.0,
                  -strayLoadParameters.tauRef * (quasiRMS(i) / strayLoadParameters.IRef) ^ 2 *
                  ifelse(w >= 0.0,
                         +(w/strayLoadParameters.wRef)^strayLoadParameters.power_w,
                         -(-w/strayLoadParameters.wRef)^strayLoadParameters.power_w))
    }
end

function Core(sp::ElectricalNode, T::HeatPort, coreParameters::CoreParameters)
    vals = compatible_values(sp)
    sp_i = Current(vals)
    powerLoss = HeatFlow(compatible_values(T))
    Gc = Unknown(vals)
    {
     RefBranch(sp, sp_i)
     RefBranch(T, -powerLoss)
     Gc - ifelse(coreParameters.PRef <= 0.0,
                 0.0,
                 coreParameters.GcRef)
     sp_i - Gc .* sp
     if isa(T, Temperature)
         powerLoss + 3/2 * (sp[1]*sp_i[1] + sp[2]*sp_i[2])
     end
    }
end

function Friction(flange::Flange, support::Flange, T::HeatPort, frictionParameters::FrictionParameters)
    powerLoss = HeatFlow(compatible_values(T))
    w = AngularVelocity(compatible_values(flange, support))
    phi = Angle(compatible_values(flange, support))
    tau = Torque(compatible_values(flange, support))
    {
     Branch(flange, support, phi, tau)
     RefBranch(T, -powerLoss)
     w - der(phi)
     if isa(T, Temperature)
         powerLoss - tau .* w
     end
     tau - ifelse(frictionParameters.PRef <= 0.0,
                  0.0,
           ifelse(w >= frictionParameters.wLinear,
                  frictionParameters.tauRef*(+w/frictionParameters.wRef)^frictionParameters.power_w,
           ifelse(w <= -frictionParameters.wLinear,
                  -frictionParameters.tauRef*(-w/frictionParameters.wRef)^frictionParameters.power_w,
                   frictionParameters.tauLinear*(w/frictionParameters.wLinear)))) 
    }
end

function SquirrelCage(spacePhasor_r::ElectricalNode, T::HeatPort, Lrsigma, Rr, T_ref, alpha)
    vals = compatible_values(spacePhasor_r)
    spacePhasor_i = Current(vals)
    powerLoss = HeatFlow(compatible_values(T))
    Rr_actual = Unknown(compatible_values(Rr))
    {
     RefBranch(spacePhasor_r, spacePhasor_i)
     RefBranch(T, -powerLoss)
     Rr_actual - Rr .* (1 + alpha .* (T - T_ref))
     spacePhasor_r - Rr_actual .* spacePhasor_i - Lrsigma .* der(spacePhasor_i)
     if isa(T, Temperature)
         2/3*powerLoss - Rr_actual .* (spacePhasor_i[1]*spacePhasor_i[1] + spacePhasor_i[2]*spacePhasor_i[2])
     end
     }
end

function SpacePhasorConvertor(n1::ElectricalNode, n2::ElectricalNode,
                              spacePhasor::ElectricalNode,
                              zero_v::ElectricalNode,
                              turnsRatio)
    v = Voltage(compatible_values(n1, n2))
    i = Current(compatible_values(n1, n2))
    i1 = Current(compatible_values(n1, n2))
    i2 = Current(compatible_values(n1, n2))
    spacePhasor_i = Current(compatible_values(spacePhasor))
    zero_i = Current(compatible_values(zero_v))
    const m = 3
    TransformationMatrix = 2/m * [[cos(+(k - 1)/m*2*pi) for k in 1:m]  [+sin(+(k - 1)/m*2*pi) for k in 1:m]]'
    ## InverseTransformation = [[cos(-(k - 1)/m*2*pi), -sin(-(k - 1)/m*2*pi)]' for k in 1:m]
    {
     RefBranch(n1, i1)
     RefBranch(n2, i2)
     RefBranch(zero_v, zero_i)
     RefBranch(spacePhasor, spacePhasor_i)
     v / turnsRatio - n1 + n2
     i*turnsRatio - i1
     i*turnsRatio + i2
     m*zero_v - sum(v)
     spacePhasor - TransformationMatrix * v
     -m*zero_i - sum(i)
     -spacePhasor_i - TransformationMatrix * i
    }
end

function AIMC_DOL()
    VAC = 100.0
    fNominal = 50.0
    JLoad = 0.29
    TLoad = 161.4
    wLoad = 1440.45*2*pi/60
    tStart1 = 0.1
    n1 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vsrc")
    n2 = Voltage(zeros(3), "Vcls")
    n3 = Voltage(zeros(3), "Vmtr")
    r1 = Angle(0.0, "MotorAngle")
    r2 = Angle(0.0, "LoadAngle")
    control = Discrete(false)
    gnd = 0.0
    {
     SineVoltage(n1, gnd, VAC .* sqrt(2/3), fNominal, [0.0, -2pi/3, 2pi/3])
     AIMSquirrelCage(n3, gnd, r1)
     Inertia(r1, r2, JLoad)
     QuadraticSpeedDependentTorque(r2, gnd, -TLoad, false, wLoad)
     BoolEvent(control, MTime - tStart1)
     IdealClosingSwitch(n1, n2, control)
    }
end

function sim_AIMC_DOL()
    # miscellaneous testing junk

    m = Sims.AIMC_DOL()
    f = elaborate(m)
    s = create_sim(f)
    y = sim(s, 1.5)

    y = sim(Sims.AIMC_DOL(), 1.0)
    

    Sims.check(Sims.SquirrelCage(Voltage(zeros(2)), 0.0, 0.0,0.0, 0.0, 0.0))
    
    Sims.check(Sims.SpacePhasorConvertor(Voltage(zeros(3)), Voltage(zeros(3)), Voltage(zeros(2)), Voltage(), 0.0))
                                         
    Sims.check(Sims.AirGapS(Voltage(zeros(2)), Voltage(zeros(2)), Angle(), 0.0, 0.0, 0.0, 0.0))
                        
    Inertia(gap_flange, gnd, Jr) # inertiaRotor
    Sims.check(Sims.Inertia(0.0, 0.0, 0.0))
    Sims.check(Sims.Resistor(Voltage(zeros(3)), Voltage(zeros(3)), zeros(3), 0.0, zeros(3), zeros(3)))

    Resistor(n3, n4, 
              fill(Rs, m),
              T,
              fill(TsRef, m), 
              fill(convertAlpha(alpha20s, TsRef), m))
              
    Sims.check(Sims.Inductor(Voltage(zeros(2)), Voltage(zeros(2)), zeros(2)))
    Sims.check(Sims.Inductor(0.0, 0.0, 0.0))


    Sims.check(Sims.Core(Voltage(zeros(2)), Temperature(), Sims.CoreParameters()))
    m = Sims.Core(Voltage(zeros(2)), Temperature(), Sims.CoreParameters())
    
    Sims.check(Sims.Friction(Angle(), 0.0, 293.0, Sims.FrictionParameters()))
    
    Sims.check(Sims.StrayLoad(Voltage(zeros(3)), Voltage(zeros(3)), Angle(), 0.0, Temperature(), Sims.StrayLoadParameters()))

    Sims.check(Sims.AIMC_DOL())
    
end
