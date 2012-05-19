

load("../src/sims.jl")
load("../library/electrical.jl")



########################################
## Square wave - test discontinuities ##
########################################



#
# The following model has discontinuities. This simulator does not
# detect events. DASSL is set up to restart when things go wrong. In
# the following case, this approach seems to work. Also, note that I
# had to add methods for several more functions that didn't support
# MExpr's.
#




function VSquare(n1, n2, V::Real, f::Real)  
    i = Current()
    v = Voltage()
    v_mag = Discrete(V)
    {
     Branch(n1, n2, v, i)
     v - v_mag
     Event(sin(2 * pi * f * MTime),
           {reinit(v_mag, V)},    # positive crossing
           {reinit(v_mag, -V)})   # negative crossing
     }
end

function CircuitSq()
    n1 = ElectricalNode("Source voltage")
    n2 = ElectricalNode("Output voltage")
    g = 0.0  # a ground has zero volts; it's not an unknown.
    {
     VSquare(n1, g, 11.0, 6.0)
     Resistor(n1, n2, 10.0)
     Resistor(n2, g, 5.0)
     Capacitor(n2, g, 5.0e-3)
     }
end

ckt_b = CircuitSq()
ckt_b_yout = sim(ckt_b, 0.5)  
