########################################
## Delay differential equation        ##
########################################

export DDE

@doc* """
An example of a delayed feedback system.
""" ->
function DDE(; tau=3.0)

    function f(x)
        1 / (1 + exp (-x))
    end
    
    b   = 4.8
    a   = 4
    p   = -0.8
    
    x = Unknown("x",1.0)
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    @equations begin
        der(x) = -x + f(a * x - b * delay(x,tau) + p)
    end
end
