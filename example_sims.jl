
########################################
## Examples for Sims                  ##
########################################

#
# Tom Short, tshort@epri.com
#
#
# Copyright (c) 2012, Electric Power Research Institute 
# BSD license - see the LICENSE file
# 



########################################
## Van Der Pol oscillator             ##
########################################

#
# A device model is a function that returns a list of equations or
# other devices that also return lists of equations. The equations
# each are assumed equal to zero. So,
#    der(y) = x + 1
# Should be entered as:
#    der(y) - (x+1)
#
# The Van Der Pol oscillator is a simple problem with two equations
# and two unknowns:

function Vanderpol()
    y = Unknown(1.0, "y")   # The 1.0 is the initial value. "y" is for plotting.
    x = Unknown("x")        # The initial value is zero if not given.
    # The following gives the return value which is a list of equations.
    # Expressions with Unknowns are kept as expressions. Expressions of
    # regular variables are evaluated immediately (like normal).
    {
     # The -1.0 in der(x, -1.0) is the initial value for the derivative 
     der(x, -1.0) - ((1 - y^2) * x - y) # == 0 is assumed
     der(y) - x
     }
end

v = Vanderpol()       # returns the hierarchical model
v_f = elaborate(v)    # returns the flattened model
v_s = create_sim(v_f) # returns a "Sim" ready for simulation

v_yout = sim(v_s, 10.0) # run the simulation to 10 seconds and return
                        # the result as an array
stophere()
# Plotting requires the Gaston library, and I need to load it:
#   push(LOAD_PATH, "/home/tshort/julia/julia/extras/gaston-0.4")
#   load("gaston.jl")
## plot(v_yout)

# # plot the signals against each other:
# plot(v_yout.y[:,2], v_yout.y[:,3])

# The result of a "sim" run is an object with components "y" and
# "colnames". "y" is a two-dimensional array with time slices along
# rows and variables along columns. The first column is simulation
# time. The remaining columns are for each unknown in the model
# including derivatives. "colnames" contains the names of each of
# the columns in "y" after the time column.



########################################
## Circuit example                    ##
########################################

#
# This example shows definitions of several electrical components.
# Each is again a function that returns a list of equations. Equations
# are expressions (type MExpr) that includes other expressions and
# unknowns (type Unknown).
#
# Arguments to each function are model parameters. These are normally
# nodes specifying connectivity followed by parameters specifying
# model characteristics.
#
# Models can contain models or other functions that return equations.
# The function Branch is a special function that returns an equation
# specifying relationships between nodes and flows. It also acts as an
# indicator to mark nodes. In the elaboration process, equations are
# created to sum flows (in this case electrical currents) to zero at
# all nodes. RefBranch is another special function for marking nodes
# and flow variables.
#
# Nodes passed as parameters or created with ElectricalNode() are
# simply unknowns. For these electrical examples, a node is simply an
# unknown voltage.
# 

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


#
# This is the top-level circuit definition. In this case, there are no
# input parameters. The ground reference "g" is assigned zero volts.
#
# All of the equations returned in the list of equations are other
# models with different parameters.
#
# In this top-level model, three new unknowns are introduced (n1, n2,
# and n2). Because these are nodes, each unknown node will also cause
# an equation to be generated that sums the flows into the node to be
# zero.
#
# In this model, the voltages n1 and n2 are labeled, so they will
# appear in the output. A SeriesProbe is used to label the current
# through the capacitor.
#
function Circuit()
    n1 = ElectricalNode("Source voltage")   # The string indicates labeling for plots
    n2 = ElectricalNode("Output voltage")
    n3 = ElectricalNode()
    g = 0.0  # a ground has zero volts; it's not an unknown.
    {
     VSource(n1, g, 10.0, 60.0)
     Resistor(n1, n2, 10.0)
     Resistor(n2, g, 5.0)
     SeriesProbe(n2, n3, "Capacitor current")
     Capacitor(n3, g, 5.0e-3)
     }
end

ckt_a = Circuit()
ckt_af = elaborate(ckt_a)
ckt_as = create_sim(ckt_af)
# Here we do the elaboration, sim creating, and simulation in one step: 
ckt_a_yout = sim(ckt_a, 0.1)  

plot(ckt_a_yout)




########################################
## Nested circuit                     ##
########################################





function SubCircuit(n1, n2)
    {
     Resistor(n1, n2, 5.0)
     Capacitor(n1, n2, 5.0e-3)
     }
