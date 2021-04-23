using Sims, ModelingToolkit, Test

struct TstCtx end

@named x = Unknown(22.0)
@test default_value(x) == 22.0
@named xa = Unknown([1.0,2,3])
@test default_value(xa) == [1.0,2,3]
@test default_value(xa) == [1.0,2,3]
@test compatible_values(x, xa) == zeros(3)

@variables v(t) i(t)
v2 = ModelingToolkit.setmetadata(v, TstCtx, 1)

@test isequal(v, v2)
@test !isequal(v, Unknown(name = :v))