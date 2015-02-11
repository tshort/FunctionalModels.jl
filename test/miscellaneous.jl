module MiscellaneousTests

using Sims
using Base.Test

# issue #55
function m()
    a = Unknown("a")
    d = Discrete()
    Equation[
        a - d
        Event(MTime - 0.1, reinit(d, 2.0))     
        Event(MTime - 0.3, reinit(d, 3.0))     
    ]
end
s = create_simstate(m())
y = sim(s);

@test y.y[1,2] == 0.0
@test y.y[150,2] == 2.0
@test y.y[end,2] == 3.0

end
