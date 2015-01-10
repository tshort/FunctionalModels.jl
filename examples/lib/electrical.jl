
########################################
## Electrical examples
##
## These attempt to mimic the Modelica.Electrical.Analog.Examples
########################################

@doc """
# Electrical
""" -> type DocHeadElectrical <: DocTag end
  

export CauerLowPassAnalog,
       CauerLowPassOPV,
       CauerLowPassOPV2,
       CharacteristicIdealDiodes,
       ChuaCircuit,
       HeatingResistor,
       HeatingRectifier,
       Rectifier,
       ShowSaturatingInductor,
       ShowVariableResistor,
       ControlledSwitchWithArc,
       CharacteristicThyristors,
       run_electrical_examples

@doc* """
Cauer low-pass filter with analog components

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network. The voltage source on `n1` is the
input voltage (step), and `n4` is the filter output voltage. The
pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassAnalogD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)
""" ->
function CauerLowPassAnalog()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    n4 = Voltage("n4")
    g = 0.0
    Equation[
        StepVoltage(n1, g, 1.0, 1.0, 0.0)
        Resistor(n1, n2, 1.0)
        Capacitor(n2, g, 1.072)
        Capacitor(n2, n3, 1/(1.704992^2 * 1.304))
        Inductor(n2, n3, 1.304)
        Capacitor(n3, g, 1.682)
        Capacitor(n3, n4, 1/(1.179945^2 * 0.8586))
        Inductor(n3, n4, 0.8565)
        Capacitor(n4, g, 0.7262)
        Resistor(n4, g, 1.0)
    ]
end

# m = CauerLowPassAnalog()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 60.0)
# y = sim(CauerLowPassAnalog(), 60.0)
# _ex1 = copy(_ex)

@doc* """
Cauer low-pass filter with operational amplifiers

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network with op amps. The voltage source
on `n[1]` is the input voltage (step), and `n[10]` is the filter output
voltage. The pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassOPVD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
""" ->
function CauerLowPassOPV()
    n = Voltage(zeros(11), "n")
    g = 0.0
    l1 = 1.304
    l2 = 0.8586
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    c3 = 1.682
    c4 = 1 / (1.179945^2 + l2)
    c5 = 0.7262
    Equation[
        StepVoltage(n[1], g, -1.0, 1.0, 0.0)
        IdealOpAmp(g, n[2], n[3])
        IdealOpAmp(g, n[4], n[5])
        IdealOpAmp(g, n[6], n[7])
        IdealOpAmp(g, n[8], n[9])
        IdealOpAmp(g, n[10], n[11])
        Resistor(n[1], n[2], 1.0)
        Resistor(n[3], n[4], -1.0)
        Resistor(n[5], n[6], 1.0)
        Resistor(n[7], n[8], -1.0)
        Resistor(n[9], n[10], 1.0)
        Capacitor(n[2], n[3], c1 + c2)
        Capacitor(n[4], n[5], l1)
        Capacitor(n[6], n[7], c2 + c3 + c4)
        Capacitor(n[8], n[9], l2)
        Capacitor(n[10], n[11], c4 + c5)
        Resistor(n[2], n[3], 1.0)
        Resistor(n[2], n[5], 1.0)
        Resistor(n[4], n[7], -1.0)
        Resistor(n[6], n[9], 1.0)
        Resistor(n[8], n[11], -1.0)
        Resistor(n[10], n[11], 1.0)
        Capacitor(n[2], n[7], c2)
        Capacitor(n[3], n[6], c2)
        Capacitor(n[6], n[11], c4)
        Capacitor(n[7], n[10], c4)
    ]
end

