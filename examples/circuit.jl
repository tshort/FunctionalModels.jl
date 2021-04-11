using Sims, ModelingToolkit, DifferentialEquations

Current() = Num(Variable{ModelingToolkit.FnType{Tuple{Any},Real}}(gensym("i")))(t)
Voltage() = Num(Variable{ModelingToolkit.FnType{Tuple{Any},Real}}(gensym("v")))(t)

function VoltageSource(n1, n2, V) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        v ~ V
    ]
end

function Resistor(n1, n2, R::Real) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        v ~ R * i
    ]
end

function Capacitor(n1, n2, C::Real) 
    i = Current()
    v = Voltage()
    [
        Branch(n1, n2, v, i)
        i ~ C * D(v)
    ]
end

function Circuit()
    @variables v1(t) v2(t)
    g = 0.0  # A ground has zero volts; it's not a variable.
    [
        VoltageSource(v1, g, sin(2pi * 60 * t))
        Resistor(v1, v2, 10.0)
        Resistor(v2, g, 5.0)
        Capacitor(v2, g, 5.0e-3)
    ]
end

ckt = Circuit()

sys = system(ckt)
prob = ODAEProblem(sys, [], (0, 0.1))
sol = solve(prob, Tsit5())
plot(sol)
