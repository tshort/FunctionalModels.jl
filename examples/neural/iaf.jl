
export LeakyIaF

@doc* """
A simple integrate-and-fire model example to illustrate
integrating over discontinuities.
""" ->
function LeakyIaF(;
                  gL     = Parameter(0.2),
                  vL     = Parameter(-70.0),
                  Isyn   = Parameter(20.0),
                  C      = Parameter(1.0),
                  theta  = Parameter(25.0),
                  vreset = Parameter(-65.0),

                  v::Unknown  = Voltage(vreset, "v")
                  )
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        der(v) = ( ((- gL) * (v - vL)) + Isyn) / C

        Event(v-theta,
             Equation[
              reinit(v, vreset)
              ],    # positive crossing
             Equation[])

     end
    
end
