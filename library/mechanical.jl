

#######################################
## Mechanical example                 ##
########################################



#
# I'm not sure these mechanical examples are right.
# There may be sign errors.
# 



Angle = AngularVelocity = AngularAcceleration = Torque = RotationalNode = Unknown

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

function Inertia(flangeA, flangeB, J::Real)
    tauA = Torque()
    tauB = Torque()
    w = AngularVelocity()
    a = AngularAcceleration()
    {
     RefBranch(flangeA, tauA)
     RefBranch(flangeB, tauB)
     flangeA - flangeB    # the angles are both equal
     w - der(flangeA)
     a - der(w)
     tauA + tauB - J * a
     }
end


function Spring(flangeA, flangeB, c::Real)
    relphi = Angle()
    tau = Torque()
    {
     Branch(flangeB, flangeA, relphi, tau)
     tau - c * relphi
     }
end


function Damper(flangeA, flangeB, d::Real)
    relphi = Angle()
    tau = Torque()
    {
     Branch(flangeB, flangeA, relphi, tau)
     tau - d * der(relphi)
     }
end

function ShaftElement(flangeA, flangeB)
    r1 = RotationalNode()
    {
     Spring(flangeA, r1, 8.0) 
     Damper(flangeA, r1, 1.5) 
     Inertia(r1, flangeB, 0.5) 
     }
end

function IdealGear(flangeA, flangeB, ratio)
    tauA = Torque()
    tauB = Torque()
    {
     RefBranch(flangeA, tauA)
     RefBranch(flangeB, tauB)
     flangeA - ratio * flangeB
     ratio * tauA + tauB
     }
end


function TorqueSrc(flangeA, flangeB, tau)
    {
     RefBranch(flangeA, tau)
     RefBranch(flangeB, tau)
     }
end