end

function SCircuit()
    n1 = ElectricalNode("Source voltage")   # The string indicates labeling for plots
    n2 = ElectricalNode("Output voltage")
    g = 0.0  # a ground has zero volts; it's not an unknown.
    {
     VSource(n1, g, 10.0, 60.0)
     Resistor(n1, n2, 10.0)
     SubCircuit(n2, g)
     }
end


sckt = SCircuit()
sckt_yout = sim(sckt, 0.1)





########################################
## Array example                      ##
########################################

#
# Unknown's can contain arrays. 
# 



function Circuit3Phase()
    V = 10. 
    f = 60.
    ang = [0, -2 / 3 * pi, 2 / 3 * pi]
    R = [3., 4., 5.]
    i = Current(zeros(3), "currents")
    v = Voltage(zeros(3), "voltages")
    {
     v - V * sin(2 * pi * f * MTime + ang)
     v - R .* i   # Need to use .* here instead of *
     }
end

ckt3 = Circuit3Phase()
ckt3_yout = sim(ckt3, 0.1)





########################################
## A bigger array example             ##
########################################




function ResistorN(n1, n2, R::Real) 
    i = Current(base_value(n1, n2))   # The base_value makes the size match with
    v = Voltage(base_value(n1, n2))   # the larger of n1 and n2.
    {
     Branch(n1, n2, v, i)
     R * i - v   # == 0 is implied
     }
end

function CapacitorN(n1, n2, C::Real) 
    i = Current(base_value(n1, n2))   # The base_value makes the size match with
    v = Voltage(base_value(n1, n2))   # the larger of n1 and n2.
    {
     Branch(n1, n2, v, i)
     C * der(v) - i
     }
end

function VSource3(n1, n2, V::Real, f::Real)  
    ang = [0, -2 / 3 * pi, 2 / 3 * pi]
    i = Current(base_value(n1, n2))   # The base_value makes the size match with
    v = Voltage(base_value(n1, n2))   # the larger of n1 and n2.
    {
     Branch(n1, n2, v, i) 
     v - V * sin(2 * pi * f * MTime + ang)
     }
end

function CircuitThreePhase()
    n1 = ElectricalNode(zeros(3), "Source voltage")
    n2 = ElectricalNode(zeros(3), "Output voltage")
    g = 0.0
    {
     VSource3(n1, g, 10.0, 60.0)
     ResistorN(n1, n2, 10.0)
     ResistorN(n2, g, 5.0)
     CapacitorN(n2, g, 5.0e-3)
     }
end

ckt3p = CircuitThreePhase()
ckt3p_yout = sim(ckt3p, 0.1)





########################################
## Square wave - test discontinuities ##
########################################



#
# The following model has discontinuities. This simulator does not
# detect events. DASSL is set up to restart when things go wrong. In
# the following case, this approach seems to work. Also, note that I
# had to add methods for several more functions that didn't support
# MExpr's.
#




function VSquare(n1, n2, V::Real, f::Real)  
    i = Current()
    v = Voltage()
    v_mag = Discrete(V)
    {
     Branch(n1, n2, v, i)
     v - v_mag
     Event(sin(2 * pi * f * MTime),
           {reinit(v_mag, V)},    # positive crossing
           {reinit(v_mag, -V)})   # negative crossing
     }
end

function CircuitSq()
    n1 = ElectricalNode("Source voltage")
    n2 = ElectricalNode("Output voltage")
    g = 0.0  # a ground has zero volts; it's not an unknown.
    {
     VSquare(n1, g, 11.0, 6.0)
     Resistor(n1, n2, 10.0)
     Resistor(n2, g, 5.0)
     Capacitor(n2, g, 5.0e-3)
     }
end

ckt_b = CircuitSq()
ckt_b_yout = sim(ckt_b, 0.5)  

plot(ckt_b_yout)


########################################
## Diode                              ##
########################################

#
# This is another test of discontinuities with an ideal diode.
# 

function Diode(n1, n2)
    i = Current()
    v = Voltage()
    s = Unknown()  # dummy variable
    {
     Branch(n1, n2, i, v)
     v - ifelse(s < 0.0, s, 0.0) 
     i - ifelse(s < 0.0, 0.0, s) 
     }
end


