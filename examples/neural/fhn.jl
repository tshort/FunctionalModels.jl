
########################################
## FitzHugh-Nagumo neuron model       ##
########################################

export FitzHughNagumo


"""
The FitzHugh-Nagumo model is a two-dimensional simplification of the
Hodgkin-Huxley model of spike generation.  It consists of two state
variables: a voltage-like variable with a nonlinearity that allows
regenerative self-excitation via positive feedback, and a recovery
variable with a linear dynamics that provides slower negative
feedback.

FitzHugh R. (1961) Impulses and physiological states in theoretical
models of nerve membrane. Biophysical J. 1:445–466

Nagumo J., Arimoto S., and Yoshizawa S. (1962) An active pulse
transmission line simulating nerve axon. Proc. IRE. 50:2061–2070.
"""
function FitzHughNagumo(;
                        Iext = Parameter(0.5),
                        tau  = Parameter(12.5),
                        a = 0.7,
                        b = 0.8,
                        v::Unknown = Unknown("v")
                        )
    w = Unknown("w")        
    @equations begin
        der(v) = v - (v^3 / 3)  - w + Iext
        der(w) = (v + a - b * w) / tau
    end
end
