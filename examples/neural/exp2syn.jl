
function Exp2Syn(v,s)
    @equations begin
        der(s) = alpha * k_(v) * (1-s) - beta * s
    end
end    


(component (type post-synaptic-conductance) (name AMPA)

        (input (w from event (unit uS)))

        (const tauA = 0.03 (unit ms)) ;; rise time
	(const tauB = 0.5 (unit ms)) ;; decay time

        (const  e = 0 )

        (const tau1 = (if ((tauA / tauB) > .9999) then (0.9999 * tauB) else tauA))
        (const tau2 = tauB)

	(const tp = ((tau1 * tau2) / (tau2 - tau1) * ln (tau2 / tau1)))
	(const scale_factor  = (1 / (neg (exp(neg (tp) / tau1)) + exp (neg (tp) / tau2))))

	(transient (A) = (neg (A) / tau1) (onevent (A + (w * scale_factor))) (initial 0))
	(transient (B) = (neg (B) / tau2) (onevent (B + (w * scale_factor))) (initial 0))

        (g =  (B - A))

