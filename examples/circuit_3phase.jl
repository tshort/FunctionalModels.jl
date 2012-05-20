

load("../src/sims.jl")
load("electrical.jl")



function ResistorN(n1, n2, R::Real) 
    i = Current(base_value(n1, n2))   # The base_value makes the size match with
    v = Voltage(base_value(n1, n2))   # the larger of n1 and n2.
    {
     Branch(n1, n2, v, i)
     R * i - v   # == 0 is implied
     }
end

function CapacitorN(n1, n2, C::Real) 
    i = Current(base_value(n1, n2))   # The base_value makes the size match with
    v = Voltage(base_value(n1, n2))   # the larger of n1 and n2.
    {
     Branch(n1, n2, v, i)
     C * der(v) - i
     }
end

function VSource3(n1, n2, V::Real, f::Real)  
    ang = [0, -2 / 3 * pi, 2 / 3 * pi]
    i = Current(base_value(n1, n2))   # The base_value makes the size match with
    v = Voltage(base_value(n1, n2))   # the larger of n1 and n2.
    {
     Branch(n1, n2, v, i) 
     v - V * sin(2 * pi * f * MTime + ang)
     }
end

function CircuitThreePhase()
    n1 = ElectricalNode(zeros(3), "Source voltage")
    n2 = ElectricalNode(zeros(3), "Output voltage")
    g = 0.0
    {
     VSource3(n1, g, 10.0, 60.0)
     ResistorN(n1, n2, 10.0)
     ResistorN(n2, g, 5.0)
     CapacitorN(n2, g, 5.0e-3)
     }
end

ckt3p = CircuitThreePhase()
ckt3p_yout = sim(ckt3p, 0.1)
