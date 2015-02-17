
########################################
## Hindmarsh-Rose neuron model        ##
########################################

export HindmarshRose

function HindmarshRose(; I = 0.1,
                       
                       a = 1.0,
                       b = 3.0,
                       c = 1.0,
                       d = 5.0,

                       r = 1e-3,
                       s = 4.0,
                       xr = -8/5)

    phi_(x) = -a * x ^ 3 + b * x ^ 2
    psi(x)  = c - d * x^2

    x = Unknown(-1.0,"x")   
    y = Unknown("y")        
    z = Unknown("z")
    
    @equations begin
        der(x) = y + phi_(x) - z + I 
        der(y) = psi(x) - y
        der(z) = r * (s * (x - xr) - z)
    end
end
