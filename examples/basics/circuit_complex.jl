
using Sims
module ComplexExamples

importall Sims

########################################
## Basic complex number example       ##
########################################




# 
# The following is a very basic example of complex numbers used in a circuit model. 
# 


#
# The following complex unknown types are defined, but they are mostly
# not used in the example below (things are left untyped).
# 
type UComplexVoltage <: UnknownCategory
end
type UComplexCurrent <: UnknownCategory
end
typealias ComplexElectricalNode Unknown{UComplexVoltage}
typealias ComplexVoltage Unknown{UComplexVoltage}
typealias ComplexCurrent Unknown{UComplexCurrent}

function RL(n1, n2, Z::Complex)
    i = Unknown(0.im, "RL i")
    v = Unknown(0.im)
    {
     Branch(n1, n2, v, i)
     Z * i - v     # Note that this doesn't include time variation (L di/dt) effects
     }
end

function VCmplxSrc(n1, n2, V::Number)
    i = Unknown(0.im)
    v = Unknown(0.im)
    {
     Branch(n1, n2, v, i)
     V - v     
     }
end

# This is just a static circuit. Nothing is time varying.
function CmplxCkt()
    n = ComplexElectricalNode(0.im, "node voltage")
    g = 0.0
    {
     VCmplxSrc(n, g, 10.+2im)
     RL(n, g, 3 + 4im)
     }
end


cckt = CmplxCkt()
cckt_f = elaborate(cckt)
cckt_s = create_sim(cckt_f) 
cckt_y = sim(cckt_s, 0.02)  
## cckt_y = sunsim(cckt, 0.02)  

end # module