@doc* """
Cauer low-pass filter with operational amplifiers (alternate implementation)

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network with op amps. The voltage source
on `n1` is the input voltage (step), and `n10` is the filter output
voltage. The pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassOPVD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
""" ->
function CauerLowPassOPV2()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    n4 = Voltage("n4")
    n5 = Voltage("n5")
    n6 = Voltage("n6")
    n7 = Voltage("n7")
    n8 = Voltage("n8")
    n9 = Voltage("n9")
    n10 = Voltage("n10")
    n11 = Voltage("n11")
    g = 0.0
    l1 = 1.304
    l2 = 0.8586
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    c3 = 1.682
    c4 = 1 / (1.179945^2 + l2)
    c5 = 0.7262
    Equation[
        StepVoltage(n1, g, -1.0, 1.0, 0.0)
        IdealOpAmp(g, n2, n3)
        IdealOpAmp(g, n4, n5)
        IdealOpAmp(g, n6, n7)
        IdealOpAmp(g, n8, n9)
        IdealOpAmp(g, n10, n11)
        Resistor(n1, n2, 1.0)
        Resistor(n3, n4, -1.0)
        Resistor(n5, n6, 1.0)
        Resistor(n7, n8, -1.0)
        Resistor(n9, n10, 1.0)
        Capacitor(n2, n3, c1 + c2)
        Capacitor(n4, n5, l1)
        Capacitor(n6, n7, c2 + c3 + c4)
        Capacitor(n8, n9, l2)
        Capacitor(n10, n11, c4 + c5)
        Resistor(n2, n3, 1.0)
        Resistor(n2, n5, 1.0)
        Resistor(n4, n7, -1.0)
        Resistor(n6, n9, 1.0)
        Resistor(n8, n11, -1.0)
        Resistor(n10, n11, 1.0)
        Capacitor(n2, n7, c2)
        Capacitor(n3, n6, c2)
        Capacitor(n6, n11, c4)
        Capacitor(n7, n10, c4)
    ]
end

# m = CauerLowPassOPV()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 20.0)
# # _ex1 = copy(_ex)


# m2 = CauerLowPassOPV2()
# f2 = elaborate(m2)
# s2 = create_sim(f2)
# y2 = sim(s2, 20.0)
# # _ex2 = copy(_ex)


@doc* """
Characteristic of ideal diodes

Three examples of ideal diodes are shown:

* The totally ideal diode (Ideal) with all parameters to be zero
* The nearly ideal diode with Ron=0.1 and Goff=0.1
* The nearly ideal but displaced diode with Vknee=5 and Ron=0.1 and Goff=0.1.

The resistance and conductance are chosen untypically high since the
slopes should be seen in the graphics. The voltage across the first
diode is (s1 - n1). The current through the first diode is
proportional to n1.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CharacteristicIdealDiodesD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicIdealDiodes)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicIdealDiodes)
""" ->
function CharacteristicIdealDiodes()
    s1 = Voltage("s1")
    s2 = Voltage("s2")
    s3 = Voltage("s3")
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    g = 0.0
    Equation[
        SineVoltage(s1, g, 10.0, 1.0, -pi/10.0) 
        SineVoltage(s2, g, 10.0, 1.0, -pi/15.0, -9.0) 
        SineVoltage(s3, g, 10.0, 1.0, -pi/20.0) 
        Resistor(n1, g, 1e-3) 
        Resistor(n2, g, 1e-3) 
        Resistor(n3, g, 1e-3) 
        IdealDiode(s1, n1, 0.0, 0.0, 0.0)
        IdealDiode(s2, n2, 0.0, 0.1, 0.1) 
        IdealDiode(s3, n3, 5.0, 0.2, 0.2) 
     ]
end


# function CharacteristicIdealDiodes1()
#     s1 = Voltage("s1")
#     n1 = Voltage("n1")
#     g = 0.0
#     {
#         SineVoltage(s1, g, 10.0, 1.0, -pi/10.0, 0.0) 
#         Resistor(n1, g, 1e-3) 
#         IdealDiode(s1, n1, 0.0, 0.0, 0.0)
#     }
# end

# m = CharacteristicIdealDiodes()
# f = elaborate(m)
# s = create_sim(f)
# y = sim(s, 1.0)


@doc* """
Chua's circuit

Chua's circuit is a simple nonlinear circuit which shows chaotic
behaviour. The circuit consists of linear basic elements (capacitors,
resistor, conductor, inductor), and one nonlinear element, which is
called Chua's diode. 

To see the chaotic behaviour, plot n2 versus n3 (the two capacitor
voltages).

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ChuaCircuitD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ChuaCircuit)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ChuaCircuit)
""" ->
function ChuaCircuit()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage(4.0, "n3")
    g = 0.0
    function NonlinearResistor(n1::ElectricalNode, n2::ElectricalNode, Ga, Gb, Ve)
        i = Current(compatible_values(n1, n2))
        v = Voltage(compatible_values(n1, n2))
        Equation[
            Branch(n1, n2, v, i)
            i - ifelse(v < -Ve, Gb .* (v + Ve) - Ga .* Ve,
                       ifelse(v > Ve, Gb .* (v - Ve) + Ga*Ve, Ga*v))
        ]
    end
    Equation[
        Resistor(n1, g, 12.5e-3) 
        Inductor(n1, n2, 18.0)
        Resistor(n2, n3, 1 / 0.565) 
        Capacitor(n2, g, 100.0)
        Capacitor(n3, g, 10.0)
        NonlinearResistor(n3, g, -0.757576, -0.409091, 1.0)
    ]
