module Lib
using ..Sims, ModelingToolkit
using IfElse: ifelse



## Standard library
## Base types
export Signal, ElectricalNode, Voltage, Current,
       HeatPort, Temperature, HeatFlow,
       Angle, Torque, AngularVelocity,
       AngularAcceleration, Flange, 
       Discrete
## Blocks
export Integrator, Derivativ, Integrator, Derivative,
       LimPID, StateSpace, Limiter, DeadZone, BooleanPulse, Pulse
## Electrical
export SeriesProbe, BranchHeatPort,
       Resistor, HeatingResistor, Capacitor, Inductor, SaturatingInductor, Transformer, EMF,
       IdealDiode, IdealThyristor, IdealGTOThyristor, IdealOpAmp,
       IdealOpeningSwitch, IdealClosingSwitch,
       ControlledIdealOpeningSwitch, ControlledIdealClosingSwitch, ControlledOpenerWithArc, ControlledCloserWithArc,
       Diode, ZDiode, HeatingDiode,
       SignalVoltage, SineVoltage, StepVoltage, SignalCurrent
## Heat Transfer
export HeatCapacitor, ThermalConductor, Convection, BodyRadiation, ThermalCollector,
       FixedTemperature, FixedHeatFlow, PrescribedHeatFlow
## Rotational
export Inertia, Disc, Spring, BranchHeatPort, Damper, SpringDamper,
       IdealGear, SpeedSensor, AccSensor, SignalTorque
## Chemical kinetics
export ReactionSystem, ReactionEquation, parse_reactions
## Event grids
export make_grid, grid_input

# load standard Sims libraries
include("types.jl")
include("blocks.jl")
include("heat_transfer.jl")
include("rotational.jl")
include("electrical.jl")

end # module Lib
