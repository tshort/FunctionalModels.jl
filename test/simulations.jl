module TestSimulations

using JuMP
using Sims, Sims.Lib
using Base.Test

array_close(x, y) = all([abs(x[i] - y[i]) < abs(diff([extrema(x)...])[1]) * 0.1 for i in 1:length(x)]) &&  # 10% difference
                    cor(x, y) > 0.999 
array_approx(x, y) = all([isapprox(x[i],y[i]) for i in 1:length(x)])

## Compare Sundials to DASSL
s1 = create_simstate(Sims.Examples.Lib.ChuaCircuit())
yd = dasslsim(s1, tstop = 2000.0)
ys = sunsim(s1, tstop = 2000.0)
@test array_close(yd.y[:,3], ys.y[:,3])

## Ensure that multiple runs give the same answer
yd1 = dasslsim(s1, tstop = 2000.0)
yd2 = dasslsim(s1, tstop = 2000.0)
ys1 = sunsim(s1, tstop = 2000.0)
ys2 = sunsim(s1, tstop = 2000.0)
@test array_approx(yd1.y[:,3], yd2.y[:,3])
@test array_approx(ys1.y[:,3], ys2.y[:,3])


## Repeat now with an example that has Events and uses Discrete
## variables

s2 = create_simstate(Sims.Examples.Basics.VanderpolWithEvents())
yd1 = dasslsim(s2, tstop = 50.0)
yd2 = dasslsim(s2, tstop = 50.0)
ys1 = sunsim(s2, tstop = 50.0)
ys2 = sunsim(s2, tstop = 50.0)
@test array_approx(yd1.y[:,3], yd2.y[:,3])
@test array_approx(ys1.y[:,3], ys2.y[:,3])
@test array_close(yd1.y[:,3], ys1.y[:,3])

## Make sure simulations with s1 still work and there is no spillover
ydx1 = dasslsim(s1, tstop = 2000.0)
ysx1 = sunsim(s1, tstop = 2000.0)
@test array_approx(yd.y[:,3], ydx1.y[:,3])
@test array_approx(ys.y[:,3], ysx1.y[:,3])

## Test initialize!

s3 = create_simstate(Sims.Examples.Lib.ChuaCircuit())
initialize!(s3)
yss = sunsim(s3, tstop = 2000.0, init = :none)
yds = dasslsim(s3, tstop = 2000.0, init = :none)
@test array_close(yss.y[:,3], yds.y[:,3])


end # module
