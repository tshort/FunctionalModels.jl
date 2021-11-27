########################################
## Test of the simulator with events  ##
## Van Der Pol oscillator             ##
## Automatic formulation              ##
########################################

export VanderpolWithEvents


"""
An extension of Sims.Examples.Basics.Vanderpol. Events are triggered
every 2 sec that change the quantity `mu`.
"""
function VanderpolWithEvents()
    @named y = Unknown(1.0)   
    @named x = Unknown()
    @named mu = Unknown(1.0)
    [
        der(x) ~ mu * (1 - y^2) * x - y
        der(y) ~ x
        Event(sin(pi/2 * t) ~ 0.0,     # Initiate an event every 2 sec.
              mu ~ mu * 0.75)
        der(mu) ~ 0.0
    ]
end

