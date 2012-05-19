
load("../src/sims.jl")
load("../library/electromechanical.jl")




########################################
## Mechanical/electrical example      ##
########################################

#
# May be broken!!!!!!!!!
# 


# 
# This is a smaller version of David's example on p. 117 of his thesis.
# I don't know if the results are reasonable or not.
#
# The FlexibleShaft shows how to build up several elements.
# 

function FlexibleShaft(flangeA, flangeB, n::Int)
    r = Array(Unknown, n)
    for i in 1:n
        r[i] = Unknown()
    end
    result = {}
    for i in 1:(n - 1)
        push(result, ShaftElement(r[i], r[i + 1]))
    end
    result
end

function MechSys()
    r1 = RotationalNode("Source angle") 
    r2 = RotationalNode()
    r3 = RotationalNode("End-of-shaft angle")
    {
     DCMotor(r1)
     Inertia(r1, r2, 0.02)
     FlexibleShaft(r2, r3, 30)
     }
end

    
m = MechSys()
m_yout = sim(m, 1.0)
