
########################################
## Heat transfer examples
##
## These attempt to mimic the Modelica.Thermal.HeatTransfer.Examples
########################################

export TwoMasses, Motor

@comment """
# Heat transfer
"""

@doc* """
Simple conduction demo

This example demonstrates the thermal response of two masses
connected by a conducting element. The two masses have the same heat
capacity but different initial temperatures (T1=100 [degC], T2= 0
[degC]). The mass with the higher temperature will cool off while the
mass with the lower temperature heats up. They will each
asymptotically approach the calculated temperature T_final_K
(T_final_degC) that results from dividing the total initial energy in
the system by the sum of the heat capacities of each element.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Thermal.HeatTransfer.Examples.TwoMassesD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.TwoMasses)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.TwoMasses)
""" ->
function TwoMasses()
    t1 = Temperature(373.15, "t1")
    t2 = Temperature(273.15, "t2")
    Equation[
        HeatCapacitor(t1, 15.0)
        HeatCapacitor(t2, 15.0)
        ThermalConductor(t1, t2, 10.0)
    ]
end


@doc* """
Second order thermal model of a motor

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Thermal.HeatTransfer.Examples.MotorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.Motor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.Motor)
""" ->
function Motor(BROKEN)   ## needs to have `interp` defined
    p1 = Temperature("p1")
    p2 = Temperature("p2")
    p3 = Temperature("p3")
    TAmb = 293.15
    t = [0, 360, 360, 600]
    winding_losses = [100, 100, 1000, 1000]
    Equation[
        # Winding
        HeatCapacitor(p1, 2500.0)
        PrescribedHeatFlow(p1, interp(winding_losses, t, MTime), 95 + 273.15, 3.03E-3)
        # Core
        HeatCapacitor(p2, 25000.0)
        PrescribedHeatFlow(p2, 500.0)
        # conduction between the winding and core:
        ThermalConductor(p1, p2, 10.0)
        # Convection to ambient 
        Convection(p2, p3, 25.0)
        FixedTemperature(p3, TAmb)
    ]
end

