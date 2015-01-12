########################################
## Test of the simulator with events  ##
## Van Der Pol oscillator             ##
## Automatic formulation              ##
########################################

export VanderpolWithEvents

using Reactive

@doc """
An extension of Sims.Examples.Basics.Vanderpol. Events are triggered
every 2 sec that change the quantity `mu`.
""" ->
function VanderpolWithEvents(mu)
    y = Unknown(1.0, "y")   
    x = Unknown("x")       
    alpha = lift(a -> 0.8 * a, Float64, mu)
    beta = lift(a -> a^2, Float64, alpha)
    mu_u = Unknown(Sims.value(mu), "mu_u") 
    alpha_u = Unknown(Sims.value(alpha), "alpha_u") 
    beta_u = Unknown(Sims.value(beta), "beta_u") 
    @equations begin
        # The -1.0 in der(x, -1.0) is the initial value for the derivative 
        der(x, -1.0) = mu * (1 - y^2) * x - y
        der(y) = x
        mu_u    = mu
        alpha_u = alpha
        beta_u  = beta
        Event(sin(pi/2 * MTime),     # Initiate an event every 2 sec.
              Equation[
                  push!(mu, mu * 0.7)
              ],
              Equation[
                  push!(mu, mu * 1.8)
              ])
    end
end

