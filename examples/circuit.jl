

load("../src/sims.jl")
load("../library/electrical.jl")



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

## plot(ckt_a_yout)
