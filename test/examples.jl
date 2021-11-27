using Sims, Sims.Lib, Sims.Examples.Lib
using ModelingToolkit
using OrdinaryDiffEq

# using Plots
function MyResistor(n1::ElectricalNode, n2::ElectricalNode; 
                  R, T = 300.15, T_ref = 300.15, alpha = 0.0)
    i = Current()
    @named T = Parameter(300.15)
    v = Voltage(default_value(n1) - default_value(n2))
    [
        Branch(n1, n2, v, i)
        v ~ R .* (1 + alpha .* (T - T_ref)) .* i
    ]
end

function SimpleParameter()
    @variables n1(t)
    @named C = Parameter(2.0)
    @named R = Parameter(1.0)
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 1.0)
        :r1 => MyResistor(n1, g, R = R, alpha = 1.0)
        :c1 => Capacitor(n1, g, C = C)
    ]
end
function runSimpleParameter()
    m = SimpleParameter()
    ctx = Sims.flatten(m)
    @named sys = system(m)
end


using Sims, Sims.Lib, Sims.Examples.Lib
using ModelingToolkit
using OrdinaryDiffEq
# using Plots

res = sim(CharacteristicIdealDiodes, 1.0)

function runCharacteristicIdealDiodes()
    m = CharacteristicIdealDiodes()
    sys = system(m, simplify=false)
    @named sys = system(m)
    prob = ODEProblem(sys, Dict(k => 0.0 for k in states(sys)), (0, 1.0))
    sol = solve(prob, Rosenbrock23())
    # sol2 = solve(prob, Tsit5())
    # display(plot(sol))
    # (sys = sys, sol = sol)
end


function runCauerLowPass()
    res = Dict()
    for m in (CauerLowPassAnalog, CauerLowPassOPV, CauerLowPassOPV2)
        sys = system(m())
        prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 40.0))
        sol = solve(prob, Tsit5())
        # display(plot(sol))
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
    # display(plot(sol))
    (sys = sys, sol = sol) 
end

function runHeatingResistor()   #### BROKEN
    sys = system(HeatingResistor())
    prob = ODAEProblem(sys, Dict(k => 0.0 for k in states(sys)), (0, 10.0))
    sol = solve(prob, Tsit5())
    # display(plot(sol))
    (sys = sys, sol = sol)
end

function runShowVariableResistor()
    sys = system(ShowVariableResistor())
    prob = ODAEProblem(sys, Dict(k => 0.0 for k in states(sys)), (0, 6.0))
    sol = solve(prob, Tsit5())
    for m in (CauerLowPassAnalog, CauerLowPassOPV, CauerLowPassOPV2)
        sys = system(m())
        prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 40.0))
        sol = solve(prob, Tsit5())
        # display(plot(sol))
        res[m] = (sys = sys, sol = sol)
    end
    res
end



runCauerLowPass()
runChuaCircuit()

include("../examples/basics/friction.jl")
sys = system(UnitMassWithFriction(0.7))
prob = ODEProblem(sys, Dict(k => 0.0 for k in states(sys)), (0, 10pi))
sol = solve(prob, Tsit5())

module Ckt
include("../examples/circuit.jl")
runCircuit()
end

module CktX
include("../examples/circuitX.jl")
runCircuitX()
end