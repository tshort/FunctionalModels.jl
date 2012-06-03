
########################################
## Rotational Mechanical Models       ##
########################################



#
# I'm not sure the mechanical models are right.
# There may be sign errors.
# 



function Inertia(flange_a::Flange, flange_b::Flange, J::Real)
    "1D-rotational component with inertia"
    val = compatible_values(flange_a, flange_b)
    tau_a = Torque(val)
    tau_b = Torque(val)
    w = AngularVelocity(val)
    a = AngularAcceleration(val)
    {
     RefBranch(flange_a, tau_a)
     RefBranch(flange_b, tau_b)
     flange_b - flange_a    # the angles are both equal
     w - der(flange_a)
     a - der(w)
     tau_a + tau_b - J .* a
     }
end


function Disc(flange_a::Flange, flange_b::Flange, deltaPhi::Signal)
    "1-dim. rotational rigid component without inertia, where right flange is rotated by a fixed angle with respect to left flange"
    tau = Torque(compatible_values(flange_a, flange_b))
    {
     RefBranch(flange_b, flange_a, deltaPhi, tau)
     }
end


function Spring(flange_a::Flange, flange_b::Flange, c::Real, phi_rel0::Signal)
    "Linear 1D rotational spring"
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    tau = Torque(val)
    {
     Branch(flange_b, flange_a, phi_rel, tau)
     tau - c .* (phi_rel - phi_rel0)
     }
end
Spring(flange_a::Flange, flange_b::Flange, c::Real) = Spring(flange_a, flange_b, c, 0.0)


function BranchHeatPort(n1::Flange, n2::Flange, hp::HeatPort,
                        model::Function, args...)
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    w_rel = AngularVelocity(val)
    tau = Torque(val)
    PowerLoss = Power(compatible_values(hp))
    {
     n1 - n2 - phi_rel
     w_rel - der(phi_rel)
     if length(value(hp)) > 1  # an array
         PowerLoss - w_rel .* tau
     else
         PowerLoss - sum(w_rel .* tau)
     end
     RefBranch(hp, -PowerLoss)
     Branch(n1, n, 0.0, tau)
     model(n, n2, args...)
     }
end


function Damper(flange_a::Flange, flange_b::Flange, d::Signal)
    "Linear 1D rotational damper"
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    tau = Torque(val)
    {
     Branch(flange_b, flange_a, phi_rel, tau)
     tau - d .* der(phi_rel)
     }
end
Damper(flange_a::Flange, flange_b::Flange, hp::HeatPort, d::Signal) =
    BranchHeatPort(flange_a, flange_b, hp, Damper, d)


function SpringDamper(flange_a::Flange, flange_b::Flange, c::Signal, d::Signal)
      "Linear 1D rotational spring and damper in parallel"
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    tau = Torque(val)
    {
     Spring(flange_a, flange_b, c)
     Damper(flange_a, flange_b, d)
     }
end
SpringDamper(flange_a::Flange, flange_b::Flange, hp::HeatPort, c::Signal, d::Signal) =
    BranchHeatPort(flange_a, flange_b, hp, SpringDamper, c, d)

    
function IdealGear(flange_a::Flange, flange_b::Flange, ratio::Real)
    val = compatible_values(flange_a, flange_b)
    tau_a = Torque(val)
    tau_b = Torque(val)
    {
     RefBranch(flange_a, tau_a)
     RefBranch(flange_b, tau_b)
     flange_a - ratio * flange_b
     ratio * tau_a + tau_b
     }
end



########################################
## Sensors
########################################

function SpeedSensor(flange::Flange, w::Signal)
    {
     w - der(flange)
     }
end


function AccSensor(flange::Flange, a::Signal)
    w = AngularVelocity(compatible_values(flange))
    {
     w - der(flange)
     a - der(w)
     }
end



########################################
## Sources
########################################


function SignalTorque(flange_a::Flange, flange_b::Flange, tau::Signal)
    {
     RefBranch(flange_a, -tau)
     RefBranch(flange_b, tau)
     }
end



########################################
## Examples
########################################

function ex_First()
    n1 = Angle("n1")
    n2 = Angle("n2")
    n3 = Angle("n3")
    n4 = Angle("n4")
    n5 = Angle("n5")
    n6 = Angle("n6")
    g = 0.0
    amplitude = 10.0
    freqHz = 5.0
    Jmotor = 0.1
    Jload = 2.0
    ratio = 10.0
    damping = 10.0
    {
     SignalTorque(n1, g, amplitude * sin(2pi * freqHz * MTime))
     Inertia(n1, n2, Jmotor)
     IdealGear(n2, n3, ratio)
     Inertia(n3, n4, 2.0)
     Damper(n4, g, damping)
     Spring(n4, n5, 1e4)
     Inertia(n5, n6, Jload)
    }
end

function sim_First()
    y = sim(ex_First())
    wplot(y, "First.pdf")
end
