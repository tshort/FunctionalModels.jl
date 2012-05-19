

########################################
## Simple electrical library          ##
########################################



type UVoltage <: UnknownCategory
end
type UCurrent <: UnknownCategory
end
typealias ElectricalNode Unknown{UVoltage}
typealias Voltage Unknown{UVoltage}
typealias Current Unknown{UCurrent}

function Resistor(n1, n2, R::Real) 
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i)
     R * i - v   # == 0 is implied
     }
end

# These models are locally balanced; the number of unknowns matches
# the number of equations. It's pretty easy to match unknowns and
# equations as shown below:
function Capacitor(n1, n2, C::Real) 
    i = Current()              # Unknown #1
    v = Voltage()              # Unknown #2
    {
     Branch(n1, n2, v, i)      # Equation #1 - this returns n1 - n2 - v
     C * der(v) - i            # Equation #2
     }
end



function Inductor(n1, n2, L::Real) 
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i)
     L * der(i) - v
     }
end

#
# Nodes or parameters can be weakly typed or strongly typed. The
# following is used to more strongly type the input nodes. With this
# approach, one could define different characteristics for a device
# with different node inputs. It will also help prevent connection of
# types that shouldn't be connected.
#
typealias NumberOrUnknown{T} Union(AbstractArray, Number, Unknown{T})


#
# MTime in the model below is a special variable indicating simulation
# time.
#
# The node input parameters are more strongly typed, too.
#
function VSource(n1::NumberOrUnknown{UVoltage}, n2::NumberOrUnknown{UVoltage}, V::Real, f::Real)  
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i) 
     v - V * sin(2 * pi * f * MTime)
     }
end

function VConst(n1, n2, V::Real)  
    i = Current()
    v = Voltage()
    {
     Branch(n1, n2, v, i) 
     v - V
     }
end

function SeriesProbe(n1, n2, name::String) 
    i = Unknown(base_value(n1, n2), name)   
    Branch(n1, n2, base_value(n1, n2), i)
end

