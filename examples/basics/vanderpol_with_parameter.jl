########################################
## Van Der Pol oscillator             ##
########################################

#
# Tom Short, tshort@epri.com
#

export VanderpolWithParameter


#
# A device model is a function that returns a list of equations or
# other devices that also return lists of equations. The equations
# each are assumed equal to zero. So,
#    der(y) = x + 1
# Should be entered as:
#    der(y) - (x+1)
#

"""
The Van Der Pol oscillator is a simple problem with two equations
and two unknowns.
"""
function VanderpolWithParameter(mu)
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    [
        # The -1.0 in der(x, -1.0) is the initial value for the derivative 
        der(x, -1.0) ~ mu * (1 - y^2) * x - y 
        der(y) ~ x
    ]
end
