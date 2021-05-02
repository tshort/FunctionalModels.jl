using SafeTestsets, Test

@safetestset "Examples" begin include("examples.jl") end
@safetestset "Flattening" begin include("flattening.jl") end
@safetestset "Variables" begin include("variables.jl") end