function HalfWaveRectifier()
    n1 = ElectricalNode("Source voltage")
    n2 = ElectricalNode()
    n3 = ElectricalNode()
    n4 = ElectricalNode("Output voltage")
    g = 0.0 
    {
     VSource(n1, g, 1.0, 1.0)
     Inductor(n1, n2, 1.0)
     Resistor(n2, n3, 1.0)
     Capacitor(n3, g, 1.0)
     Diode(n3, n4)
     Resistor(n4, g, 1.0)
     }
end

rct = HalfWaveRectifier()
rct_yout = sim(rct, 10.0)  



stophere()



########################################
## Mechanical example                 ##
########################################



#
# I'm not sure these mechanical examples are right.
# There may be sign errors.
# 



Angle = AngularVelocity = AngularAcceleration = Torque = RotationalNode = Unknown

function EMF(n1, n2, flange, k::Real)
    tau = Torque()
    i = Current()
    v = Voltage()
    w = AngularVelocity()
    {
     Branch(n1, n2, i, v)
     RefBranch(flange, tau)
     w - der(flange)
     v - k * w
     tau - k * i
     }
end

function DCMotor(flange)
    n1 = ElectricalNode()
    n2 = ElectricalNode()
    n3 = ElectricalNode()
    g = 0.0
    {
     VConst(n1, g, 60)
     Resistor(n1, n2, 100.0)
     Inductor(n2, n3, 0.2)
     EMF(n3, g, flange, 1.0)
     }
end

function Inertia(flangeA, flangeB, J::Real)
    tauA = Torque()
    tauB = Torque()
    w = AngularVelocity()
    a = AngularAcceleration()
    {
     RefBranch(flangeA, tauA)
     RefBranch(flangeB, tauB)
     flangeA - flangeB    # the angles are both equal
     w - der(flangeA)
     a - der(w)
     tauA + tauB - J * a
     }
end


function Spring(flangeA, flangeB, c::Real)
    relphi = Angle()
    tau = Torque()
    {
     Branch(flangeB, flangeA, relphi, tau)
     tau - c * relphi
     }
end


function Damper(flangeA, flangeB, d::Real)
    relphi = Angle()
    tau = Torque()
    {
     Branch(flangeB, flangeA, relphi, tau)
     tau - d * der(relphi)
     }
end

function ShaftElement(flangeA, flangeB)
    r1 = RotationalNode()
    {
     Spring(flangeA, r1, 8.0) 
     Damper(flangeA, r1, 1.5) 
     Inertia(r1, flangeB, 0.5) 
     }
end

function IdealGear(flangeA, flangeB, ratio)
    tauA = Torque()
    tauB = Torque()
    {
     RefBranch(flangeA, tauA)
     RefBranch(flangeB, tauB)
     flangeA - ratio * flangeB
     ratio * tauA + tauB
     }
end


function TorqueSrc(flangeA, flangeB, tau)
    {
     RefBranch(flangeA, tau)
     RefBranch(flangeB, tau)
     }
end



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

#
# @unknown
#
# A macro to ease entry of many unknowns.
#
#   @unknowns i("Load resistor current") v x("some val", 3.0) y{UVoltage}("label")
#
# becomes:
#
#   i = Unknown("Resistor current")
#   v = Unknown()
#   x = Unknown(3.0, "some val")
#   x = Unknown{UVoltage}("label")
#

macro unknown(args...)
    blk = expr(:block)
    for arg in args
        if isa(arg, Symbol)
            push(blk.args, :($arg = Unknown()))
        elseif isa(arg, Expr)
            name = arg.args[1]
            if length(arg.args) > 1
                newcall = copy(arg)
                if isa(arg.args[1], Expr) && arg.args[1].head == :curly    # {}
                    name = arg.args[1].args[1]
                    newcall.args[1].args[1] = :Unknown
                else
                    newcall.args[1] = :Unknown
                end
                push(blk.args, :($name = $newcall))
            else
                push(blk.args, :($name = Unknown()))
            end
        end
    end
    push(blk.args, :nothing)
    return blk
end

#
# Here's a retry with the unknown nodes defined using @unknown.
#


function FirstMechSys()
    g = 0.0
    @unknown r1("Source angle") r2 r3 r4 r5 r6("End angle")
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


m1 = FirstMechSys()
m1_yout = sim(m1, 1.0)






########################################
## Mechanical/electrical example      ##
########################################




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
cckt_y = sim(cckt, 0.02)  


stophere()
