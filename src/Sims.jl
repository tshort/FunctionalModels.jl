require("Options")


module Sims

using Base
import Base.assign,
       Base.hcat,
       Base.length,
       Base.ref, 
       Base.size, 
       Base.vcat

using OptionsMod
export Options, @options     # export these so with `using Sims` the user doesn't have to do `using OptionsMod`

if isdir(julia_pkgdir() * "/Winston")
    include(find_in_path("Winston"))
end    
## if isdir(julia_pkgdir() * "/Tk")
##     load("Tk")
## end    

## Types
export ModelType, UnknownCategory, Unknown, UnknownVariable, DefaultUnknown, DerUnknown, RefUnknown, RefBranch,
       Model, MExpr, Discrete, RefDiscrete, DiscreteVar, Event, LeftVar, StructuralEvent,
       EquationSet, SimFunctions, Sim, SimResult

## Specials
export MTime

## Methods
export is_unknown, der, delay, mexpr, value, compatible_values, reinit, ifelse,
       basetypeof, from_real, to_real,
       gplot, wplot,
       check,
       elaborate, create_sim, sim

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
           

include(find_in_path("Sims/src/sim.jl"))

# load standard Sims libraries
include(find_in_path("Sims/src/types.jl"))
include(find_in_path("Sims/src/blocks.jl"))
include(find_in_path("Sims/src/electrical.jl"))
include(find_in_path("Sims/src/machines.jl"))
include(find_in_path("Sims/src/powersystems.jl"))
include(find_in_path("Sims/src/heat_transfer.jl"))
include(find_in_path("Sims/src/rotational.jl"))
## include(find_in_path("Sims/src/examples.jl"))

end # module Sims


