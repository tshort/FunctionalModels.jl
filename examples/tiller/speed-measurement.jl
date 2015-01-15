
using Sims

using PyPlot, PyCall
@pyimport pandas
function pplot(x)
    pd = pandas.DataFrame(x.y[:,2:end], x.y[:,1], columns = x.colnames)
    pd[:plot]()
end

@doc """
# Examples from *Modelica by Example*

These examples are from the online book [Modelica by
Example](http://book.xogeny.com/) by Michael M. Tiller. Michael
explains modeling and simulations very well, and it's easy to compare
results to those online.

NOTE: These are not yet included in `Sims.Examples.*`.
"""

@doc """
Rotational example

http://book.xogeny.com/behavior/equations/mechanical/

![diagram](http://book.xogeny.com/_images/PlantWithPulseCounter.svg)

""" ->
function SecondOrderSystem(; phi1 = Unknown("Angle of inertia 1"),
                             phi2 = Unknown("Angle of inertia 2", 1.0),
                             omega1 = Unknown("Velocity of inertia 1"),
                             omega2 = Unknown("Velocity of inertia 2"),
                             J1 = 0.4, J2 = 1.0, k1 = 11.0, k2 = 5.0, d1 = 0.2, d2 = 1.0)
    phidiff = Unknown(value(phi2) - value(phi1))  # Used because der(phi2 - phi1) isn't supported
    @equations begin
        ## Equations for inertia 1
        phidiff = phi2 - phi1
        omega1 = der(phi1)
        J1*der(omega1) = k1*(phi2-phi1)+d1*der(phidiff)
        ## Equations for inertia 2
        omega2 = der(phi2)
        J2*der(omega2) = k1*(phi1-phi2)-d1*der(phidiff)-k2*phi2-d2*der(phi2)
    end
end
y = dasslsim(SecondOrderSystem(), tstop = 5.0)
pplot(y)



using Sims.Lib
function Inertia1(flange_a::Flange, J::Real)
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


##
## NOTE: broken - fails on initial conditions
##
function SecondOrderSystemUsingSimsLib(; #phi1 = Angle(label = "Angle of inertia 1"),
                                         phi2 = Angle(label = "Angle of inertia 2", value = 1.0, fixed = true),
                                         ## omega1 = Unknown("Velocity of inertia 1"),
                                         ## omega2 = Unknown("Velocity of inertia 2"),
                                         J1 = 0.4, J2 = 1.0, k1 = 11.0, k2 = 5.0, d1 = 0.2, d2 = 1.0)
    @equations begin
        ## omega1 = der(phi1)
        ## omega2 = der(phi2)
        Inertia1(phi1, J1)
        Inertia1(phi2, J2)
        SpringDamper(phi1, phi2, k1, d1)
    end
end
m = SecondOrderSystemUsingSimsLib()
e = elaborate(m)
s = create_simstate(e)
## y = dasslsim(SecondOrderSystemUsingSimsLib(), tstop = 5.0)

pplot(y)


using Reactive

@doc """
Rotational example with sample-and-hold measurement

http://book.xogeny.com/behavior/discrete/measuring/#sample-and-hold

Uses old-style Discrete's.

""" ->
function SampleAndHold()
    sample_time = 0.125
    omega1 = Unknown("omega1")
    omega1_measured = Discrete()
    omega1_measured_u = Unknown("omega1 measured")
    @equations begin
        Event(sin(MTime / sample_time * 2pi ),
              Equation[reinit(omega1_measured, omega1)])
        SecondOrderSystem(omega1 = omega1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(SampleAndHold(), tstop = 5.0)
pplot(y)

@doc """
Rotational example with sample-and-hold measurement

http://book.xogeny.com/behavior/discrete/measuring/#sample-and-hold

""" ->
function RSampleAndHold()
    sample_time = 0.125
    omega1 = Unknown("omega1")
    omega1_measured = RDiscrete(Reactive.Input(0.0))
    omega1_measured_u = Unknown("omega1 measured")
    @equations begin
        Event(sin(MTime / sample_time * 2pi ),
              Equation[push!(omega1_measured, omega1)])
        SecondOrderSystem(omega1 = omega1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(RSampleAndHold(), tstop = 5.0)
pplot(y)

@doc """
Rotational example with interval measurements

http://book.xogeny.com/behavior/discrete/measuring/#interval-measurement

""" ->
function RIntervalMeasure()
    teeth = 200
    tooth_angle = 2pi / teeth
    phi1 = Unknown("phi1")
    omega1_measured_u = Unknown("omega1 measured")
    omega1_measured = RDiscrete(Reactive.Input(0.0))
    next_phi = RDiscrete(Reactive.Input(value(phi1) + tooth_angle))
    prev_phi = RDiscrete(Reactive.Input(value(phi1) - tooth_angle))
    last_time = RDiscrete(Reactive.Input(0.0))
    @equations begin
        Event(ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              Equation[
                       push!(omega1_measured, tooth_angle / (MTime - last_time))
                       push!(next_phi, phi1 + tooth_angle)
                       push!(prev_phi, phi1 - tooth_angle)
                       push!(last_time, MTime)
                       ])
        SecondOrderSystem(phi1 = phi1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(RIntervalMeasure(), tstop = 5.0)
pplot(y)

@doc """
Rotational example with pulse counting

http://book.xogeny.com/behavior/discrete/measuring/#pulse-counting

""" ->
function RPulseCounting()
    sample_time = 0.125
    teeth = 200
    tooth_angle = 2pi / teeth
    phi1 = Unknown("phi1")
    omega1_measured_u = Unknown("omega1 measured")
    omega1_measured = RDiscrete(Reactive.Input(0.0))
    next_phi = RDiscrete(Reactive.Input(value(phi1) + tooth_angle))
    prev_phi = RDiscrete(Reactive.Input(value(phi1) - tooth_angle))
    count = RDiscrete(Reactive.Input(0))
    @equations begin
        Event(ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              Equation[
                       push!(next_phi, phi1 + tooth_angle)
                       push!(prev_phi, phi1 - tooth_angle)
                       push!(count, count + 1)
                       ])
        Event(sin(MTime / sample_time * 2pi),
              Equation[
                       push!(omega1_measured, count * tooth_angle / sample_time)
                       push!(count, 0)
                       ])
        SecondOrderSystem(phi1 = phi1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(RPulseCounting(), tstop = 5.0)
pplot(y)
