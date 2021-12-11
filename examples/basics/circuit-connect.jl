using Sims, ModelingToolkit
using OrdinaryDiffEq
# using Plots

Current(x = 0.0; name = :i) = Unknown(x, name = name)
Voltage(x = 0.0; name = :v) = Unknown(x, name = name)

struct Pin
    v
    i
end
Pin() = Pin(Voltage(), Current())


function connect(x, y)
    i = Current()
    [
        RefBranch(x.v, i)
        RefBranch(y.v, -i)
        x.v ~ y.v
    ]
end


Gnd() = Pin(0.0, Current())

function VoltageSource(; V) 
    p = Pin()
    n = Pin()
    v = Voltage()
    # v = p.v - n.v
    (p = p,
     n = n,
     v = v,
     eq = 
        [
            Branch(p.v, n.v, v, p.i)
            p.i ~ -n.i
            v ~ V
        ]
    )
end

function Resistor(; R) 
    p = Pin()
    n = Pin()
    v = Voltage()
    (p = p,
     n = n,
     v = v,
     eq = 
        [
            Branch(p.v, n.v, v, p.i)
            p.i ~ -n.i
            v ~ R * p.i
        ]
    )
end

function Capacitor(; C) 
    p = Pin()
    n = Pin()
    v = Voltage()
    (p = p,
     n = n,
     v = v,
     eq = 
        [
            Branch(p.v, n.v, v, p.i)
            p.i ~ -n.i
            D(v) ~ p.i / C
        ]
    )
end

function Subsystem()
    p = Pin()
    n = Pin()
    g = Gnd()
    r1 = Resistor(R = 10.0)
    c1 = Capacitor(C = 5.0e-3)
    r2 = Resistor(R = 5.0)
    (p = p,
     n = n,
     eq = 
        [
            :r1 => r1.eq 
            :c1 => c1.eq 
            :r2 => r2.eq 
            connect(r1.p, p)
            connect(r1.n, c1.p)
            connect(c1.n, n)
            connect(r2.p, n)
            connect(r2.n, g)
        ]
    )
end

function CircuitConnect()
    vsrc = VoltageSource(V = sin(2pi * 60 * t))
    ss = Subsystem()
    c1 = Capacitor(C = 5.0e-3)
    g = Gnd()
    Any[
        :vsrc => vsrc.eq
        :ss => ss.eq
        :c1 => c1.eq
        connect(vsrc.p, ss.p)
        connect(vsrc.n, g)
        connect(ss.n, c1.p)
        connect(c1.n, g)
    ]
end

function runCircuitConnect()
    ckt = CircuitConnect()
    sys = system(ckt)
    prob = ODAEProblem(sys, [k => 0.0 for k in states(sys)], (0, 0.1))
    sol = solve(prob, Tsit5())
    # plot(sol)
    # plot(sol, vars = [v1, v2])
end
function tstCircuitConnect()
    ckt = CircuitConnect()
    ctx = Sims.flatten(ckt)
    sys = system(ckt)
end