end


## m = ChuaCircuit()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 1.0)


@doc* """
Heating resistor

This is a very simple circuit consisting of a voltage source and a
resistor. The loss power in the resistor is transported to the
environment via its heatPort.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.HeatingResistorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingResistor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingResistor)
""" ->
function HeatingResistor()
    n1 = Voltage("n1")
    hp1 = Temperature("hp1")
    hp2 = Temperature("hp2")
    g = 0.0
    Equation[
        SineVoltage(n1, g, 220, 1.0)
        Resistor(n1, g, 100.0, hp1, 20 + 273.15, 1e-3)
        ThermalConductor(hp1, hp2, 50.0)
        FixedTemperature(hp2, 20 + 273.15)
    ]
end


@doc* """
Heating rectifier

The heating rectifier shows a heat flow always if the electrical
capacitor is loaded. 

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.HeatingRectifierD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingRectifier)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingRectifier)

NOTE: CURRENTLY UNFINISHED
""" ->
function HeatingRectifier()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    hp1 = Temperature("hp1")
    hp2 = Temperature("hp2")
    g = 0.0
    Equation[
        SineVoltage(n1, g, 1.0, 1.0)
        HeatingDiode(n1, n2, hp1, morejunkXX)
        Capacitor(n2, g, 1.0)
        Resistor(n2, g, 1.0)
        ThermalConductor(hp1, hp2, 10.0)
        HeatCapacitor(hp2, 20 + 273.15)
    ]
end


function Rectifier()
    n = Voltage("n")
    VAC = 400.0
    n1 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vs")
    n2 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vl")
    ## np = Voltage("Vp")
    ## nn = Voltage("Vn")
    np = Voltage( VAC*sqrt(2)/2, "Vp")
    nn = Voltage(-VAC*sqrt(2)/2, "Vn")
    nout = Voltage("Vout")
    g = 0.0
    f = 50.0
    LAC = 60e-6
    Ron = 1e-3
    Goff = 1e-3
    Vknee = 2.0
    CDC = 15e-3
    IDC = 500.0
    Equation[
        SineVoltage(n1, g, VAC .* sqrt(2/3), f, [0.0, -2pi/3, 2pi/3])
        Inductor(n1, n2, LAC)
        ## Resistor(n2, np, 1e3)
        ## Resistor(n2, nn, 1e3)
        IdealDiode(n2, np, Vknee, Ron, Goff)
        IdealDiode(nn, n2, Vknee, Ron, Goff)
        ## Capacitor(np, nn, CDC)
        Capacitor(np, g, 2 * CDC)
        Capacitor(nn, g, 2 * CDC)
        ## SignalCurrent(np, nn, IDC)
    ]
end

@doc* """
B6 diode bridge

The rectifier example shows a B6 diode bridge fed by a three phase
sinusoidal voltage, loaded by a DC current. DC capacitors start at
ideal no-load voltage, thus making easier initial transient.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.RectifierD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.Rectifier)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.Rectifier)

NOTE: CURRENTLY BROKEN
""" ->
function Rectifier()
    n = Voltage("n")
    VAC = 400.0
    n1 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vs")
    n2 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]), "Vl")
    ## np = Voltage("Vp")
    ## nn = Voltage("Vn")
    np = Voltage( VAC*sqrt(2)/2, "Vp")
    nn = Voltage(-VAC*sqrt(2)/2, "Vn")
    nout = Voltage("Vout")
    g = 0.0
    f = 50.0
    LAC = 60e-6
    Ron = 1e-3
    Goff = 1e-3
    Vknee = 2.0
    CDC = 15e-3
    IDC = 500.0
    Equation[
        SineVoltage(n1, g, VAC .* sqrt(2/3), f, [0.0, -2pi/3, 2pi/3])
        Inductor(n1, n2, LAC)
        ## Resistor(n2, np, 1e3)
        ## Resistor(n2, nn, 1e3)
        IdealDiode(n2[1], np, Vknee, Ron, Goff)
        IdealDiode(n2[2], np, Vknee, Ron, Goff)
        IdealDiode(n2[3], np, Vknee, Ron, Goff)
        IdealDiode(nn, n2[1], Vknee, Ron, Goff)
        IdealDiode(nn, n2[2], Vknee, Ron, Goff)
        IdealDiode(nn, n2[3], Vknee, Ron, Goff)
        ## Capacitor(np, nn, CDC)
        Capacitor(np, g, 2 * CDC)
        Capacitor(nn, g, 2 * CDC)
        ## SignalCurrent(np, nn, IDC)
        Resistor(np, nn, 400 / IDC)
    ]
