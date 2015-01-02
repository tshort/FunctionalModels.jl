using Sims

## Examples of initial conditions

#
# These only work for "balanced" cases meaning the number of inputs
# equals the number of outputs.
#
# Still need to figure out how to make that happen for the more
# common underdetermined case.
#

function test()
    @unknown x y
    @equations begin
        2*x - y = exp(-x)
         -x + 2*y = exp(-y)
     end
end
f = elaborate(test())
sm = create_sim(f)
res = inisolve(sm)

function mkin()
    @unknown x(1.0) y(1.0)
    @equations begin
        x^2 + y^2 = 1.0
        y = x^2
    end
end

sm = create_sim(mkin())
res = inisolve(sm)


## BROKEN
function fun()
    @unknown x
    y = Unknown(:y, 1.0, true)
    @equations begin
        x^2 + y^2 = 1.0
        der(y, 0.0) = x
    end
end

## sm = create_sim(fun())
## res = inisolve(sm)
