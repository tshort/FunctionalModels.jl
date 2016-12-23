using Sims
using Base.Test

println("== run all examples")
println("= Basics examples")
Sims.Examples.Basics.runall()
println("= Lib examples")
Sims.Examples.Lib.runall()
# println("= Neural examples")
# Sims.Examples.Neural.runall()
println("= Tiller examples")
Sims.Examples.Tiller.runall()
if Sims.hasdassl
    Sims.defaultsim(dasslsim)
    println("== run all examples with DASSL")
    println("= Basics examples")
    Sims.Examples.Basics.runall()
    println("= Lib examples")
    Sims.Examples.Lib.runall()
    # println("= Neural examples")
    # Sims.Examples.Neural.runall()
    println("= Tiller examples")
    Sims.Examples.Tiller.runall()
    Sims.defaultsim(sunsim)
end

println("== run other tests")
println("= simulations")
include("simulations.jl")
println("= miscellaneous")
include("miscellaneous.jl")
