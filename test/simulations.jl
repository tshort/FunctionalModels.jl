module TestSimulations

using Sims, Sims.Lib
using Base.Test

array_close(x, y) = all([abs(x[i] - y[i]) < abs(diff([extrema(x)...])[1]) * 0.01 for i in 1:length(x)]) # 1% error
array_approx(x, y) = all([isapprox(x[i],y[i]) for i in 1:length(x)])

# Compare Sundials to DASSL
s = create_simstate(Sims.Examples.Lib.ChuaCircuit())
yd = dasslsim(s, tstop = 2000.0)
ys = sunsim(s, tstop = 2000.0)
@test array_close(yd.y[:,3], ys.y[:,3])

# Ensure that multiple runs give the same answer
yd1 = dasslsim(s, tstop = 2000.0)
yd2 = dasslsim(s, tstop = 2000.0)
ys1 = sunsim(s, tstop = 2000.0)
ys2 = sunsim(s, tstop = 2000.0)
@test array_approx(yd1.y[:,3], yd2.y[:,3])
@test array_approx(ys1.y[:,3], ys2.y[:,3])


## Repeat now with an example that has Events and uses Discrete
## variables

s = create_simstate(Sims.Examples.Basics.VanderpolWithEvents())
yd1 = dasslsim(s, tstop = 50.0)
yd2 = dasslsim(s, tstop = 50.0)
ys1 = sunsim(s, tstop = 50.0)
ys2 = sunsim(s, tstop = 50.0)
@test array_approx(yd1.y[:,3], yd2.y[:,3])
@test array_approx(ys1.y[:,3], ys2.y[:,3])
@test array_close(yd1.y[:,3], ys1.y[:,3])


end # module
