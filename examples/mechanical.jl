



########################################
## Simple Mechanical Models           ##
########################################



#
# I'm not sure the mechanical models are right.
# There may be sign errors.
# 



Angle = AngularVelocity = AngularAcceleration = Torque = RotationalNode = Unknown

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

