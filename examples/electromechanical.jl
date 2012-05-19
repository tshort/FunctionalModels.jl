load("electromechanical.jl")



function EMF(n1, n2, flange, k::Real)
    tau = Torque()
    i = Current()
    v = Voltage()
    w = AngularVelocity()
    {
     Branch(n1, n2, i, v)
     RefBranch(flange, tau)
     w - der(flange)
     v - k * w
     tau - k * i
     }
end

function DCMotor(flange)
    n1 = ElectricalNode()
    n2 = ElectricalNode()
    n3 = ElectricalNode()
    g = 0.0
    {
     VConst(n1, g, 60)
     Resistor(n1, n2, 100.0)
     Inductor(n2, n3, 0.2)
     EMF(n3, g, flange, 1.0)
     }
end
