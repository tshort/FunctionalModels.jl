
using Sims, Sims.Lib, Sims.Examples.Lib
using ModelingToolkit
using DifferentialEquations
using Plots

function runCauerLowPass()
    res = Dict()
    for m in (CauerLowPassAnalog, CauerLowPassOPV, CauerLowPassOPV2)
        sys = system(m())
        prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 40.0))
        sol = solve(prob, Tsit5())
        display(plot(sol))
        res[m] = (sys = sys, sol = sol)
    end
    res
end

function runChuaCircuit()
    sys = system(ChuaCircuit())
    # It's tricky to get the initial values right.
    # Values set on variables are getting removed when the variables are removed.
    sysstates = states(sys)
    p0 = Dict(k => 0.0 for k in sysstates)
    p0[sysstates[3]] = 4.0
    prob = ODAEProblem(sys, p0, (0, 10000.0))
    sol = solve(prob, Tsit5())
    display(plot(sol))
    (sys = sys, sol = sol) 
end

function runHeatingResistor()   #### BROKEN
    sys = system(HeatingResistor())
    prob = ODAEProblem(sys, Dict(k => 0.0 for k in states(sys)), (0, 10.0))
    sol = solve(prob, Tsit5())
    display(plot(sol))
    (sys = sys, sol = sol)
end


runCauerLowPass()
runChuaCircuit()

module Ckt
include("../examples/circuit.jl")
runCircuit()
end

module CktX
include("../examples/circuitX.jl")
runCircuitX()
end