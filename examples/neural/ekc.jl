

##########################################################
## Ermentrout-Kopell canonical neuron model.
##########################################################

export ErmentroutKopell

function ErmentroutKopell(;
                          alpha = 0.012,
                          beta  = 0.01,
                          theta = Unknown(1.0, "theta")
                          )
    @equations begin
        der(theta) = 1 - cos(theta) + alpha * (1 + cos(theta)) * sin(beta * MTime)
        
        Event(theta-pi,
             Equation[
                 reinit(theta, theta-2*pi)
             ],    # positive crossing
             Equation[])

    end
end
