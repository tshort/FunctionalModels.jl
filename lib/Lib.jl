module Lib
using ..Sims, ModelingToolkit
import IfElse
const ie = IfElse.ifelse

const t = Sims.t

# Note: broken or experimental objects are not exported.


## Standard library
## Base types
export Signal, ElectricalNode, Voltage, Current,
       HeatPort, Temperature, HeatFlow,
       Angle, Torque, AngularVelocity,
       AngularAcceleration, Flange 
    #    Discrete

## Blocks
export Integrator, Derivativ, Integrator, Derivative,
       LimPID, StateSpace, Limiter, DeadZone, Pulse
    #    BooleanPulse, 

## Electrical
export SeriesProbe, BranchHeatPort,
       Resistor, HeatingResistor, Capacitor, Inductor, 
       Transformer, EMF,
       IdealDiode, 
       IdealOpAmp,
       IdealOpeningSwitch, IdealClosingSwitch,
       ControlledIdealOpeningSwitch, ControlledIdealClosingSwitch, 
       Diode, ZDiode, 
       SignalVoltage, SineVoltage, StepVoltage, SignalCurrent
    #    SaturatingInductor, 
    #    IdealThyristor, IdealGTOThyristor, 
    #    ControlledOpenerWithArc, ControlledCloserWithArc,
    #    HeatingDiode,

## Heat Transfer
export HeatCapacitor, ThermalConductor, Convection, BodyRadiation, ThermalCollector,
       FixedTemperature, FixedHeatFlow, PrescribedHeatFlow

## Rotational
export Inertia, Disc, Spring, BranchHeatPort, Damper, SpringDamper,
       IdealGear, SpeedSensor, AccSensor, SignalTorque


# load standard Sims libraries
include("types.jl")
include("blocks.jl")
include("heat_transfer.jl")
include("rotational.jl")
include("electrical.jl")

end # module Lib
