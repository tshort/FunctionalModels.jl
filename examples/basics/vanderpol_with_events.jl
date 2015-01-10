########################################
## Test of the simulator with events  ##
## Van Der Pol oscillator             ##
## Automatic formulation              ##
########################################

export VanderpolWithEvents


@doc """
An extension of Sims.Examples.Basics.Vanderpol. Events are triggered
every 2 sec that change the quantity `mu`.
""" ->
function VanderpolWithEvents()
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
    mu_unk = Unknown(1.0, "mu_unk") 
    mu = Discrete(1.0, "mu")
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    @equations begin
        # The -1.0 in der(x, -1.0) is the initial value for the derivative 
        der(x, -1.0) = mu * (1 - y^2) * x - y
        der(y) = x
        mu_unk = mu
        Event(sin(pi/2 * MTime),     # Initiate an event every 2 sec.
              Equation[
                  reinit(mu, mu * 0.75)
              ],
              Equation[
                  reinit(mu, mu * 1.8)
              ])
    end
end

