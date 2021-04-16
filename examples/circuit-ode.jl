module M

using ModelingToolkit, Plots, DifferentialEquations


struct NodeSet end

RefBranch(x, i) = nothing
function RefBranch(n::Num, i)
    meta = Symbolics.getmetadata(n.val, NodeSet, Num[])
    push!(meta, i)
    Symbolics.setmetadata(n.val, NodeSet, meta)
    nothing
end

function Branch(n1, n2, v, i)
    RefBranch(n1, i)
    RefBranch(n2, -i)
    v ~ n1 - n2
end

@parameters t
const D = Differential(t)

function VoltageSource(n1, n2, V; name) 
    @variables i(t)
    @variables v(t)
    eqs = [
        Branch(n1, n2, v, i)
        v ~ V
    ]
    ODESystem(eqs, t, [i, v], [], name=name)
end

function Resistor(n1, n2, R; name) 
    @variables i(t)
    @variables v(t)
    eqs = [
        Branch(n1, n2, v, i)
        v ~ R * i
    ]
    ODESystem(eqs, t, [i, v], [], name=name)
end

function Capacitor(n1, n2, C; name) 
    @variables i(t)
    @variables v(t)
    eqs = [
        Branch(n1, n2, v, i)
        D(v) ~ i / C
    ]
    ODESystem(eqs, t, [i, v], [], name=name)
end

function Circuit(; name)
    @variables v1(t) v2(t)
    g = 0.0  # A ground has zero volts; it's not a variable.
    systems = [
        VoltageSource(v1, g, sin(2pi * 60 * t), name = :vsrc)
        Resistor(v1, v2, 10.0, name = :r1)
        Resistor(v2, g, 5.0, name = :r2)
        Capacitor(v2, g, 5.0e-3, name = :c1)
    ]
    ODESystem(Equation[], t, [v1, v2], [], systems=systems, name=name)
end

@named ckt = Circuit()

end # module