########################################
## Van Der Pol oscillator             ##
########################################

#
# Tom Short, tshort@epri.com
#

export Vanderpol


"""
The Van Der Pol oscillator is a simple problem with two equations
and two unknowns.
"""
function Vanderpol()
    @named y = Unknown(1.0)   # The 1.0 is the initial value. "y" is for plotting.
    @named x = Unknown()        # The initial value is zero if not given.
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    [
        D(x) ~ (1 - y^2) * x - y 
        D(y) ~ x
    ]
end
