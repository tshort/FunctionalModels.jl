
export LeakyIaF

@doc* """
A simple integrate-and-fire model example to illustrate
integrating over discontinuities.
""" ->
function LeakyIaF(;
                  Isyn   = Parameter(20.0),
                  gL     = Parameter(0.2),
                  vL     = Parameter(-70.0),
                  C      = Parameter(1.0),
                  theta  = Parameter(25.0),
                  vreset = -65.0,

                  v::Unknown  = Voltage(vreset, "v")
                  )
    
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Regular
    # variables are evaluated immediately (like normal).
    @equations begin

        C * der(v) = ( ((- gL) * (v - vL)) + Isyn)

        Event(v-theta,
             Equation[
              reinit(v, vreset)
              ],    # positive crossing
             Equation[])

     end
    
end
