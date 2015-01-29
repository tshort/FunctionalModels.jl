
########################################
## Examples
########################################

export RLModel, PiModel, ModalModel

@comment """
# Power systems
"""

@doc* """
Three-phase RL line model

See also sister models: PiModel and ModalModal.

WARNING: immature / possibly broken!

""" ->
function RLModel()
    ns = Voltage(zeros(3), "Vs")
    np = Voltage(zeros(3))
    nl = Voltage(zeros(3), "Vl")
    g = 0.0
    Vln = 7200.0
    freq = 60.0
    rho = 100.0
    len = 4000.0    # meters
    load_VA = 1e6   # per phase
    load_pf = 0.85
    ## load_pf = 1.0
    Z, Y = OverheadImpedances(freq, rho,
        ConductorGeometries(
            ConductorLocation(-1.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 0.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 1.0, 10.0, Conductors["AAC 500 kcmil"])))
    Equation[
        SineVoltage(ns, g, Vln, freq, [0, -2/3*pi, 2/3*pi])
        SeriesProbe(ns, np, "I")
        RLLine(np, nl, Z, len, freq)
        ConstZSeriesLoad(nl, g, load_VA, load_pf, Vln, freq)
        ## ConstZParallelLoad(nl, g, load_VA, load_pf, Vln, freq)
    ]
end

@doc* """
Three-phase Pi line model

See also sister models: RLModel and ModalModal.

WARNING: immature / possibly broken!

""" ->
function PiModel()
    # Lots of junk on the load voltage with this configuration.
    # Also, it won't solve at 60 Hz. It's probably too stiff. It
    # may need some more shunt resistance in parallel with the cap.
    # With load_pf = 1.0, it is much cleaner but still doesn't solve
    # at 60 Hz. Also, it's cleaner with info[11] = 2.
    # Will solve for 6 kHz line parameter solution if the solution
    # time is short enough (lower delta t).
    # 
    ns = Voltage(zeros(3), "Vs")
    np = Voltage(zeros(3))
    nl = Voltage(zeros(3), "Vl")
    g = 0.0
    Vln = 7200.0
    freq = 6000.0
    rho = 100.0
    len = 4000.0
    load_VA = 1e6   # per phase
    ## load_pf = 0.95
    load_pf = 1.0
    ne = 5
    ## load_pf = 1.0
    Z, Y = OverheadImpedances(freq, rho,
        ConductorGeometries(
            ConductorLocation(-1.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 0.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 1.0, 10.0, Conductors["AAC 500 kcmil"])))
    Equation[
        SineVoltage(ns, g, Vln, 60.0, [0, -2/3*pi, 2/3*pi])
        SeriesProbe(ns, np, "I")
        PiLine(np, nl, Z, Y, len, freq, ne)
        ## ConstZSeriesLoad(nl, g, load_VA, load_pf, Vln, freq)
        ConstZSeriesLoad(nl, g, load_VA, load_pf, Vln, 60.0)
        ## ConstZParallelLoad(nl, g, load_VA, load_pf, Vln, freq)
    ]
end     

     
## m = ex_PiModel()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 0.1)

@doc* """
Three-phase modal line model

See also sister models: PiModel and RLModal.

WARNING: immature / possibly broken!

""" ->
function ModalModel()
    ns = Voltage(zeros(3), "Vs")
    np = Voltage(zeros(3))
    nl = Voltage(zeros(3), "Vl")
    g = 0.0
    Vln = 7200.0
    freq = 6000.0
    rho = 100.0
    len = 4000.0
    load_VA = 1e6   # per phase
    ## load_pf = 0.95
    load_pf = 1.0
    Z, Y = OverheadImpedances(freq, rho,
        ConductorGeometries(
            ConductorLocation(-1.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 0.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 1.0, 10.0, Conductors["AAC 500 kcmil"])))
    Equation[
        SineVoltage(ns, g, Vln, 60.0, [0, -2/3*pi, 2/3*pi])
        SeriesProbe(ns, np, "I")
        ModalLine(np, nl, Z, Y, len, freq)
        ConstZSeriesLoad(nl, g, load_VA, load_pf, Vln, 60.0)
    ]
end

     
## m = ex_Modal()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 0.2)


