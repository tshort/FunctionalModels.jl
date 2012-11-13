module Sims

using Base
import Base.length, Base.eltype, Base.ndims, Base.numel, Base.size, Base.promote
import Base.similar, Base.fill!, Base.one, Base.copy_to, Base.reshape
import Base.convert, Base.reinterpret, Base.ref, Base.assign, Base.check_bounds
import Base.push, Base.append!, Base.grow, Base.pop, Base.enqueue, Base.shift
import Base.insert, Base.del, Base.del_all, Base.~, Base.-, Base.sign, Base.real
import Base.imag, Base.conj!, Base.conj, Base.!, Base.+, Base.div, Base.mod
import Base.-, Base.*, Base./, Base.^, Base.&, Base.|
import Base.(./), Base.(.^), Base./, Base.\, Base.&, Base.|, Base.$, Base.(.*)
import Base.(.==), Base.==, Base.(.<), Base.<, Base.(.!=), Base.!=
import Base.(.<=), Base.<=, Base.slicedim, Base.flipdim, Base.rotl90
import Base.>=, Base.<, Base.>
import Base.rotr90, Base.rot180, Base.reverse!, Base.<<, Base.>>, Base.>>>
import Base.nnz, Base.find, Base.findn, Base.nonzeros
import Base.areduce, Base.max, Base.min, Base.sum, Base.prod, Base.map_to
import Base.filter, Base.transpose, Base.ctranspose, Base.permute, Base.hcat
import Base.vcat, Base.cat, Base.isequal, Base.cumsum, Base.cumprod
import Base.write, Base.read, Base.msync, Base.findn_nzs, Base.reverse
import Base.iround, Base.itrunc, Base.ifloor, Base.iceil, Base.abs
import Base.string, Base.show
import Base.isnan, Base.isinf, Base.^, Base.cmp, Base.sqrt, Base.min, Base.max, Base.isless, Base.atan2

## Types
export ModelType, UnknownCategory, UnknownVariable, DefaultUnknown, DerUnknown, RefUnknown, RefBranch,
       Model, MExpr, Discrete, RefDiscrete, DiscreteVar, Event, LeftVar, StructuralEvent,
       EquationSet, SimFunctions, Sim, SimResult

## Specials
export MTime

## Methods
export is_unknown, der, mexpr, value, compatible_values, reinit, ifelse,
       basetypeof, from_real, to_real,
       ## plot, wplot,
       elaborate, create_sim, sim 

## Model methods
export Branch 

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
       ControlledIdealOpeningSwitch, ControlledIdealClosingSwitch, ControlledOpenerWithArc, ControlledCloserWithArc,
       Diode,
       SignalVoltage, SineVoltage, StepVoltage, SignalCurrent
## Power Systems
export SeriesImpedance, ShuntAdmittance,
       RLLine, PiLine,
       ConductorGeometries, Conductor, ConductorLocation,
       OverheadImpedances, Conductors,
       ConstZParallelLoad, ConstZSeriesLoad
## Heat Transfer
export HeatCapacitor, ThermalConductor, Convection, BodyRadiation, ThermalCollector,
       FixedTemperature, FixedHeatFlow
## Rotational
export Inertia, Disc, Spring, BranchHeatPort, Damper, SpringDamper,
       IdealGear, SpeedSensor, AccSensor, SignalTorque
           

load("sims.jl")
# load standard Sims libraries

load("types.jl")
load("blocks.jl")
load("electrical.jl")
load("powersystems.jl")
load("heat_transfer.jl")
load("rotational.jl")
## load("examples.jl")

end # module Sims



module SimsCore     # SimsCore doesn't include the standard libraries

using Base
import Base.length, Base.eltype, Base.ndims, Base.numel, Base.size, Base.promote
import Base.similar, Base.fill!, Base.one, Base.copy_to, Base.reshape
import Base.convert, Base.reinterpret, Base.ref, Base.assign, Base.check_bounds
import Base.push, Base.append!, Base.grow, Base.pop, Base.enqueue, Base.shift
import Base.insert, Base.del, Base.del_all, Base.~, Base.-, Base.sign, Base.real
import Base.imag, Base.conj!, Base.conj, Base.!, Base.+, Base.div, Base.mod
import Base.-, Base.*, Base./, Base.^, Base.&, Base.|
import Base.(./), Base.(.^), Base./, Base.\, Base.&, Base.|, Base.$, Base.(.*)
import Base.(.==), Base.==, Base.(.<), Base.<, Base.(.!=), Base.!=
import Base.(.<=), Base.<=, Base.slicedim, Base.flipdim, Base.rotl90
import Base.>=, Base.<, Base.>
import Base.rotr90, Base.rot180, Base.reverse!, Base.<<, Base.>>, Base.>>>
import Base.nnz, Base.find, Base.findn, Base.nonzeros
import Base.areduce, Base.max, Base.min, Base.sum, Base.prod, Base.map_to
import Base.filter, Base.transpose, Base.ctranspose, Base.permute, Base.hcat
import Base.vcat, Base.cat, Base.isequal, Base.cumsum, Base.cumprod
import Base.write, Base.read, Base.msync, Base.findn_nzs, Base.reverse
import Base.iround, Base.itrunc, Base.ifloor, Base.iceil, Base.abs
import Base.string, Base.show
import Base.isnan, Base.isinf, Base.^, Base.cmp, Base.sqrt, Base.min, Base.max, Base.isless, Base.atan2

load("sims.jl")

end # module SimsCore
