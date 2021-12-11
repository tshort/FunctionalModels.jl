using FunctionalModels, FunctionalModels.Lib
using ModelingToolkit, OrdinaryDiffEq

include("../examples/lib/electrical.jl")

clpa  = sim(CauerLowPassAnalog, 60.0)
clpo  = sim(CauerLowPassOPV, 60.0, Tsit5())
clpo2 = sim(CauerLowPassOPV2, 60.0, Tsit5())
# cid   = sim(CharacteristicIdealDiodes, 1.0)
cc    = sim(ChuaCircuit, 5000.0, init = [0.0, 0.0, 4.0])
# hr    = sim(HeatingResistor, 5.0)
# svr   = sim(ShowVariableResistor, 1)
