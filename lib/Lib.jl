module Lib
using ..Sims
using Docile
@document


## Standard library
## Base types
export NumberOrUnknown, Signal, UVoltage, UCurrent, ElectricalNode, Voltage, Current,
       UHeatPort, UTemperature, UHeatFlow,
       HeatPort, Temperature, HeatFlow,
       UAngle, UTorque, Angle, Torque, UAngularVelocity, AngularVelocity,
       UAngularAcceleration, AngularAcceleration, Flange
## Blocks
export Integrator, Derivativ, Integrator, Derivative,
       LimPID, StateSpace, Limiter, DeadZone, BooleanPulse, Pulse
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
## Chemical kinetics
export ReactionSystem, ReactionEquation, parseReactionSystem

# load standard Sims libraries
include("types.jl")
include("blocks.jl")
include("electrical.jl")
## include("machines.jl")
include("powersystems.jl")
include("heat_transfer.jl")
include("rotational.jl")
include("kinetic.jl")

end # module Lib
