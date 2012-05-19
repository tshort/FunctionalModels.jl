

load("../src/sims.jl")
load("../library/mechanical.jl")


#
# I'm not sure this mechanical example is right.
# There may be sign errors in the mechanical library.
# 


# Modelica.Mechanics.Examples.First
function FirstMechSys()
    g = 0.0
    # Could use an array or a macro to generate the following:
    r1 = RotationalNode("Source angle") 
    r2 = RotationalNode() 
    r3 = RotationalNode()
    r4 = RotationalNode()
    r5 = RotationalNode()
    r6 = RotationalNode("End angle")
    {
     TorqueSrc(r1, g, 10 * sin(2 * pi * 5 * MTime))
     Inertia(r1, r2, 0.1)
     IdealGear(r2, r3, 10)
     Inertia(r3, r4, 2.0)
     Spring(r4, r5, 1e4)
     Inertia(r5, r6, 2.0)
     Damper(r4, g, 10)
     }
end
