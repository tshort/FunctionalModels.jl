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
    y = Unknown(value = 1.0, label = "y", fixed = true)   
    x = Unknown("x")
    mu = Discrete(1.0)
    alpha = @liftd(0.8 * :mu)
    beta = @liftd(:alpha^2)
    mu_u = Unknown(value(mu), "mu_u") 
    alpha_u = Unknown(value(alpha), "alpha_u") 
    beta_u = Unknown(value(beta), "beta_u") 
    @equations begin
        der(x) = mu * (1 - y^2) * x - y
        der(y) = x
        mu_u    = mu
        alpha_u = alpha
        beta_u  = beta
        Event(sin(pi/2 * MTime),     # Initiate an event every 2 sec.
              Equation[
                  reinit(mu, mu * 0.75)
              ],
              Equation[
                  reinit(mu, mu * 1.8)
              ])
    end
end