end



## m = Rectifier()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 0.1)



@doc* """
Simple demo to show behaviour of SaturatingInductor component

This simple circuit uses the saturating inductor which has a changing
inductivity.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ShowSaturatingInductorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowSaturatingInductor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowSaturatingInductor)

NOTE: CURRENTLY BROKEN
""" ->
function ShowSaturatingInductor()
    n1 = Voltage("V")
    g = 0.0
    Lzer = 2.0
    Lnom = 1.0
    Inom = 1.0
    Linf = 0.5
    U = 1.25
    f = 1/(2pi)
    phase = pi/2
    phase = 0.0
    Equation[
        SineVoltage(n1, g, U, f, phase)
        ## SaturatingInductor(n1, g, Inom, Lnom, Linf, Lzer)
        SaturatingInductor(n1, g, Inom, Lnom)
    ]
end


function ShowSaturatingInductor2()
    n1 = Voltage()
    g = 0.0
    U = 1.25
    f = 1/(2pi)
    phase = 0.0
    Equation[
        SineVoltage(n1, g, U, f, phase)
        SaturatingInductor2(n1, g, 71.0, 0.1, 0.04)
    ]
end
## m = ShowSaturatingInductor2()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 10.0)
## y | dump

function ShowSaturatingInductor3()
    n1 = Voltage()
    g = 0.0
    U = 1.25
    f = 1/(2pi)
    phase = 0.0
    Equation[
        SineVoltage(n1, g, U, f, phase)
        SaturatingInductor3(n1, g, 3e-9, 0.33, 0.15)
    ]
end
## m = ShowSaturatingInductor3()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 10.0)
## y | dump

function ShowSaturatingInductor4()
    n1 = Voltage()
    g = 0.0
    U = 1.25
    f = 1/(2pi)
    phase = 0.0
    Equation[
        SineVoltage(n1, g, U, f, phase)
        SaturatingInductor4(n1, g, .50, 0.7, 0.0)
    ]
end
## m = ShowSaturatingInductor4()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 10.0)
## y | dump


@doc* """
Simple demo of a VariableResistor model

It is a simple test circuit for the VariableResistor. The
VariableResistor sould be compared with R2. `isig1` and `isig2` are
current monitors

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ShowVariableResistorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowVariableResistor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowVariableResistor)
""" ->
function ShowVariableResistor()
    n = Voltage("Vs")
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    n4 = Voltage("n4")
    n5 = Voltage("n5")
    isig1 = Voltage("Ir1")
    isig2 = Voltage("Ir2")
    vres = Voltage("Vres")
    g = 0.0
    Equation[
        n2 - n3 - isig1    # current monitor
        n5 - n3 - isig2    # current monitor
        n5 - n4 - vres 
        SineVoltage(n, g, 1.0, 1.0)
        Resistor(n, n1, 1.0)
        Resistor(n1, n2, 1.0)
        Resistor(n2, n3, 1.0)
        Resistor(n, n4, 1.0)
        Resistor(n4, n5, 2 + 2.5 * MTime)
        Resistor(n5, n3, 1.0)
    ]
end



@doc* """
Comparison of controlled switch models both with and without arc

This example is to compare the behaviour of switch models with and without an electric arc taking into consideration.

a3 and b3 are proportional to the switch currents. The difference in
the closing area shows that the simple arc model avoids the suddenly
switching.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ControlledSwitchWithArcD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc)
""" ->
function ControlledSwitchWithArc()
    a1 = Voltage("a1")
    a2 = Voltage("a2")
    a3 = Voltage("a3")
    b1 = Voltage("b1")
    b2 = Voltage("b2")
    b3 = Voltage("b3")
    vs = Voltage("vs")
    g = 0.0
    Equation[
        SineVoltage(vs, g, 1.0, 1.0)
        SignalVoltage(a1, g, 50.0)
        ControlledIdealClosingSwitch(a1, a2, vs, 0.5, 1e-5, 1e-5)
        Inductor(a2, a3, 0.1)
        Resistor(a3, g, 1.0)
        ## SignalVoltage(b1, g, 50.0)
        ## ## ControlledCloserWithArc(b1, b2, vs, 0.5, 1e-5, 1e-5, 30.0, 1e4, 60.0)
        ## ControlledCloserWithArc(b1, b2, vs, 0.5, 1e-5, 1e-5, 60.0, 1e-2, 60.0)
        ## Inductor(b2, b3, 0.1)
        ## Resistor(b3, g, 1.0)
    ]
end


## m = ControlledSwitchWithArc()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 6.1)

