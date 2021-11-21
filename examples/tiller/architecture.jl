
using Sims, Sims.Lib, IfElse

export FlatSystem, BaseSystem, IdealSensor, SampleHoldSensor,
       IdealActuator, LimitedActuator, ProportionalController,
       PIDController

"""
# Architectures

These examples from the following sections from the [Architectures
chapter](http://book.xogeny.com/components/architectures/):

* [Sensor Comparison](http://book.xogeny.com/components/architectures/sensor_comparison/)
* [Architecture Driven Approach](http://book.xogeny.com/components/architectures/sensor_comparison_ad/)

In [Modelica by Example](http://book.xogeny.com/), Tiller shows how
components can be connected together in a reusable fashion. This is
also possible in Sims.jl. Because Sims.jl is functional, the approach
is different than Modelica's object-oriented approach. The functional
approach is generally cleaner.
"""
@comment 


"""
Sensor comparison for a rotational example

http://book.xogeny.com/components/architectures/sensor_comparison/

![diagram](http://book.xogeny.com/_images/FlatSystem.svg)

"""
function FlatSystem(phi1 = Angle(),
                    phi2 = Angle())
    desiredspeed = AngularVelocity("desired speed")
    d = Variable()
    omega2 = AngularVelocity("shaft speed")
    [
        der(phi2) ~ omega2
        d ~ desiredspeed
        :in1 => Inertia(phi1, 0.1) # left side
        :in2 => Inertia(phi2, 0.3) # right side
        :sd  => SpringDamper(phi1, phi2, 100.0, 3.0)
        :d   => Damper(phi2, 0.0, 4.0)
        # BooleanPulse(d)
        :st  => SignalTorque(phi1, 0.0, 20 * (IfElse.ifelse(d, 1.0, 0.0) - omega2))
    ]
end

## y = dasslsim(FlatSystem(), tstop = 5.0)
## plot(y)


"""
Basic plant for the example
"""
function BasicPlant(phi1 = Angle(), phi2 = Angle())
    [
        :in1 => Inertia(phi1, 0.1) # left side
        :in2 => Inertia(phi2, 0.3) # right side
        :sd  => SpringDamper(phi1, phi2, 100.0, 3.0)
        :d   => Damper(phi2, 0.0, 4.0)
    ]
end

"""
Ideal sensor for angular velocity
"""
function IdealSensor(phi, signal)
    [
        der(phi) ~ signal
    ]
end

"""
Sample-and-hold velocity sensor
"""
function SampleHoldSensor(phi, signal, sampletime)
    omega_measured = Variable(0.0)
    omega = AngularVelocity()
    [
        der(phi) ~ omega
        Event(sin(t / sampletime * 2pi ) ~ 0.0,
              omega_measured ~ omega)
        signal ~ omega_measured
    end
end
## Create a closure to handle samplerate adjustments
SampleHoldSensor(; sampletime = 1.0) = (phi, signal) -> SampleHoldSensor(phi, signal, sampletime)

"""
Ideal actuator
"""
function IdealActuator(phi, tau)
    [
        SignalTorque(phi, 0.0, tau)
    ]
end

"""
Actuator with lag and saturation
"""
function LimitedActuator(phi, tau, delayTime, uMax)
    clippedtau = Unknown()
    delayedtau = Unknown()
    [
        ## delayedtau = delay(tau, delayTime)   # broken (#36)
        ## Limiter(delayedtau, clippedtau, uMax)
        Limiter(tau, clippedtau, uMax)
        SignalTorque(phi, 0.0, tau)
    ]
end
LimitedActuator(; delayTime = 0.0, uMax = Inf) = (phi, tau) -> LimitedActuator(phi, tau, delayTime, uMax)

"""
Proportional controller
"""
function ProportionalController(setpoint, measured, command, k)
    [
        command ~ k * (setpoint - measured)
    ]
end
ProportionalController(; k = 20.0) = (setpoint, measured, command) -> ProportionalController(setpoint, measured, command, k)
    
"""
PID controller
"""
function PIDController(setpoint, measured, command, k, Ti, Td, yMax)
    [
        LimPID(setpoint, measured, command, k=k, Ti=Ti, Td=Td, yMax=yMax, yMin = -yMax)
    ]
end
PIDController(; k = 1.0, Ti = 1.0, Td = 1.0, yMax = Inf) = (setpoint, measured, command) -> PIDController(setpoint, measured, command, k, Ti, Td, yMax)


"""
Base system with replaceable components

This is the same example as [FlatSystem](#flatsystem), but `Plant`,
`Sensor`, `Actuator`, and `Controller` can all be changed by passing
in optional keyword arguments.

Here is an example where several components are modified. The
replacement components like `SampleHoldSensor` are based on closures
(functions that return functions).

```julia
Variant2  = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                       Controller = PIDController(yMax=15, Td=0.1, k=20, Ti=0.1),
                       Actuator = LimitedActuator(delayTime=0.005, uMax=10));
```
"""
function BaseSystem(; Plant = BasicPlant,
                      Sensor = IdealSensor,
                      Actuator = IdealActuator,
                      Controller = ProportionalController(k = 20.0))
    @named phi1 = Angle()
    @named phi2 = Angle()
    @named omega2 = AngularVelocity()
    @named setpoint = Unknown()
    @named measured = Unknown()
    d = Discrete(true)
    @named tau = Unknown()
    [
        der(phi2) ~ omega2
        BooleanPulse(d)
        setpoint ~ IfElse.ifelse(d, 1.0, 0.0)
        :plant      => Plant(phi1, phi2)
        :sensor     => Sensor(phi2, measured)
        :controller => Controller(setpoint, measured, tau)
        :actuator   => Actuator(phi1, tau)
    ]
end

## bs = dasslsim(BaseSystem(), tstop = 5.0)
## plot(bs)

"""
BaseSystem variant with sample-hold sensing
"""
Variant1 = () -> BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01));

## v1 = dasslsim(Variant1(), tstop = 5.0)
## plot(v1)

Variant1a = () -> BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.036));


"""
BaseSystem variant with PID control along with a realistic actuator
"""
Variant2() = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                        Controller = PIDController(yMax=15, Td=0.1, k=20, Ti=0.1),
                        Actuator = LimitedActuator(delayTime=0.005, uMax=10));



"""
BaseSystem variant with a tuned PID control along with a realistic actuator
"""
Variant2a() = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                         Controller = PIDController(yMax=50, Td=0.01, k=4, Ti=0.07),
                         Actuator = LimitedActuator(delayTime=0.005, uMax=50));

