module Lib

using Sims
using Sims.Lib
using ModelingToolkit
using IfElse: ifelse


"""
# Sims.Lib

Examples using models from the Sims standard library (Sims.Lib).

Many of these are patterned after the examples in the Modelica
Standard Library.

"""
@comment 

# include("blocks.jl")
include("electrical.jl")
include("heat_transfer.jl")
include("rotational.jl")

# Electrical

export CauerLowPassAnalog,
       CauerLowPassOPV,
       CauerLowPassOPV2,
       CharacteristicIdealDiodes,
       ChuaCircuit,
       HeatingResistor,
       Rectifier,
       ShowVariableResistor
    #    HeatingRectifier,
    #    ShowSaturatingInductor,
    #    ControlledSwitchWithArc,
    #    CharacteristicThyristors,

# Heat transfer

export TwoMasses 
    #    Motor


end # module

