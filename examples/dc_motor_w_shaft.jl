
load("Sims")
using Sims



########################################
## Mechanical/electrical example      ##
########################################

#
# I don't know if the answer is right.
# 


# 
# This is a smaller version of David's example on p. 117 of his thesis.
# I don't know if the results are reasonable or not.
#
# The FlexibleShaft shows how to build up several elements.
# 

function ShaftElement(flangeA, flangeB)
    r1 = RotationalNode()
    {
     Spring(flangeA, r1, 8.0) 
     Damper(flangeA, r1, 1.5) 
     Inertia(r1, flangeB, 0.5) 
     }
end

function FlexibleShaft(flangeA, flangeB, n::Int)
    # n is the number of elements
    r = Array(Unknown, n)
    for i in 1:n
        r[i] = Unknown()
    end
    r[1] = flangeA
    r[end] = flangeB
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
     FlexibleShaft(r2, r3, 5)
     }
end

    
m = MechSys()
m_yout = sim(m, 4.0)
