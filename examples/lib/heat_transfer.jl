
########################################
## Heat transfer examples
##
## These attempt to mimic the Modelica.Thermal.HeatTransfer.Examples
########################################

export TwoMasses, Motor

@comment """
# Heat transfer
"""

"""
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
"""
function TwoMasses()
    t1 = Temperature(373.15, "t1", gensym = false)
    t2 = Temperature(273.15, "t2", gensym = false)
    [
        HeatCapacitor(t1, C = 15.0, name = :hc1)
        HeatCapacitor(t2, C = 15.0, name = :hc2)
        ThermalConductor(t1, t2, G = 10.0, name = :tc1)
    ]
end


"""
Second order thermal model of a motor

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Thermal.HeatTransfer.Examples.MotorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.Motor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.Motor)
"""
function Motor(BROKEN)   ## needs to have `interp` defined
    p1 = Temperature("p1")
    p2 = Temperature("p2")
    p3 = Temperature("p3")
    TAmb = 293.15
    t = [0, 360, 360, 600]
    winding_losses = [100, 100, 1000, 1000]
    [
        # Winding
        HeatCapacitor(p1, C = 2500.0, name = :hc1)
        PrescribedHeatFlow(p1, Q_flow = interp(winding_losses, t, t), T_ref = 95 + 273.15, alpha = 3.03E-3, name = hf1)
        # Core
        HeatCapacitor(p2, C = 25000.0, name = :hc2)
        PrescribedHeatFlow(p2, Q_flow = 500.0, name = :hf2)
        # conduction between the winding and core:
        ThermalConductor(p1, p2, G = 10.0, name = :tc1)
        # Convection to ambient 
        Convection(p2, p3, Gc = 25.0, name = :conv1)
        FixedTemperature(p3, T = TAmb, name = :t1)
    ]
end

