
#######################################
# Izhikevich Fast Spiking neuron model.
#######################################

function IzhikevichFS(;
                      Isyn  = Parameter(0.0),
                      Iext  = Parameter(400.0),

                      k     =   1.0,
                      Vinit = -65.0,
                      Vpeak =  25.0,
                      Vt    = -55.0,
                      Vr    = -40.0,
                      Vb    = -55.0,
                      Cm    =  20.0,

                      FS_a = 0.2,
                      FS_b = 0.025,
                      FS_c = -45.0,
                      FS_U = FS_b * -65.0,

                      v::Unknown  = Voltage(-60.899, "v")
                      )
    
    u   = Unknown(FS_U,  "u")
    s   = Unknown()
    
    @equations begin
        der(v) = ((k * (v - Vr) * (v - Vt)) + (- u) + Iext) / Cm
        der(u) = FS_a * (s - u)
        s = FS_b * (v - Vb) ^ 3
   
        Event(v-Vpeak,
             Equation[
                 reinit(v, FS_c)
             ],    # positive crossing
             Equation[])

     end
    
end

