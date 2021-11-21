using Sims, ModelingToolkit, Test

function m1(a, b)
    @named x = Unknown()
    [
        b ~ x
        D(a) ~ b
    ]
end

function m2(a, b)
    @named x = Unknown()
    [
        D(x) ~ b
        x ~ a
    ]
end

function ss(a, b)
    @named x = Unknown()
    [
        :m1 => m1(x, a) 
        :m2 => m2(x, b) 
    ]
end

function mod()
    @named x = Unknown(3.0)
    @named y = Unknown()
    [
        :m1 => m1(x, y) 
        :ss => ss(x, y)
    ]
end

m = mod()

ctx = Sims.flatten(m)

sys = system(m)

@test length(states(sys)) == length(equations(sys))

@variables x(t) ssₓx(t) ssₓm2ₓx(t)

@test all(x in states(sys) for x in [x, ssₓx, ssₓm2ₓx])