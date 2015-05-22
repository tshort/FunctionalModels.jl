

export HalfWaveRectifier, StructuralHalfWaveRectifier


# With a zero angle, both of the problems below fail.
function VSource(n1::NumberOrUnknown{UVoltage}, n2::NumberOrUnknown{UVoltage}, V::Real, f::Real, ang::Real)  
    i = Current()
    v = Voltage()
    @equations begin
        Branch(n1, n2, v, i) 
        v = V * sin(2 * pi * f * MTime + ang)
    end
end



function IdealDiode(n1, n2)
    i = Current()
    v = Voltage()
    s = Unknown()  # dummy variable
    openswitch = Discrete(false)  # on/off state of diode
    @equations begin
        Branch(n1, n2, v, i)
        BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative
        v = ifelse(openswitch, s, 0.0) 
        i = ifelse(openswitch, 0.0, s) 
        ## v = s * ifelse(openswitch, 1.0, 1e-5) 
        ## i = s * ifelse(openswitch, 1e-5, 1.0) 
     end
end

function OpenDiode(n1, n2)
    v = Voltage()
    Equation[
        StructuralEvent(v+0.0,     # when V goes positive, this changes to a ClosedDiode
            Branch(n1, n2, v, 0.0),
            () -> ClosedDiode(n1, n2))
    ]
end

function ClosedDiode(n1, n2)
    i = Current()
    Equation[
        StructuralEvent(-i,     # when I goes negative, this changes to an OpenDiode
            Branch(n1, n2, 0.0, i),
            () -> OpenDiode(n1, n2))
    ]
end


@doc+ """
A half-wave rectifier. The diode uses Events to toggle switching.

See F. E. Cellier and E. Kofman, *Continuous System Simulation*,
Springer, 2006, fig 9.27.
""" ->
function HalfWaveRectifier()
    nsrc = Voltage("Source voltage")
    n2 = Voltage("")
    nout = Voltage("Output voltage")
    g = 0.0 
    Equation[
        VSource(nsrc, g, 1.0, 60.0, pi/32)
        Resistor(nsrc, n2, 1.0)
        IdealDiode(n2, nout)
        Capacitor(nout, g, 0.001)
        Resistor(nout, g, 50.0)
    ]
end




@doc+ """
This is the same circuit used in
Sims.Examples.Basics.HalfWaveRectifier, but a structurally variable
diode is used instead of a diode that uses Events.
""" ->
function StructuralHalfWaveRectifier()
    nsrc = Voltage("Source voltage")
    n2 = Voltage("")
    nout = Voltage("Output voltage")
    Vdiode = Unknown("Vdiode")    # probe variable
    g = 0.0 
    @equations begin
        Vdiode = n2 - nout
        VSource(nsrc, g, 1.0, 60.0, pi/32)
        Resistor(nsrc, n2, 1.0)
        ClosedDiode(n2, nout)
        Capacitor(nout, g, 0.001)
        Resistor(nout, g, 50.0)
    end
end

