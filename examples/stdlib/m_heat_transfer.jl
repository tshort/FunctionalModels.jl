using Sims


########################################
## Heat transfer examples
##
## These attempt to mimic the Modelica.Thermal.HeatTransfer.Examples
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


function ex_Motor(BROKEN)   ## needs to have `interp` defined
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
