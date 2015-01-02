
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
    @equations begin
        RefBranch(flange_a, tau_a)
        RefBranch(flange_b, tau_b)
        flange_b = flange_a    # the angles are both equal
        w = der(flange_a)
        a = der(w)
        tau_a + tau_b = J .* a
    end
end


function Disc(flange_a::Flange, flange_b::Flange, deltaPhi::Signal)
    "1-dim. rotational rigid component without inertia, where right flange is rotated by a fixed angle with respect to left flange"
    tau = Torque(compatible_values(flange_a, flange_b))
    @equations begin
        RefBranch(flange_b, flange_a, deltaPhi, tau)
    end
end


function Spring(flange_a::Flange, flange_b::Flange, c::Real, phi_rel0::Signal)
    "Linear 1D rotational spring"
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    tau = Torque(val)
    @equations begin
        Branch(flange_b, flange_a, phi_rel, tau)
        tau = c .* (phi_rel - phi_rel0)
    end
end
Spring(flange_a::Flange, flange_b::Flange, c::Real) = Spring(flange_a, flange_b, c, 0.0)


function BranchHeatPort(n1::Flange, n2::Flange, hp::HeatPort,
                        model::Function, args...)
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    w_rel = AngularVelocity(val)
    tau = Torque(val)
    PowerLoss = Power(compatible_values(hp))
    @equations begin
        n1 - n2 = phi_rel
        w_rel = der(phi_rel)
        if length(value(hp)) > 1  # an array
            PowerLoss = w_rel .* tau
        else
            PowerLoss = sum(w_rel .* tau)
        end
        RefBranch(hp, -PowerLoss)
        Branch(n1, n, 0.0, tau)
        model(n, n2, args...)
    end
end


function Damper(flange_a::Flange, flange_b::Flange, d::Signal)
    "Linear 1D rotational damper"
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    tau = Torque(val)
    @equations begin
        Branch(flange_b, flange_a, phi_rel, tau)
        tau = d .* der(phi_rel)
    end
end
Damper(flange_a::Flange, flange_b::Flange, hp::HeatPort, d::Signal) =
    BranchHeatPort(flange_a, flange_b, hp, Damper, d)


function SpringDamper(flange_a::Flange, flange_b::Flange, c::Signal, d::Signal)
      "Linear 1D rotational spring and damper in parallel"
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(val)
    tau = Torque(val)
    @equations begin
        Spring(flange_a, flange_b, c)
        Damper(flange_a, flange_b, d)
    end
end
SpringDamper(flange_a::Flange, flange_b::Flange, hp::HeatPort, c::Signal, d::Signal) =
    BranchHeatPort(flange_a, flange_b, hp, SpringDamper, c, d)

