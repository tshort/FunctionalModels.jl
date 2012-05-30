

########################################
## Heat transfer models               ##
########################################

########################################
## Basic
########################################



function HeatCapacitor(hp::HeatPort, C::Signal, Tstart::Real)
# can't really use Tstart here. Need to define at the top level.
    Q_flow = HeatFlow(compatible_values(hp))
    {
     RefBranch(hp, Q_flow)
     C .* der(hp) - Q_flow
     }
end
HeatCapacitor(hp::HeatPort, C::Signal) = HeatCapacitor(hp, C, 293.15)


function ThermalConductor(port_a::HeatPort, port_b::HeatPort, G::Signal)
    dT = Temperature(compatible_values(port_a, port_b))
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    {
     Branch(port_a, port_b, dT, Q_flow)
     G .* dT - Q_flow
     }
end


function Convection(port_a::HeatPort, port_b::HeatPort, Gc::Signal)
    dT = Temperature(compatible_values(port_a, port_b))
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    {
     Branch(port_a, port_b, dT, Q_flow)
     Gc .* dT - Q_flow
     }
end


function BodyRadiation(port_a::HeatPort, port_b::HeatPort, Gr::Signal)
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    {
     RefBranch(port_a, Q_flow)
     RefBranch(port_b, -Q_flow)
     sigma .* Gr .* (port_a .^ 4 - port_b .^ 4) - Q_flow
     }
end


function ThermalCollector(port_a::HeatPort, port_b::HeatPort)
    # This ends up being a short circuit.
    Q_flow = HeatFlow(compatible_values(port_a, port_b))
    {
     Branch(port_a, port_b, 0.0, Q_flow)
     }
end



########################################
## Sources
########################################


function FixedTemperature(port::HeatPort, T::Signal)
    Q_flow = HeatFlow(compatible_values(port, T))
    {
     Branch(port, T, 0.0, Q_flow)
     }
end
PrescribedTemperature = FixedTemperature


function FixedHeatFlow(port::HeatPort, Q_flow::Signal, T_ref::Signal, alpha::Signal)
    Q_flow = HeatFlow(compatible_values(port, T))
    {
     RefBranch(port, Q_flow .* alpha .* (port - T_ref))
     }
end
FixedHeatFlow(port::HeatPort, Q_flow::Signal, T_ref::Signal) = FixedHeatFlow(port, Q_flow, T_ref, 0.0)
FixedHeatFlow(port::HeatPort, Q_flow::Signal) = FixedHeatFlow(port, Q_flow, 293.15, 0.0)
PrescribedHeatFlow = FixedHeatFlow




########################################
## Examples
########################################


function ex_TwoMasses()
    p1 = Temperature(373.15, "p1")
    p2 = Temperature(273.15, "p2")
    {
     HeatCapacitor(p1, 15.0, 373.15)
     HeatCapacitor(p2, 15.0, 273.15)
     ThermalConductor(p1, p2, 10.0)
     }
end


function sim_TwoMasses()
    y = sim(ex_TwoMasses(), 1.0)
    wplot(y, "TwoMasses.pdf")
end


function ex_Motor()
    p1 = Temperature("p1")
    p2 = Temperature("p2")
    p3 = Temperature("p3")
    TAmb = 293.15
    t = [0, 360, 360, 600]
    winding_losses = [100, 100, 1000, 1000]
    {
     # Winding
     HeatCapacitor(p1, 2500.0, TAmb)
     PrescribedHeatFlow(p1, interp(winding_losses, t, MTime), 95 + 273.15, 3.03E-3)
     # Core
     HeatCapacitor(p2, 25000.0, TAmb)
     PrescribedHeatFlow(p2, 500.0)
     # conduction between the winding and core:
     ThermalConductor(p1, p2, 10.0)
     # Convection to ambient 
     Convection(p2, p3, 25.0)
     FixedTemperature(p3, TAmb)
     }
end

function sim_Motor()
    y = sim(ex_Motor(), 7200.0)
    wplot(y, "Motor.pdf")
end
