
############################
# Morris-Lecar neuron model.
############################
  	                   


function MorrisLecar(;
                     Istim =  Parameter(50.0),
                     c   =   20.0,
                     vk  =  -70.0,
                     vl  =  -50.0,
                     vca =  100.0,
                     gk  =    8.0,
                     gl  =    2.0,
                     gca =    4.0,
                     v1  =   -1.0,
                     v2  =   15.0,
                     v3  =   10.0,
                     v4  =   14.5,
                     phi =   0.0667,
                     v   = Voltage(-60.899, "v")
                     )
                     
    minf (v) = (0.5 * (1.0 + tanh ((v - v1) / v2)))
    winf (v) = (0.5 * (1.0 + tanh ((v - v3) / v4)))
    lamw (v) = (phi * cosh ((v - v3) / (2.0 * v4)))

    w   = Unknown(0.0149,  "w")
    ica = Unknown()   
    ik  = Unknown()   

    @equations begin
        der(v) = (Istim + (gl * (vl - v)) + ica + ik) / c   
        der(w) = lamw (v) * (winf(v) - w)
        ica = gca * (minf (v) * (vca - v))
        ik  = gk * (w * (vk - v))
    end
end

