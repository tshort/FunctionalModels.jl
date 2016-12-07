##########################################################
## Adaptive exponential integrate-and-fire neuron model ##
##########################################################

export AdEx

function AdEx(;
              Isyn  =  Parameter(210.0),

              C     = 200.0,
              gL    =  10.0,
              EL    = -58.0,
              VT    = -50.0,
              Delta = 2.0,
              theta = 0.0,
              trefractory = 0.25,

              a = 2.0,
              b = 100.0,
              tau_w = 120.0,
              
              Vr = -46.0,
              V::Unknown = Unknown(Vr, "V")
              )

    
    W   = Unknown(Vr, "W")
    
    @equations begin
        der(V) = (( ((- gL) * (V - EL)) +
                   (gL * Delta * (exp((V - VT) / Delta))) +
                   (- W) + Isyn) / C)
        der(W) = (((a * (V - EL)) - W) / tau_w)
   
        Event(V-theta,
             Equation[
                 reinit(V, Vr)
             ],    # positive crossing
             Equation[])

     end
    
end
