module Lib

using Sims, Sims.Lib

export Gate, UConductance, Conductance
export F, R
export OhmicCurrent, GHKCurrent, MembranePotential
export Connect
export ghk, nernst

## Types of biophysical quantities used in neural models

type UConductance <: UnknownCategory
end

typealias Gate Unknown{DefaultUnknown,NonNegative}
typealias Conductance Unknown{UConductance,NonNegative}

const F = 96485.3
const R =  8.3145


function ghk (celsius, v, ci, co, z)
    let T = celsius + 273.15
        E = (1e-3) * v
        k0 = ((z * (F * E)) / (R * T))
        k1 = exp (- k0)
        k2 = ((z ^ 2) * (E * (F ^ 2))) / (R * T)
        return (1e-6) * (ifelse (abs (1 - k1) < 1e-6,
                                 (z * F * (ci - (co * k1)) * (1 - k0)),
                                 (k2 * (ci - (co * k1)) / (1 - k1))))
    end
end


function ktf (celsius)
    return (1000.0 * R * (celsius + 273.15) / F )
end

function nernst (celsius, ci, co, z) 
    ifelse (ci <= 0, 1e6,
            ifelse (co <= 0, -1e6,
                    ktf (celsius) / z * (log (co / ci))))
end


function GHKCurrent (celsius,v,i,p,ci,co,z)
    @equations begin
        i = p * ghk(celsius, v, ci, co, z)
    end
end

function OhmicCurrent (v,i,g,erev)
    @equations begin
        i = g * (v - erev)
    end
end

function MembranePotential(v,currents,c)
    @equations begin
        c * der(v) = - foldl((i,ax) -> i+ax, currents)
    end
end

function Connect(I,g,n1,n2)
   @equations begin
       g * I = n2 - n1
   end
end


end # module Lib
