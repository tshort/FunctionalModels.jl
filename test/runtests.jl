using SafeTestsets, Test

@safetestset "Flattening" begin include("flattening.jl") end
@safetestset "Variables" begin include("variables.jl") end
@safetestset "Examples: Basics" begin include("examples_basics.jl") end
@safetestset "Examples: Lib electrical" begin include("examples_lib_electrical.jl") end
@safetestset "Examples: Lib heat transfer" begin include("examples_lib_heat_transfer.jl") end
@safetestset "Examples: Lib rotational" begin include("examples_lib_rotational.jl") end
@safetestset "Examples: Tiller" begin include("examples_tiller.jl") end
