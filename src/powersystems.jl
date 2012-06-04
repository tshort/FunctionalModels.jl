

########################################
## PowerSystems
########################################

const c = 299792458.0
const mue_0 = 4pi * 1.e-7
const epsilon_0 = 1 / (mue_0 * c * c)

########################################
## Line Models
########################################

SeriesImpedance = ShuntAdmittance = Array{Complex128, 2}

function RLLine(n1::ElectricalNode, n2::ElectricalNode, Z::SeriesImpedance, len::Real, freq::Real)
    vals = compatible_values(n1, n2) 
    i = Current(vals)
    v = Voltage(vals)
    R = real(Z) * len
    L = imag(Z) * len / (2pi * freq)
    {
     Branch(n1, n2, v, i)
     L * der(i) + R * i - v
     }
end


function PiLine(n1::ElectricalNode, n2::ElectricalNode, Z::SeriesImpedance, Y::ShuntAdmittance, len::Real, freq::Real, ne::Int)
    vals = compatible_values(n1, n2)
    nc = length(vals)
    ne1 = ne + 1
    i = Current(zeros(nc, ne1))
    v = Voltage(zeros(nc, ne))
    R = real(Z) / ne * len
    L = imag(Z) / ne * len / (2pi * freq)
    G = real(Z) * ne / len
    C = imag(Z) * ne / len / (2pi * freq)
    {
     RefBranch(n1, i[:, 1])
     RefBranch(n2, -i[:, ne1])
     C * der(v) + G * v - (i[:, 1:ne] - i[p:, 2:ne1])
     L * der(i) + R * i - [[2 * (n1 - v[:, 1])],
                           v[:, 1:ne - 1] - v[:, 2:ne],
                           [2 * (v[:, ne] - n2)]]
     }
end


########################################
## Impedance Models
########################################


type ConductorGeometries
    nc::Int           # Number of conductors
    x::Vector{Float64}   # Horizontal positioning of conductors, m
    y::Vector{Float64}   # Vertical positioning of conductors, m
    radius::Vector{Float64}  # Conductor radius, m
    gmr::Vector{Float64}     # Conductor geometric mean radius, m
    rho::Vector{Float64}     # Conductor resistivity, ohm-m
end

type Conductor
    radius::Real # Conductor radius
    gmr::Real    # Geometric mean radius
    Rdc::Real    # DC resistance per m
    area::Real   # Cross-sectional area, m^2
    rho::Real    # Conductor resistivity, ohm-m
end
Conductor(radius::Real, gmr::Real, Rdc::Real, area::Real) = Conductor(radius, gmr, Rdc, area, Rdc .* area)

type ConductorLocation
    x::Real  # Horizontal positioning of conductors
    y::Real  # Vertical positioning of conductors
    cond::Conductor  # Conductor specs
end

ConductorGeometries(cl::Vector{ConductorLocation}) =
    ConductorGeometries(length(cl),
                        map(x -> x.x, cl),
                        map(x -> x.y, cl),
                        map(x -> x.cond.radius, cl),
                        map(x -> x.cond.gmr, cl),
                        map(x -> x.cond.rho, cl))
ConductorGeometries(args::ConductorLocation...) = ConductorGeometries([args...])



function OverheadImpedances(freq::Real, rho::Real, cg::ConductorGeometries)
    P = fill(0.0im, cg.nc, cg.nc)
    w = 2pi * freq
    De = sqrt(1 / 1.0im * rho / w / mue_0)
    Z = fill(0.0im, cg.nc, cg.nc)
    P = fill(0.0im, cg.nc, cg.nc)
    for idx in 1:cg.nc
        de = sqrt(cg.rho[idx] / 1im / w / mue_0)
        Z[idx,idx] = 1im * w * mue_0 / 2 / pi * log(2 * (cg.y[idx] + De) / cg.radius[idx]) +
            cg.rho[idx] / pi / cg.radius[idx]^2 *
            (0.3565 + cg.radius[idx] / 2 / de * acoth(0.777 * cg.radius[idx] / de))
        P[idx,idx] = 1 / ( 1im * w * 2 * pi * epsilon_0) *
            log(2 * cg.y[idx] / cg.radius[idx])
        for kdx in (idx+1):cg.nc
            dik = sqrt((cg.y[idx] - cg.y[kdx])^2 + (cg.x[idx] - cg.x[kdx])^2)
            Dik = sqrt((cg.y[idx] + cg.y[kdx])^2 + (cg.x[idx] - cg.x[kdx])^2)
            Z[idx,kdx] = 1im * w * mue_0 / 2 / pi *
                log(sqrt((cg.y[idx] + cg.y[kdx] + 2*De)^2 + (cg.x[idx] - cg.x[idx])^2) / dik)
            Z[kdx,idx] = Z[idx,kdx]
            P[idx,kdx] = 1 / (1im * w * 2 * pi * epsilon_0) * log(Dik / dik)
            P[kdx,idx] = P[idx,kdx]
        end
    end
    Y = inv(P)
    Z, Y     # both in ohms/m
end



