
########################################
## Rotational Mechanical Models       ##
########################################

@comment """
# Rotational mechanics

Library to model 1-dimensional, rotational mechanical systems

Rotational provides 1-dimensional, rotational mechanical components to
model in a convenient way drive trains with frictional losses.

These components are modeled after the Modelica.Mechanics.Rotational
library.

NOTE: these need more testing.
"""


@comment """
## Basic models
"""

#
# I'm not sure the mechanical models are right.
# There may be sign errors.
# 

"""
1D-rotational component with inertia

Rotational component with inertia at a flange (or between two rigidly
connected flanges).

```julia
Inertia(flange_a::Flange, J::Real)
Inertia(flange_a::Flange, flange_b::Flange, J::Real)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `J::Real` : Moment of inertia [kg.m^2]

"""
function Inertia(flange_a::Flange, J::Real)
    val = compatible_values(flange_a)
    tau_a = Torque(val)
    w = AngularVelocity(val)
    a = AngularAcceleration(val)
    @equations begin
        RefBranch(flange_a, tau_a)
        w = der(flange_a)
        a = der(w)
        tau_a = J .* a
    end
end
function Inertia(flange_a::Flange, flange_b::Flange, J::Real)
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


"""
1-dim. rotational rigid component without inertia, where right flange is rotated by a fixed angle with respect to left flange

Rotational component with two rigidly connected flanges without
inertia. The right flange is rotated by the fixed angle "deltaPhi"
with respect to the left flange.

```julia
Disc(flange_a::Flange, flange_b::Flange, deltaPhi)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `deltaPhi::Signal` : rotation of left flange with respect to right flange (= flange_b - flange_a) [rad]

"""
function Disc(flange_a::Flange, flange_b::Flange, deltaPhi = 0.0)
    tau = Torque(compatible_values(flange_a, flange_b))
    @equations begin
        RefBranch(flange_b, flange_a, deltaPhi, tau)
    end
end


"""
Linear 1D rotational spring

A linear 1D rotational spring. The component can be connected either
between two inertias/gears to describe the shaft elasticity, or
between a inertia/gear and the housing (component Fixed), to describe
a coupling of the element with the housing via a spring.

```julia
Spring(flange_a::Flange, flange_b::Flange, c::Real, phi_rel0 = 0.0)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `c`: spring constant [N.m/rad]
* `phi_rel0` : unstretched spring angle [rad]

"""
function Spring(flange_a::Flange, flange_b::Flange, c::Real, phi_rel0::Signal = 0.0)
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(value(flange_b) - value(flange_a))
    tau = Torque(val)
    @equations begin
        Branch(flange_b, flange_a, phi_rel, tau)
        tau = c .* (phi_rel - phi_rel0)
    end
end


"""
Linear 1D rotational damper

Linear, velocity dependent damper element. It can be either connected
between an inertia or gear and the housing (component Fixed), or
between two inertia/gear elements.

```julia
Damper(flange_a::Flange, flange_b::Flange, d::Signal)
Damper(flange_a::Flange, flange_b::Flange, hp::HeatPort, d::Signal)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `hp::HeatPort` : heat port [K]
* `d`: 	damping constant [N.m.s/rad]

"""
function Damper(flange_a::Flange, flange_b::Flange, d::Signal)
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(value(flange_b) - value(flange_a))
    tau = Torque(val)
    @equations begin
        Branch(flange_b, flange_a, phi_rel, tau)
        tau = d .* der(phi_rel)
    end
end
Damper(flange_a::Flange, flange_b::Flange, hp::HeatPort, d::Signal) =
    MBranchHeatPort(flange_a, flange_b, hp, Damper, d)


"""
Linear 1D rotational spring and damper in parallel

A spring and damper element connected in parallel. The component can
be connected either between two inertias/gears to describe the shaft
elasticity and damping, or between an inertia/gear and the housing
(component Fixed), to describe a coupling of the element with the
housing via a spring/damper.

```julia
SpringDamper(flange_a::Flange, flange_b::Flange, c::Signal, d::Signal)
SpringDamper(flange_a::Flange, flange_b::Flange, hp::HeatPort, c::Signal, d::Signal)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `hp::HeatPort` : heat port [K]
* `c`: 	spring constant [N.m/rad]
* `d`: 	damping constant [N.m.s/rad]

"""
function SpringDamper(flange_a::Flange, flange_b::Flange, c::Signal, d::Signal)
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(value(flange_b) - value(flange_a))
    tau = Torque(val)
    @equations begin
        Spring(flange_a, flange_b, c)
        Damper(flange_a, flange_b, d)
    end
