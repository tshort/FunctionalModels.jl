
using Sims, Sims.Lib
const D = Sims.D
const t = Sims.t

export SecondOrderSystem, SecondOrderSystemUsingSimsLib, SampleAndHold, IntervalMeasure, PulseCounting

"""
# Examples of speed measurement

These examples show several ways of measuring speed on a rotational
system. They are based on Michael's section on [Speed
Measurement](http://mbe.modelica.university/behavior/discrete/measuring/). These
examples include use of Variable variables and Events.

The system is based on the following plant:

![diagram](http://mbe.modelica.university/static/_images/PlantWithPulseCounter.svg)

"""
@comment 


"""
Rotational example

http://mbe.modelica.university/behavior/equations/mechanical/

"""
function SecondOrderSystem(; phi1 = Unknown(name = :phi1),
                             phi2 = Unknown(1.0, name = :phi2),
                             omega1 = Unknown(name = :omega1),
                             omega2 = Unknown(name = :omega2),
                             J1 = 0.4, J2 = 1.0, c1 = 11.0, c2 = 5.0, d1 = 0.2, d2 = 1.0)
    [
        ## Equations for inertia 1
        D(phi1) ~ omega1
        D(omega1) ~ (c1*(phi2 - phi1) + d1*(omega2 - omega1)) / J1
        ## Equations for inertia 2
        D(phi2) ~ omega2
        D(omega2) ~ (c1*(phi1 - phi2) + d1*(omega1 - omega2) - c2*phi2 - d2*omega2) / J2
    ]
end

# function SecondOrderSystem(; phi1 = Unknown(name = :phi1),
#                              phi2 = Unknown(1.0, name = :phi2),
#                              omega1 = Unknown(name = :omega1),
#                              omega2 = Unknown(name = :omega2),
#                              J1 = 0.4, J2 = 1.0, k1 = 11.0, k2 = 5.0, d1 = 0.2, d2 = 1.0)
#     # @named phidiff = Unknown(default_value(phi2) - default_value(phi1))  # Used because der(phi2 - phi1) isn't supported
#     @named phidiff = Unknown(default_value(phi2) - default_value(phi1))  # Used because der(phi2 - phi1) isn't supported
#     [
#         ## Equations for inertia 1
#         phidiff ~ phi2 - phi1
#         der(phi1) ~ omega1
#         J1*der(omega1) - d1*der(phidiff) ~ k1*(phi2-phi1)
#         ## Equations for inertia 2
#         der(phi2) ~ omega2
#         J2*der(omega2) + d1*der(phidiff) ~ -d2*omega2 + k1*(phi1-phi2) - k2*phi2
#     ]
# end


"""
Rotational example based on components in Sims.Lib

http://mbe.modelica.university/behavior/equations/mechanical/

![diagram](http://mbe.modelica.university/static/_images/PlantWithPulseCounter.svg)

"""
function SecondOrderSystemUsingSimsLib(; phi1 = Angle(0.0, name = :phi1),
                                         phi2 = Angle(1.0, name = :phi2),
                                         omega1 = Unknown(0.0, name = :omega1),
                                         omega2 = Unknown(0.0, name = :omega2),
                                         J1 = 0.4, J2 = 1.0, c1 = 11.0, c2 = 5.0, d1 = 0.2, d2 = 1.0)
    [
        der(phi1) ~ omega1
        der(phi2) ~ omega2
        :in1 => Inertia(phi1, J = J1)
        :in2 => Inertia(phi2, J = J2)
        :sd1 => SpringDamper(phi1, phi2, c = c1, d = d1)
        :sd2 => SpringDamper(phi2, 0.0, c = c2, d = d2)
    ]
end



"""
Rotational example with sample-and-hold measurement

http://mbe.modelica.university/behavior/discrete/measuring/#sample-and-hold

"""
function SampleAndHold()
    sample_time = 0.125
    @named omega1 = Unknown()
    @named omega1_measured = Unknown()
    [
        SecondOrderSystem(omega1 = omega1)
        Event(sin(Sims.t / sample_time * 2pi) ~ 0.0,
              omega1_measured ~ omega1)
        der(omega1_measured) ~ 0.0
    ]
end

"""
Rotational example with interval measurements

http://mbe.modelica.university/behavior/discrete/measuring/#interval-measurement

"""
function IntervalMeasure()
    teeth = 200
    tooth_angle = 2pi / teeth
    @named phi1 = Unknown()
    @named omega1_measured_u = Unknown()
    @named omega1_measured = Variable(0.0)
    @named next_phi = Variable(default_value(phi1) + tooth_angle)
    @named prev_phi = Variable(default_value(phi1) - tooth_angle)
    @named last_time = Variable(0.0)
    [
        Event(IfElse.ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1),
              [
               omega1_measured ~ tooth_angle / (t - last_time)
               next_phi ~ phi1 + tooth_angle
               prev_phi ~ phi1 - tooth_angle
               last_time ~ Sims.t
              ])
        :sos => SecondOrderSystem(phi1 = phi1)
        omega1_measured_u ~ omega1_measured
    ]
end

"""
Rotational example with pulse counting

http://mbe.modelica.university/behavior/discrete/measuring/#pulse-counting

"""
function PulseCounting()
    sample_time = 0.125
    teeth = 200
    tooth_angle = 2pi / teeth
    @named phi1 = Unknown()
    @named omega1_measured_u = Unknown()
    @named omega1_measured = Variable(0.0)
    @named next_phi = Variable(default_value(phi1) + tooth_angle)
    @named prev_phi = Variable(default_value(phi1) - tooth_angle)
    @named count = Variable(0)
    [
        Event(IfElse.ifelse(phi1 > next_phi, phi1 - next_phi, prev_phi - phi1) ~ 0.0,
              [
               next_phi ~ phi1 + tooth_angle
               prev_phi ~ phi1 - tooth_angle
               count ~ count + 1
              ])
        Event(sin(t / sample_time * 2pi) ~ 0.0,
              [
               omega1_measured ~ count * tooth_angle / sample_time
               count ~ 0
              ])
        :sos => SecondOrderSystem(phi1 = phi1)
        omega1_measured_u ~ omega1_measured
    ]
end
