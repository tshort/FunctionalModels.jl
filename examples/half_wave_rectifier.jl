
load("../src/sims.jl")
load("../library/electrical.jl")



function IdealDiode(n1, n2)
    i = Current()
    v = Voltage()
    s = Unknown()  # dummy variable
    openswitch = Discrete(false)  # on/off state of diode
    {
     Branch(n1, n2, v, i)
     BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative
     v - ifelse(openswitch, s, 0.0) 
     i - ifelse(openswitch, 0.0, s) 
     ## v - s * ifelse(openswitch, 1.0, 1e-5) 
     ## i - s * ifelse(openswitch, 1e-5, 1.0) 
     }
end

function OpenDiode(n1, n2)
    v = Voltage()
    StructuralEvent(v+0.0,     # when V goes positive, this changes to a ClosedDiode
        :(ClosedDiode($n1, $n2)),
        Branch(n1, n2, v, 0.0))
end

function ClosedDiode(n1, n2)
    i = Current()
    StructuralEvent(-i,     # when I goes negative, this changes to an OpenDiode
        :(OpenDiode($n1, $n2)),
        Branch(n1, n2, 0.0, i))
end

# Cellier, fig 9.27
function HalfWaveRectifier()
    nsrc = ElectricalNode("Source voltage")
    n2 = ElectricalNode("")
    nout = ElectricalNode("Output voltage")
    g = 0.0 
    {
     VSource(nsrc, g, 1.0, 60.0)
     Resistor(nsrc, n2, 1.0)
     IdealDiode(n2, nout)
     Capacitor(nout, g, 0.001)
     Resistor(nout, g, 50.0)
     }
end


println("**** Non-structural Half Wave Rectifier ****")
rct = HalfWaveRectifier()
rct_f = elaborate(rct)
rct_s = create_sim(rct_f) 
rct_y = sim(rct_s, 0.1)  






# The same circuit with a structurally variable diode.
function StructuralHalfWaveRectifier()
    nsrc = ElectricalNode("Source voltage")
    n2 = ElectricalNode("")
    nout = ElectricalNode("Output voltage")
    Vdiode = Unknown("Vdiode")    # probe variable
    g = 0.0 
    {
     Vdiode - (n2 - nout)
     VSource(nsrc, g, 1.0, 60.0)
     Resistor(nsrc, n2, 1.0)
     ClosedDiode(n2, nout)
     Capacitor(nout, g, 0.001)
     Resistor(nout, g, 50.0)
     }
end

println("**** Structural Half Wave Rectifier ****")
sct = StructuralHalfWaveRectifier()
sct_f = elaborate(sct)
sct_s = create_sim(sct_f) 
sct_y = sim(sct_s, 0.1)  


