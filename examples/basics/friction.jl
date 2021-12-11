using Sims, ModelingToolkit

function UnitMassWithFriction(k)
    v = Unknown(0.0, name = :v)
    x = Unknown(0.0, name = :x)
    [
    D(x) ~ v
    D(v) ~ sin(t) - k * sign(v) # f = ma, sinusoidal force acting on the mass, and Coulomb friction opposing the movement
    Event(v ~ 0)
    ]
end
# sys = system(UnitMassWithFriction(0.7))
# prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 40.0))
# sol = solve(prob, Tsit5())

# using ModelingToolkit, OrdinaryDiffEq, Plots
# function UnitMassWithFriction(k; name)
#   @variables t x(t)=0 v(t)=0
#   D = Differential(t)
#   eqs = [
#     D(x) ~ v
#     D(v) ~ sin(t) - k*sign(v) # f = ma, sinusoidal force acting on the mass, and Coulomb friction opposing the movement
#   ]
#   ODESystem(eqs, t, continuous_events=[v ~ 0], name=name) # when v = 0 there is a discontinuity
# end

# @named m = UnitMassWithFriction(0.7)
# prob = ODEProblem(m, Pair[], (0, 10pi))
# sol = solve(prob, Tsit5())
# plot(sol)