end
SpringDamper(flange_a::Flange, flange_b::Flange, hp::HeatPort, c::Signal, d::Signal) =
    MBranchHeatPort(flange_a, flange_b, hp, SpringDamper, c, d)



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
    
"""
Ideal gear without inertia

This element characterices any type of gear box which is fixed in the
ground and which has one driving shaft and one driven shaft. The gear
is ideal, i.e., it does not have inertia, elasticity, damping or
backlash. If these effects have to be considered, the gear has to be
connected to other elements in an appropriate way.

```julia
IdealGear(flange_a::Flange, flange_b::Flange, ratio)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `ratio` : transmission ratio (flange_a / flange_b)

"""
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
## Misc
########################################
@comment """
## Miscellaneous
"""

"""
Wrap argument `model` with a heat port that captures the power
generated by the device. This is vectorizable.

```julia
MBranchHeatPort(flange_a::Flange, flange_b::Flange, hp::HeatPort,
                model::Function, args...)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `hp::HeatPort` : Heat port [K]                
* `model::Function` : Model to wrap
* `args...` : Arguments passed to `model`  

"""
function MBranchHeatPort(flange_a::Flange, flange_b::Flange, hp::HeatPort,
                         model::Function, args...)
    val = compatible_values(flange_a, flange_b)
    phi_rel = Angle(value(flange_b) - value(flange_a))
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



########################################
## Sensors
########################################
@comment """
## Sensors
"""

"""
Ideal sensor to measure the absolute flange angular velocity

Measures the absolute angular velocity w of a flange in an ideal way
and provides the result as output signal w.

```julia
SpeedSensor(flange::Flange, w::Signal)
```

### Arguments

* `flange::Flange` : left flange of shaft [rad]
* `w::Signal`: 	absolute angular velocity of the flange [rad/sec]

"""
function SpeedSensor(flange::Flange, w::Signal)
    @equations begin
        w = der(flange)
    end
end


"""
Ideal sensor to measure the absolute flange angular acceleration

Measures the absolute angular velocity a of a flange in an ideal way
and provides the result as output signal a.

```julia
SpeedSensor(flange::Flange, a::Signal)
```

### Arguments

* `flange::Flange` : left flange of shaft [rad]
* `a::Signal`: 	absolute angular acceleration of the flange [rad/sec^2]

"""
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
@comment """
## Sources
"""


"""
Input signal acting as external torque on a flange

The input signal tau defines an external torque in [Nm] which acts
(with negative sign) at a flange connector, i.e., the component
connected to this flange is driven by torque tau.

```julia
SignalTorque(flange_a::Flange, flange_b::Flange, tau)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `tau` : Accelerating torque acting at flange_a relative to flange_b
  (normally a support); a positive value accelerates flange_a

"""
function SignalTorque(flange_a::Flange, flange_b::Flange, tau)
    @equations begin
        RefBranch(flange_a, -tau)
        RefBranch(flange_b, tau)
    end
end

"""
Quadratic dependency of torque versus speed

Model of torque, quadratic dependent on angular velocity of flange.
Parameter TorqueDirection chooses whether direction of torque is the
same in both directions of rotation or not.

```julia
QuadraticSpeedDependentTorque(flange_a::Flange, flange_b::Flange,
                              tau_nominal::Signal, TorqueDirection::Bool, w_nominal::Signal)
```

### Arguments

* `flange_a::Flange` : left flange of shaft [rad]
* `flange_b::Flange` : right flange of shaft [rad]
* `tau_nominal::Signal` : nominal torque (if negative, torque is acting as a load) [N.m]
* `TorqueDirection::Bool` : same direction of torque in both directions of rotation
* `AngularVelocity::Signal` : nominal speed [rad/sec]

"""
function QuadraticSpeedDependentTorque(flange_a::Flange, flange_b::Flange,
                                       tau_nominal::Signal, TorqueDirection::Bool, w_nominal::Signal)
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
