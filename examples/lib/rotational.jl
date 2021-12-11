const t = Sims.t

########################################
## Rotational mechanical examples
##
## These attempt to mimic Modelica.Mechanics.Rotational.Examples
########################################

export First

"""
# Rotational
"""
@comment 

"""
First example: simple drive train

The drive train consists of a motor inertia which is driven by a
sine-wave motor torque. Via a gearbox the rotational energy is
transmitted to a load inertia. Elasticity in the gearbox is modeled by
a spring element. A linear damper is used to model the damping in the
gearbox bearing.

Note, that a force component (like the damper of this example) which
is acting between a shaft and the housing has to be fixed in the
housing on one side via component Fixed.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Mechanics.Rotational.Examples.FirstD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Mechanics_Rotational_Examples.html#Modelica.Mechanics.Rotational.Examples.First)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Mechanics_Rotational_Examples.html#Modelica.Mechanics.Rotational.Examples.First)
"""
function First()
    @variables n1(t) n2(t) n3(t) n4(t) n5(t) n6(t)
    g = 0.0
    amplitude = 10.0
    freqHz = 5.0
    Jmotor = 0.1
    Jload = 2.0
    ratio = 10.0
    damping = 10.0
    [
        :st  => SignalTorque(n1, g, tau = amplitude * sin(2pi * freqHz * t))
        :in1 => Inertia(n1, n2, J = Jmotor)
        :ig  => IdealGear(n2, n3, ratio = ratio)
        :in2 => Inertia(n3, n4, J = 2.0)
        :d   => Damper(n4, g, d = damping)
        :s   => Spring(n4, n5, c = 1e4)
        :in3 => Inertia(n5, n6, J = Jload)
    ]
end