Conductors = Dict()
Conductors["AAC 6"         ] = Conductor(0.0023368, 0.00169505260283220, 0.00220648910363477,  1.3290296e-05)  
Conductors["AAC 4"         ] = Conductor(0.0029464, 0.00213500023006833, 0.00138690050107373,  2.1161248e-05)  
Conductors["AAC 2"         ] = Conductor(0.0037084, 0.00268913541371853, 0.000871162411516742, 3.3677352e-05)  
Conductors["AAC 1"         ] = Conductor(0.0041656, 0.00301800562571244, 0.00069052980593335,  4.2387012e-05)  
Conductors["AAC 1/0"       ] = Conductor(0.0046736, 0.00338709531337320, 0.000548111528672552, 5.3483764e-05)  
Conductors["AAC 2/0"       ] = Conductor(0.0052578, 0.00380132315332131, 0.000434587011850791, 6.741922e-05)   
Conductors["AAC 3/0"       ] = Conductor(0.0058928, 0.00426620935611816, 0.000344923148810944, 8.4967572e-05)  
Conductors["AAC 4/0"       ] = Conductor(0.0066294, 0.00478794923139534, 0.000273279050345980, 0.000107290108) 
Conductors["AAC 250 kcmil" ] = Conductor(0.0072009, 0.00524227277904635, 0.000231398631989183, 0.000126709424) 
Conductors["AAC 267 kcmil" ] = Conductor(0.0074422, 0.00541796266207486, 0.000216858546090830, 0.000135290052) 
Conductors["AAC 300 kcmil" ] = Conductor(0.0079883, 0.00603065220129721, 0.000192687206712797, 0.000152128728) 
Conductors["AAC 336 kcmil" ] = Conductor(0.0084582, 0.00638878052680925, 0.000171871271772847, 0.000170580304) 
Conductors["AAC 350 kcmil" ] = Conductor(0.0086233, 0.00654870252913523, 0.000165409011373578, 0.000177289968) 
Conductors["AAC 398 kcmil" ] = Conductor(0.0091821, 0.00693759510538613, 0.000145400858983536, 0.000201547984) 
Conductors["AAC 450 kcmil" ] = Conductor(0.0097663, 0.00741040142097535, 0.000128561699673904, 0.000227999544) 
Conductors["AAC 477 kcmil" ] = Conductor(0.0100711, 0.00759589632541113, 0.000121415930963175, 0.000241547904) 
Conductors["AAC 500 kcmil" ] = Conductor(0.0102997, 0.00778603448162464, 0.000115823590233039, 0.000253289816) 
Conductors["AAC 556 kcmil" ] = Conductor(0.0108585, 0.00824840561466452, 0.000104017537580530, 0.000281870404) 
Conductors["AAC 700 kcmil" ] = Conductor(0.0122174, 0.00941099577128183, 8.26423685675654e-05, 0.000354450904) 
Conductors["AAC 716 kcmil" ] = Conductor(0.0123698, 0.00948887392432065, 8.08403921100772e-05, 0.000362708952) 
Conductors["AAC 750 kcmil" ] = Conductor(0.0126619, 0.00972639651747099, 7.71743020758769e-05, 0.000380128272) 
Conductors["AAC 795 kcmil" ] = Conductor(0.0130302, 0.0099698647036081,  7.27004294917681e-05, 0.00040290242)  
Conductors["AAC 874 kcmil" ] = Conductor(0.0136779, 0.0104752368933353,  6.61138948540523e-05, 0.000443482984) 
Conductors["AAC 900 kcmil" ] = Conductor(0.0138684, 0.0106493242174353,  6.42497812773403e-05, 0.000456257152) 
Conductors["AAC 954 kcmil" ] = Conductor(0.0142748, 0.0110062263865808,  6.058369124314e-05,   0.00048354742)  
Conductors["AAC 1000 kcmil"] = Conductor(0.0146177, 0.0111891381927375,  5.78496579972958e-05, 0.000506708664) 




########################################
## Load Models
########################################



function ConstZLoad(n1::ElectricalNode, n2::ElectricalNode,
                    load_VA, load_pf, Vln, freq::Real)
    Z = Vln .^ 2 / load_VA .* (load_pf + 1.0im * sqrt(1 - load_pf .^ 2))
    R = real(Z)
    L = imag(Z) / (2pi .* freq)
    {
     Resistor(n1, n2, R)
     Inductor(n1, n2, L)
     }
end



########################################
## Examples
########################################



function ex_RLModel()
    ns = Voltage(zeros(3), "Vs")
    np = Voltage(zeros(3))
    nl = Voltage(zeros(3), "Vl")
    g = 0.0
    Vln = 7200.0
    freq = 60.0
    rho = 100.0
    len = 4000.0
    load_VA = 1e5   # per phase
    load_pf = 0.85
    Z, Y = OverheadImpedances(freq, rho,
        ConductorGeometries(
            ConductorLocation(-1.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 0.0, 10.0, Conductors["AAC 500 kcmil"]),
            ConductorLocation( 1.0, 10.0, Conductors["AAC 500 kcmil"])))
    {
     SineVoltage(ns, g, Vln, freq, [0, -2/3*pi, 2/3*pi])
     SeriesProbe(ns, np, "I")
     RLLine(np, nl, Z, len, freq)
     ConstZLoad(nl, g, load_VA, load_pf, Vln, freq)
     }
end

m = ex_RLModel()
f = elaborate(m)
s = create_sim(f)
y = sim(s, 0.05)
