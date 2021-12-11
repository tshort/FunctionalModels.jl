using ModelingToolkit 
using OrdinaryDiffEq

@parameters t
const D = Differential(t)
@parameters a = -2.0
@parameters b = 1.0
@parameters x0 = 0.5
# @variables x(t) = $(x0)
# @variables x(t) = x0
@variables x(t) = 0.5
@variables dx(t) = 0.3

eq = [D(x) ~ dx
      dx ~ a * x + b]

sys = ODESystem(eq, t, [], [a, b], defaults=[a=>-2.5, b=>1.0])
sys2 = structural_simplify(sys)
prob = ODAEProblem(sys2, [x => 0.5], (0, 0.1))
sol = solve(prob, Tsit5())

