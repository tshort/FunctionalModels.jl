

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


