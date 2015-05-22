
using Sims, Sims.Lib, Docile

export FlatSystem, BaseSystem, IdealSensor, SampleHoldSensor,
       IdealActuator, LimitedActuator, ProportionalController,
       PIDController

@comment """
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


@doc+ """
Sensor comparison for a rotational example

http://book.xogeny.com/components/architectures/sensor_comparison/

![diagram](http://book.xogeny.com/_images/FlatSystem.svg)

""" ->
function FlatSystem(phi1 = Angle(),
                    phi2 = Angle())
    desiredspeed = AngularVelocity("desired speed")
    d = Discrete(true)
    omega2 = AngularVelocity("shaft speed")
    @equations begin
        omega2 = der(phi2)
        d = desiredspeed
        Inertia(phi1, 0.1) # left side
        Inertia(phi2, 0.3) # right side
        SpringDamper(phi1, phi2, 100.0, 3.0)
        Damper(phi2, 0.0, 4.0)
        BooleanPulse(d)
        SignalTorque(phi1, 0.0, 20 * (ifelse(d, 1.0, 0.0) - omega2))
    end
end

## y = dasslsim(FlatSystem(), tstop = 5.0)
## wplot(y)


@doc+ """
Basic plant for the example
""" ->
function BasicPlant(phi1 = Angle(), phi2 = Angle())
    @equations begin
        Inertia(phi1, 0.1) # left side
        Inertia(phi2, 0.3) # right side
        SpringDamper(phi1, phi2, 100.0, 3.0)
        Damper(phi2, 0.0, 4.0)
    end
end

@doc+ """
Ideal sensor for angular velocity
""" ->
function IdealSensor(phi, signal)
    @equations begin
        signal = der(phi)
    end
end

@doc+ """
Sample-and-hold velocity sensor
""" ->
function SampleHoldSensor(phi, signal, sampletime)
    omega_measured = Discrete(0.0)
    omega = AngularVelocity()
    @equations begin
        omega = der(phi)
        Event(sin(MTime / sampletime * 2pi ),
              reinit(omega_measured, omega))
        signal = omega_measured
    end
end
## Create a closure to handle samplerate adjustments
SampleHoldSensor(; sampletime = 1.0) = (phi, signal) -> SampleHoldSensor(phi, signal, sampletime)

@doc+ """
Ideal actuator
""" ->
function IdealActuator(phi, tau)
    @equations begin
        SignalTorque(phi, 0.0, tau)
    end
end

@doc+ """
Actuator with lag and saturation
""" ->
function LimitedActuator(phi, tau, delayTime, uMax)
    clippedtau = Unknown()
    delayedtau = Unknown()
    @equations begin
        ## delayedtau = delay(tau, delayTime)   # broken (#36)
        ## Limiter(delayedtau, clippedtau, uMax)
        Limiter(tau, clippedtau, uMax)
        SignalTorque(phi, 0.0, tau)
    end
end
LimitedActuator(; delayTime = 0.0, uMax = Inf) = (phi, tau) -> LimitedActuator(phi, tau, delayTime, uMax)

@doc+ """
Proportional controller
""" ->
function ProportionalController(setpoint, measured, command, k)
    @equations begin
        command = k * (setpoint - measured)
    end
end
ProportionalController(; k = 20.0) = (setpoint, measured, command) -> ProportionalController(setpoint, measured, command, k)
    
@doc+ """
PID controller
""" ->
function PIDController(setpoint, measured, command, k, Ti, Td, yMax)
    @equations begin
        LimPID(setpoint, measured, command, k=k, Ti=Ti, Td=Td, yMax=yMax, yMin = -yMax)
    end
end
PIDController(; k = 1.0, Ti = 1.0, Td = 1.0, yMax = Inf) = (setpoint, measured, command) -> PIDController(setpoint, measured, command, k, Ti, Td, yMax)


@doc+ """
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
""" ->
function BaseSystem(; Plant = BasicPlant,
                      Sensor = IdealSensor,
                      Actuator = IdealActuator,
                      Controller = ProportionalController(k = 20.0))
    phi1 = Angle()
    phi2 = Angle()
    omega2 = AngularVelocity("shaft speed")
    setpoint = Unknown("desired speed")
    measured = Unknown("measured speed")
    d = Discrete(true)
    tau = Unknown("tau")
    @equations begin
        omega2 = der(phi2)
        BooleanPulse(d)
        setpoint = ifelse(d, 1.0, 0.0)
        Plant(phi1, phi2)
        Sensor(phi2, measured)
        Controller(setpoint, measured, tau)
        Actuator(phi1, tau)
    end
end

## bs = dasslsim(BaseSystem(), tstop = 5.0)
## wplot(bs)

"""
BaseSystem variant with sample-hold sensing
"""
Variant1 = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01));

## v1 = dasslsim(Variant1, tstop = 5.0)
## wplot(v1)

Variant1a = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.036));

## v1a = dasslsim(Variant1a, tstop = 5.0)
## wplot(v1a)


"""
BaseSystem variant with PID control along with a realistic actuator
"""
Variant2  = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                       Controller = PIDController(yMax=15, Td=0.1, k=20, Ti=0.1),
                       Actuator = LimitedActuator(delayTime=0.005, uMax=10));

## v2 = dasslsim(Variant2, tstop = 5.0)
## wplot(v2)


"""
BaseSystem variant with a tuned PID control along with a realistic actuator
"""
Variant2a  = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),
                        Controller = PIDController(yMax=50, Td=0.01, k=4, Ti=0.07),
                        Actuator = LimitedActuator(delayTime=0.005, uMax=50));

## v2a = dasslsim(Variant2a, tstop = 5.0)
## wplot(v2a)
