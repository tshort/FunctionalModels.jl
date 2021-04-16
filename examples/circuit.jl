using Sims, ModelingToolkit, DifferentialEquations, Plots
# using Sims, ModelingToolkit

Current() = Unknown(:i)
Voltage() = Unknown(:v)

function VoltageSource(n1, n2; V, name) 
    i = Current()
    v = Voltage()
    name => [
        Branch(n1, n2, v, i)
        v ~ V
    ]
end

function Resistor(n1, n2; R, name) 
    i = Current()
    v = Voltage()
    name => [
        Branch(n1, n2, v, i)
        v ~ R * i
    ]
end

function Capacitor(n1, n2; C, name) 
    i = Current()
    v = Voltage()
    name => [
        Branch(n1, n2, v, i)
        D(v) ~ i / C
    ]
end

function Subsystem(n1, n2; name)
    @variables vs(t)
    g = 0.0  # A ground has zero volts; it's not a variable.
    name => [
        Resistor(n1, vs, R = 10.0, name = :r1)
        Capacitor(vs, n2, C = 5.0e-3, name = :c1)
        Resistor(n2, g, R = 5.0, name = :r2)
    ]
end

function Circuit(v1, v2)
    g = 0.0  # A ground has zero volts; it's not a variable.
    [
        VoltageSource(v1, g, V = sin(2pi * 60 * t), name = :vsrc)
        Subsystem(v1, v2, name = :ss)
        Capacitor(v2, g, C = 5.0e-3, name = :c1)
    ]
end

@variables v1(t) v2(t)
ckt = Circuit(v1, v2)

sys = system(eq)
prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 0.1))
sol = solve(prob, Tsit5())
plot(sol)
plot(sol, vars = [v1, v2])
