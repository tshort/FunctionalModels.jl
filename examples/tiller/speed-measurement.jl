
using Sims, Docile

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
""" -> type DocExTiller <: DocTag end

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

@doc """
Rotational example based on components in Sims.Lib

http://book.xogeny.com/behavior/equations/mechanical/

![diagram](http://book.xogeny.com/_images/PlantWithPulseCounter.svg)

""" ->
function SecondOrderSystemUsingSimsLib(; phi1 = Angle(label = "Angle of inertia 1", value = 0.0, fixed = true),
                                         phi2 = Angle(label = "Angle of inertia 2", value = 1.0, fixed = true),
                                         omega1 = Unknown(label = "Velocity of inertia 1", value = 0.0, fixed = true),
                                         omega2 = Unknown(label = "Velocity of inertia 2", value = 0.0, fixed = true),
                                         J1 = 0.4, J2 = 1.0, k1 = 11.0, k2 = 5.0, d1 = 0.2, d2 = 1.0)
    @equations begin
        omega1 = der(phi1)
        omega2 = der(phi2)
        Inertia(phi1, J1)
        Inertia(phi2, J2)
        SpringDamper(phi1, phi2, k1, d1)
        SpringDamper(phi2, 0.0, k2, d2)
    end
end
y = dasslsim(SecondOrderSystemUsingSimsLib(), tstop = 5.0)
pplot(y)



@doc """
Rotational example with sample-and-hold measurement

http://book.xogeny.com/behavior/discrete/measuring/#sample-and-hold

""" ->
function SampleAndHold()
    sample_time = 0.125
    omega1 = Unknown("omega1")
    omega1_measured = Discrete(0.0)
    omega1_measured_u = Unknown("omega1 measured")
    @equations begin
        Event(sin(MTime / sample_time * 2pi ),
              Equation[reinit(omega1_measured, omega1)])
        SecondOrderSystem(omega1 = omega1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(SampleAndHold(), tstop = 5.0)
## pplot(y)

@doc """
Rotational example with interval measurements

http://book.xogeny.com/behavior/discrete/measuring/#interval-measurement

""" ->
function IntervalMeasure()
    teeth = 200
    tooth_angle = 2pi / teeth
    phi1 = Unknown("phi1")
    omega1_measured_u = Unknown("omega1 measured")
    omega1_measured = Discrete(0.0)
    next_phi = Discrete(value(phi1) + tooth_angle)
    prev_phi = Discrete(value(phi1) - tooth_angle)
    last_time = Discrete(0.0)
    @equations begin
        Event(ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              Equation[
                       reinit(omega1_measured, tooth_angle / (MTime - last_time))
                       reinit(next_phi, phi1 + tooth_angle)
                       reinit(prev_phi, phi1 - tooth_angle)
                       reinit(last_time, MTime)
                       ])
        SecondOrderSystem(phi1 = phi1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(IntervalMeasure(), tstop = 5.0)
## pplot(y)

@doc """
Rotational example with pulse counting

http://book.xogeny.com/behavior/discrete/measuring/#pulse-counting

""" ->
function PulseCounting()
    sample_time = 0.125
    teeth = 200
    tooth_angle = 2pi / teeth
    phi1 = Unknown("phi1")
    omega1_measured_u = Unknown("omega1 measured")
    omega1_measured = Discrete(0.0)
    next_phi = Discrete(value(phi1) + tooth_angle)
    prev_phi = Discrete(value(phi1) - tooth_angle)
    count = Discrete(0)
    @equations begin
        Event(ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              Equation[
                       reinit(next_phi, phi1 + tooth_angle)
                       reinit(prev_phi, phi1 - tooth_angle)
                       reinit(count, count + 1)
                       ])
        Event(sin(MTime / sample_time * 2pi),
              Equation[
                       reinit(omega1_measured, count * tooth_angle / sample_time)
                       reinit(count, 0)
                       ])
        SecondOrderSystem(phi1 = phi1)
        omega1_measured_u = omega1_measured
    end
end
y = dasslsim(PulseCounting(), tstop = 5.0)
## pplot(y)
