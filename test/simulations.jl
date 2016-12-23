module TestSimulations

using JuMP
using Sims, Sims.Lib
using Base.Test

array_close(x, y) = all([abs(x[i] - y[i]) < abs(diff([extrema(x)...])[1]) * 0.1 for i in 1:length(x)]) &&  # 10% difference
                    cor(x, y) > 0.999 
array_approx(x, y) = all([isapprox(x[i],y[i]) for i in 1:length(x)])

## Compare Sundials to DASSL
s1 = create_simstate(Sims.Examples.Lib.ChuaCircuit())
ys = sunsim(s1, tstop = 2000.0)
if Sims.hasdassl
    yd = dasslsim(s1, tstop = 2000.0)
    @test array_close(yd.y[:,3], ys.y[:,3])
end
## Ensure that multiple runs give the same answer
if Sims.hasdassl
    yd1 = dasslsim(s1, tstop = 2000.0)
    yd2 = dasslsim(s1, tstop = 2000.0)
    @test array_approx(yd1.y[:,3], yd2.y[:,3])
end
ys1 = sunsim(s1, tstop = 2000.0)
ys2 = sunsim(s1, tstop = 2000.0)
@test array_approx(ys1.y[:,3], ys2.y[:,3])


## Repeat now with an example that has Events and uses Discrete
## variables

s2 = create_simstate(Sims.Examples.Basics.VanderpolWithEvents())
ys1 = sunsim(s2, tstop = 50.0)
ys2 = sunsim(s2, tstop = 50.0)
ys3 = sunsim(s2, tstop = 50.0)
@test array_approx(ys1.y[:,3], ys2.y[:,3])
@test isapprox(ys1.y[end,end], 859.3902414298703)    # I don't know if this check is too precise
if Sims.hasdassl
    yd1 = dasslsim(s2, tstop = 50.0)
    yd2 = dasslsim(s2, tstop = 50.0)
    @test array_approx(yd1.y[:,3], yd2.y[:,3])
    @test array_close(yd1.y[:,3], ys1.y[:,3])
end

## Make sure simulations with s1 still work and there is no spillover
if Sims.hasdassl
    ydx1 = dasslsim(s1, tstop = 2000.0)
    @test array_approx(yd.y[:,3], ydx1.y[:,3])
end
ysx1 = sunsim(s1, tstop = 2000.0)
@test array_approx(ys.y[:,3], ysx1.y[:,3])

# ## Test initialize!

# s3 = create_simstate(Sims.Examples.Lib.ChuaCircuit())
# initialize!(s3)
# yss = sunsim(s3, tstop = 2000.0, init = :none)
# if Sims.hasdassl
#     yds = dasslsim(s3, tstop = 2000.0, init = :none)
#     @test array_close(yss.y[:,3], yds.y[:,3])
# end


end # module