function dc()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    g = 0.0
    Equation[
        SignalVoltage(n1, g, 50.0)
        Resistor(n1, n2, 0.1)
        Inductor(n2, g, 0.1)
    ]
end

## m = dc()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, .1)

@doc* """
Characteristic of ideal thyristors

Two examples of thyristors are shown: the ideal thyristor and the
ideal GTO thyristor with Vknee=5.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CharacteristicThyristorsD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicThyristors)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicThyristors)
""" ->
function CharacteristicThyristors()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage("n3")
    sig = Discrete(false)
    g = 0.0
    Equation[
        SineVoltage(n1, g, 10.0, 1.0, -0.006) 
        IdealThyristor(n1, n2, sig, 5.0)
        IdealGTOThyristor(n1, n3, sig, 0.0)
        BoolEvent(sig, MTime - 1.25)  
        Resistor(n2, g, 1e-3)
        Resistor(n3, g, 1e-3)
    ]
end



function test_BoolEventHook()
    n1 = Voltage("n1")
    sig2 = Discrete(true)
    sig = Discrete(false)
    addhook!(sig, 
             reinit(sig2, false))
    g = 0.0
    Equation[
        SineVoltage(n1, g, ifelse(sig2, 10.0, 5.0), ifelse(sig, 1.0, 2.0)) 
        BoolEvent(sig, MTime - 0.25)  
        Resistor(n1, g, 1e-3)
    ]
end

## m = test_BoolEventHook()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 2.0)


function docutil()
    
    template = """
        @doc* \"\"\"
        --LABEL--

        ![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.--NAME--D.png)
        
        [LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.--NAME--)
         | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.--NAME--)
        \"\"\" ->
        """

    entries = """
        CauerLowPassAnalog         , Cauer low-pass filter with analog components
        CauerLowPassOPV            , Cauer low-pass filter with operational amplifiers
        CauerLowPassSC             , Cauer low-pass filter with operational amplifiers and switched capacitors
        CharacteristicIdealDiodes  , Characteristic of ideal diodes
        CharacteristicThyristors   , Characteristic of ideal thyristors
        ChuaCircuit                , Chua's circuit
        DifferenceAmplifier        , Simple NPN transistor amplifier circuit
        HeatingMOSInverter         , Heating MOS Inverter
        HeatingNPN_OrGate          , Heating NPN Or Gate
        HeatingResistor            , Heating resistor
        HeatingRectifier           , Heating rectifier
        NandGate                   , CMOS NAND Gate (see Tietze/Schenk page 157)
        OvervoltageProtection      , Example for Zener diodes
        Rectifier                  , B6 diode bridge
        ShowSaturatingInductor     , Simple demo to show behaviour of SaturatingInductor component
        ShowVariableResistor       , Simple demo of a VariableResistor model
        SwitchWithArc              , Comparison of switch models both with and without arc
        ThyristorBehaviourTest     , Thyristor demonstration example
        AmplifierWithOpAmpDetailed , Simple Amplifier circuit which uses OpAmpDetailed
        CompareTransformers        , Transformer circuit to show the magnetization facilities
        ControlledSwitchWithArc    , Comparison of controlled switch models both with and without arc
        SimpleTriacCircuit         , Simple triac test circuit
        IdealTriacCircuit          , Ideal triac test circuit
        AD_DA_conversion           , Conversion circuit
    """

    a = readcsv(IOBuffer(entries))
    a = map(strip, a)
    for i in 1:size(a, 1)
        s = replace(template, "--LABEL--", a[i,2])
        s = replace(s, "--NAME--", a[i,1], 3)
        println(s)
    end
    
end    
    

@doc* """
Run the electrical examples from Examples.Lib
""" ->
function run_electrical_examples()
    clpa  = sim(CauerLowPassAnalog(), 60.0)
    clpo  = sim(CauerLowPassOPV(), 60.0)
    clpo2 = sim(CauerLowPassOPV2(), 60.0)
    cid   = sim(CharacteristicIdealDiodes(), 1.0)
    cc    = sim(ChuaCircuit(), 5000.0)
    hr    = sim(HeatingResistor(), 5.0)
    svr   = sim(ShowVariableResistor(), 6.2832)
    ## ct    = sim(CharacteristicThyristors(), 2.0)
    ## -- Broken examples --
    ## hr    = sim(HeatingRectifier(), 5.0)
    ## r     = sim(Rectifier(), 0.1)
    ## ssi   = sim(ShowSaturatingInductor(), 6.2832)
    ## cswa  = sim(ControlledSwitchWithArc(), 6)
end