function Brake(flange_a::Flange, flange_b::Flange, support::Flange, f_normalized::Signal,
               mue_pos, peak, cgeo, fn_max, w_small)
    ## NOT WORKING!!!
    "Brake based on Coulomb friction"
    val = compatible_values(flange_a, flange_b)
    phi = Angle(val)   # Angle between shaft flanges and support
    tau = Torque(val)  # Brake friction torque
    tau_a = Torque(val)
    tau_b = Torque(val)
    w = AngularVelocity(val)  # Absolute angular velocity of flange_a and flange_b
    a = AngularAcceleration(val)  # Absolute angular acceleration of flange_a and flange_b
    mue0 = tempInterpol1(0, mue_pos, 2)
    free = Discrete(fill(true, length(vals)))
    locked = Discrete(fill(false, length(vals)))
    startForward = Discrete(fill(false, length(vals)))
    startBackward = Discrete(fill(false, length(vals)))
    const UnknownMode=3   # Value of mode is not known
    const Free=2      # Element is not active
    const Forward=1   # w_rel > 0 (forward sliding)
    const Stuck=0     # w_rel = 0 (forward sliding, locked or backward sliding)
    const Backward=-1 # w_rel < 0 (backward sliding)
    mode = Discrete(fill(UnknownMode, length(vals)))
    @equations begin
        RefBranch(flange_a, tau_a)
        RefBranch(flange_b, tau_b)
        
        phi - flange_a + support
        flange_b - flange_a
   
        # Angular velocity and angular acceleration of flanges flange_a and flange_b
        w = der(phi)
        a = der(w)
        w_relfric = w
        a_relfric = a

        # Friction torque, normal force and friction torque for w_rel=0
        tau_a + tau_b = tau
        fn = fn_max .* f_normalized
        tau0 = mue0 .* cgeo .* fn
        tau0_max = peak .* tau0
        BoolEvent(free, fn)
        Event(w,
              Equation[
                  reinit(startForward,
                         pre(mode) == Stuck & (sa > tau0_max/unitTorque | pre(startForward)) &
                         sa > tau0/unitTorque | pre(mode) == Backward & w > w_small | initial() & (w > 0))
                  reinit(startBackward,
                         pre(mode) == Stuck & (sa < -tau0_max/unitTorque | pre(startBackward) &
                         sa < -tau0/unitTorque) | pre(mode) == Forward & w < -w_small | initial() & (w < 0))
                  reinit(locked,
                         !free && !(pre(mode) == Forward | startForward | pre(mode) == Backward | startBackward))
                  # finite state machine to determine configuration
                  reinit(mode,
                         ifelse(free, Free,
                         ifelse((pre(mode) == Forward  | pre(mode) == Free | startForward) & w > 0, Forward,
                         ifelse((pre(mode) == Backward | pre(mode) == Free | startBackward) & w < 0, Backward,
                         Stuck))))
              ])
   
        # Friction torque
        tau = ifelse(locked,
                     sa*unitTorque,
              ifelse(free,
                     0.0,
                     cgeo .* fn .* (ifelse(startForward,
                                            tempInterpol1( w, mue_pos, 2),
                                    ifelse(startBackward,
                                           -tempInterpol1(-w, mue_pos, 2),
                                    ifelse(pre(mode) == Forward,
                                            tempInterpol1( w, mue_pos, 2),
                                           -tempInterpol1(-w, mue_pos, 2)))))))
   
        a = unitAngularAcceleration .*
            ifelse(locked,
                   0.0,
            ifelse(free,
                   sa,
            ifelse(startForward,
                   sa - tau0_max ./ unitTorque,
            ifelse(startBackward,
                   sa + tau0_max ./ unitTorque,
            ifelse(pre(mode) == Forward,
                   sa - tau0_max ./ unitTorque,
                   sa + tau0_max ./ unitTorque)))))
    end
end
    
function IdealGear(flange_a::Flange, flange_b::Flange, ratio::Real)
    val = compatible_values(flange_a, flange_b)
    tau_a = Torque(val)
    tau_b = Torque(val)
    @equations begin
        RefBranch(flange_a, tau_a)
        RefBranch(flange_b, tau_b)
        flange_a = ratio * flange_b
        ratio * tau_a + tau_b
    end
end



########################################
## Sensors
########################################

function SpeedSensor(flange::Flange, w::Signal)
    @equations begin
        w = der(flange)
    end
end


function AccSensor(flange::Flange, a::Signal)
    w = AngularVelocity(compatible_values(flange))
    @equations begin
        w = der(flange)
        a = der(w)
    end
end



########################################
## Sources
########################################


function SignalTorque(flange_a::Flange, flange_b::Flange, tau::Signal)
    @equations begin
        RefBranch(flange_a, -tau)
        RefBranch(flange_b, tau)
    end
end

function QuadraticSpeedDependentTorque(flange_a::Flange, flange_b::Flange,
                                       tau_nominal::Signal, TorqueDirection::Bool, w_nominal::Signal)
    "Quadratic dependency of torque versus speed"
    val = compatible_values(flange_a, flange_b)
    tau = Torque(val)
    phi = Angle(val)
    w = AngularVelocity(val)
    @equations begin
        Branch(flange_b, flange_a, phi, tau)
        w = der(phi)
        tau = ifelse(TorqueDirection,
                     tau_nominal*(w/w_nominal)^2,
                     tau_nominal*ifelse(w >= 0, (w/w_nominal)^2, -(w/w_nominal)^2))
    end
end 
