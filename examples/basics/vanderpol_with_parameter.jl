########################################
## Van Der Pol oscillator             ##
########################################

#
# Tom Short, tshort@epri.com
#

export VanderpolWithParameter



"""
The Van Der Pol oscillator is a simple problem with two equations
and two unknowns.
"""
function VanderpolWithParameter(mu)
    @named y = Unknown(1.0)   # The 1.0 is the initial value. "y" is for plotting.
    @named x = Unknown()      # The initial value is zero if not given.
    @named mu = Parameter(mu)
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    [
        # The -1.0 in der(x, -1.0) is the initial value for the derivative 
        der(x) ~ mu * (1 - y^2) * x - y 
        der(y) ~ x
    ]
end
