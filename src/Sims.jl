## using Winston

module Sims

import Base.hcat,
       Base.length,
       Base.getindex, 
       Base.setindex!,
       Base.show,
       Base.size,
       Base.vcat

## Types
export ModelType, UnknownCategory, Unknown, UnknownVariable, DefaultUnknown, DerUnknown, RefUnknown, RefBranch,
       InitialEquation, Model, MExpr, Discrete, RefDiscrete, DiscreteVar, Event, LeftVar, StructuralEvent,
       EquationSet, SimFunctions, Sim, SimResult

## Specials
export MTime, @init, @unknown

## Methods
export is_unknown, der, delay, mexpr, value, compatible_values, reinit, ifelse,
       basetypeof, from_real, to_real,
       gplot, wplot,
       check,
       elaborate, create_sim, sim, sunsim, dasslsim, inisolve

## Model methods
export Branch, BoolEvent

## Standard library
## Base types
export NumberOrUnknown, Signal, UVoltage, UCurrent, ElectricalNode, Voltage, Current,
       UHeatPort, UTemperature, UHeatFlow,
       HeatPort, Temperature,
       UAngle, UTorque, Angle, Torque, UAngularVelocity, AngularVelocity,
       UAngularAcceleration, AngularAcceleration, Flange
## Blocks
export Integrator, Derivativ, Integrator, Derivative,
       LimPID, StateSpace, Limiter, DeadZone
## Electrical
export SeriesProbe, BranchHeatPort,
       Resistor, Capacitor, Inductor, SaturatingInductor, Transformer, EMF,
       IdealDiode, IdealThyristor, IdealGTOThyristor, IdealOpAmp,
       IdealOpeningSwitch, IdealClosingSwitch,
       ControlledIdealOpeningSwitch, ControlledIdealClosingSwitch, ControlledOpenerWithArc, ControlledCloserWithArc,
       Diode, ZDiode, HeatingDiode,
       SignalVoltage, SineVoltage, StepVoltage, SignalCurrent
## Power Systems
export SeriesImpedance, ShuntAdmittance,
       RLLine, PiLine, ModalLine,
       ConductorGeometries, Conductor, ConductorLocation,
       OverheadImpedances, Conductors,
       ConstZParallelLoad, ConstZSeriesLoad
## Heat Transfer
export HeatCapacitor, ThermalConductor, Convection, BodyRadiation, ThermalCollector,
       FixedTemperature, FixedHeatFlow, PrescribedHeatFlow
## Rotational
export Inertia, Disc, Spring, BranchHeatPort, Damper, SpringDamper,
       IdealGear, SpeedSensor, AccSensor, SignalTorque
           

include("main.jl")
include("elaboration.jl")
include("simcreation.jl")
include("utils.jl")

# solvers
hasdassl = try
    include("dassl.jl")
    sim = dasslsim
    true
catch
    false
end
hassundials = try
    include("sundials.jl")
    sim = sunsim
    true
catch
    false
end
if hassundials
    sim = sunsim
elseif hasdassl
    sim = dasslsim
else
    error("Sims: no solver available (Sundials and DASSL are both unavailable)")
end
    

# load standard Sims libraries
include("types.jl")
include("blocks.jl")
include("electrical.jl")
## include("machines.jl")
include("powersystems.jl")
include("heat_transfer.jl")
include("rotational.jl")

end # module Sims
