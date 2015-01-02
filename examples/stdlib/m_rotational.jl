using Sims


########################################
## Rotational mechanical examples
##
## These attempt to mimic Modelica.Mechanics.Rotational.Examples
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
    Equation[
        SignalTorque(n1, g, amplitude * sin(2pi * freqHz * MTime))
        Inertia(n1, n2, Jmotor)
        IdealGear(n2, n3, ratio)
        Inertia(n3, n4, 2.0)
        Damper(n4, g, damping)
        Spring(n4, n5, 1e4)
        Inertia(n5, n6, Jload)
    ]
end

function sim_First()
    y = sim(ex_First())
    wplot(y, "First.pdf")
end
