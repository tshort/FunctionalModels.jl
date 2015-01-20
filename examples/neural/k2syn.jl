## Two state kinetic scheme synapse described by rise time tauA, and
## decay time constant tauB.  Decay time must be greater than rise
## time.

function K2Syn(tauA,tauB,g,w,input)

    tau1 = ((tauA / tauB) > .9999) ? (0.9999 * tauB) : tauA
    tau2 = tauB

    tp = ((tau1 * tau2) / (tau2 - tau1) * log (tau2 / tau1))
    scale_factor = (1 / (- (exp(- (tp) / tau1)) + exp (- (tp) / tau2)))

    A = Unknown("A")
    B = Unknown("B")
    
    @equations begin
        der(A) = (- (A) / tau1)
        der(B) = (- (B) / tau2)

        g = B - A
        Event (input,
               Equation[
                        reinit(A, A + (w * scale_factor))
                        ])
    end
end    

