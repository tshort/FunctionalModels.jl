using Sims, Sims.Lib
using ModelingToolkit


########################################
## Mechanical/electrical example      ##
########################################

export DcMotorWithShaft

#
# I don't know if the answer is right.
# 


# 
# This is a smaller version of David's example on p. 117 of his thesis.
# I don't know if the results are reasonable or not.
#
# The FlexibleShaft shows how to build up several elements.
# 

function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange; k::Real)
    tau = Angle()
    i = Current()
    v = Voltage()
    w = AngularVelocity()
    [
        Branch(n1, n2, i, v)
        RefBranch(flange, tau)
        der(flange) ~ w
        v ~ k * w
        tau ~ k * i
    ]
end

function DCMotor(flange::Flange)
    n1 = Voltage()
    n2 = Voltage()
    n3 = Voltage()
    g = 0.0
    [
        :vs  => SignalVoltage(n1, g, V=60.0)
        :r   => Resistor(n1, n2, R=100.0)
        :l   => Inductor(n2, n3, L=0.2)
        :emf => EMF(n3, g, flange, k=1.0)
    ]
end

function ShaftElement(flangeA::Flange, flangeB::Flange)
    r1 = Angle()
    [
        :s  => Spring(flangeA, r1, c=8.0) 
        :d  => Damper(flangeA, r1, d=1.5) 
        :in => Inertia(r1, flangeB, J=0.5) 
    ]
end

function FlexibleShaft(flangeA::Flange, flangeB::Flange; n::Int)
    # n is the number of elements
    r = [Angle() for i in 1:n]
    r[1] = flangeA
    r[end] = flangeB
    result = []
    for i in 1:(n - 1)
        push!(result, ShaftElement(r[i], r[i + 1]))
    end
    result
end

"""
A DC motor with a flexible shaft. The shaft is made of multiple
elements. These are collected together algorithmically.

This is a smaller version of an example on p. 117 of David Broman's
[thesis](http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf).

I don't know if the results are reasonable or not.
"""
function DcMotorWithShaft()
    r1 = Angle(name = "Source angle") 
    r2 = Angle()
    r3 = Angle(name = "End-of-shaft angle")
    [
        :m  => DCMotor(r1)
        :in => Inertia(r1, r2, J=0.02)
        :fs => FlexibleShaft(r2, r3, n=5)
    ]
end

    
