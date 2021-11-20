using Sims
using Sims.Lib
using ModelingToolkit


########################################
## Electrical examples
##
## These attempt to mimic the Modelica.Electrical.Analog.Examples
########################################

"""
# Electrical
"""
@comment   

export CauerLowPassAnalog,
       CauerLowPassOPV,
       CauerLowPassOPV2,
       CharacteristicIdealDiodes,
       ChuaCircuit,
       HeatingResistor,
    #    HeatingRectifier,
       Rectifier,
    #    ShowSaturatingInductor,
       ShowVariableResistor,
    #    ControlledSwitchWithArc,
    #    CharacteristicThyristors,
       run_electrical_examples

"""
Cauer low-pass filter with analog components

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network. The voltage source on `n1` is the
input voltage (step), and `n4` is the filter output voltage. The
pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassAnalogD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)
"""
function CauerLowPassAnalog()
    @variables n1(t) n2(t) n3(t) n4(t)
    g = 0.0
    [
        :vsrc => StepVoltage(n1, g, V = 1.0, start = 1.0)
        :r1 => Resistor(n1, n2, R = 1.0)
        :c1 => Capacitor(n2, g, C = 1.072)
        :c2 => Capacitor(n2, n3, C = 1/(1.704992^2 * 1.304))
        :l1 => Inductor(n2, n3, L = 1.304)
        :c3 => Capacitor(n3, g, C = 1.682)
        :c4 => Capacitor(n3, n4, C = 1/(1.179945^2 * 0.8586))
        :l2 => Inductor(n3, n4, L = 0.8565)
        :c5 => Capacitor(n4, g, C = 0.7262)
        :r2 => Resistor(n4, g, R = 1.0)
    ]
end

"""
Cauer low-pass filter with operational amplifiers

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network with op amps. The voltage source
on `n[1]` is the input voltage (step), and `n[10]` is the filter output
voltage. The pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassOPVD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
"""
function CauerLowPassOPV()
    @named n = Unknown(zeros(11))
    g = 0.0
    l1 = 1.304
    l2 = 0.8586
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    c3 = 1.682
    c4 = 1 / (1.179945^2 + l2)
    c5 = 0.7262
    [
        :vsrc => StepVoltage(n[1], g, V = -1.0, start = 1.0)
        :op1 => IdealOpAmp(g, n[2], n[3])
        :op2 => IdealOpAmp(g, n[4], n[5])
        :op3 => IdealOpAmp(g, n[6], n[7])
        :op4 => IdealOpAmp(g, n[8], n[9])
        :op5 => IdealOpAmp(g, n[10], n[11])
        :r1 => Resistor(n[1], n[2],  R = 1.0)
        :r2 => Resistor(n[3], n[4],  R = -1.0)
        :r3 => Resistor(n[5], n[6],  R = 1.0)
        :r4 => Resistor(n[7], n[8],  R = -1.0)
        :r5 => Resistor(n[9], n[10], R =  1.0)
        :c1 => Capacitor(n[2], n[3],   C = c1 + c2)
        :c2 => Capacitor(n[4], n[5],   C = l1)
        :c3 => Capacitor(n[6], n[7],   C = c2 + c3 + c4)
        :c4 => Capacitor(n[8], n[9],   C = l2)
        :c5 => Capacitor(n[10], n[11], C = c4 + c5)
        :r6 => Resistor(n[2], n[3],   R = 1.0)
        :r7 => Resistor(n[2], n[5],   R = 1.0)
        :r8 => Resistor(n[4], n[7],   R = -1.0)
        :r9 => Resistor(n[6], n[9],   R = 1.0)
        :r10 => Resistor(n[8], n[11],  R = -1.0)
        :r11 => Resistor(n[10], n[11], R = 1.0)
        :c6 => Capacitor(n[2], n[7],  C = c2)
        :c7 => Capacitor(n[3], n[6],  C = c2)
        :c8 => Capacitor(n[6], n[11], C = c4)
        :c9 => Capacitor(n[7], n[10], C = c4)
    ]
end

"""
Cauer low-pass filter with operational amplifiers (alternate implementation)

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network with op amps. The voltage source
on `n1` is the input voltage (step), and `n10` is the filter output
voltage. The pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassOPVD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
"""
function CauerLowPassOPV2()
    @variables n1(t) n2(t) n3(t) n4(t) n5(t) n6(t) n7(t) n8(t) n9(t) n10(t) n11(t)
    g = 0.0
    l1 = 1.304
    l2 = 0.8586
    c1 = 1.072
    c2 = 1/(1.704992^2 * l1)
    c3 = 1.682
    c4 = 1 / (1.179945^2 + l2)
    c5 = 0.7262
    [
        :vsrc => StepVoltage(n1, g, V = -1.0, start = 1.0)
        :op1 => IdealOpAmp(g, n2, n3)
        :op2 => IdealOpAmp(g, n4, n5)
        :op3 => IdealOpAmp(g, n6, n7)
        :op4 => IdealOpAmp(g, n8, n9)
        :op5 => IdealOpAmp(g, n10, n11)
        :r1 => Resistor(n1, n2,  R = 1.0)
        :r2 => Resistor(n3, n4,  R = -1.0)
        :r3 => Resistor(n5, n6,  R = 1.0)
        :r4 => Resistor(n7, n8,  R = -1.0)
        :r5 => Resistor(n9, n10, R =  1.0)
        :c1 => Capacitor(n2, n3,   C = c1 + c2)
        :c2 => Capacitor(n4, n5,   C = l1)
        :c3 => Capacitor(n6, n7,   C = c2 + c3 + c4)
        :c4 => Capacitor(n8, n9,   C = l2)
        :c5 => Capacitor(n10, n11, C = c4 + c5)
        :r6 => Resistor(n2, n3,   R = 1.0)
        :r7 => Resistor(n2, n5,   R = 1.0)
        :r8 => Resistor(n4, n7,   R = -1.0)
        :r9 => Resistor(n6, n9,   R = 1.0)
        :r10 => Resistor(n8, n11,  R = -1.0)
        :r11 => Resistor(n10, n11, R = 1.0)
        :c6 => Capacitor(n2, n7,  C = c2)
        :c7 => Capacitor(n3, n6,  C = c2)
        :c8 => Capacitor(n6, n11, C = c4)
        :c9 => Capacitor(n7, n10, C = c4)
    ]
end

"""
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
"""
function CharacteristicIdealDiodes()
    @variables n1(t) n2(t) n3(t)
    @variables s1(t) s2(t) s3(t)
    g = 0.0
    [
        :s1 => SineVoltage(s1, g, V = 10.0, f = 1.0, ang = -pi/10.0) 
        :s2 => SineVoltage(s2, g, V = 10.0, f = 1.0, ang = -pi/15.0, offset = -9.0) 
        :s3 => SineVoltage(s3, g, V = 10.0, f = 1.0, ang = -pi/20.0) 
        :r1 => Resistor(n1, g, R = 1e-3) 
        :r2 => Resistor(n2, g, R = 1e-3) 
        :r3 => Resistor(n3, g, R = 1e-3) 
        :d1 => IdealDiode(s1, n1, Vknee = 0.0, Ron = 0.0, Goff = 0.0)
        :d2 => IdealDiode(s2, n2, Vknee = 0.0, Ron = 0.1, Goff = 0.1) 
        :d3 => IdealDiode(s3, n3, Vknee = 5.0, Ron = 0.2, Goff = 0.2) 
     ]
end




"""
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
"""
function ChuaCircuit()
    @variables n1(t) n2(t) n3(t)
    g = 0.0
    function NonlinearResistor(n1::ElectricalNode, n2::ElectricalNode; Ga, Gb, Ve)
        i = Current(compatible_values(n1, n2))
        v = Voltage(compatible_values(n1, n2))
        [
            Branch(n1, n2, v, i)
            i ~ ifelse(v < -Ve, Gb .* (v + Ve) - Ga .* Ve,
                       ifelse(v > Ve, Gb .* (v - Ve) + Ga*Ve, Ga*v))
        ]
    end
    [
        :r1 => Resistor(n1, g,  R = 12.5e-3) 
        :l1 => Inductor(n1, n2, L = 18.0)
        :r2 => Resistor(n2, n3, R = 1 / 0.565) 
        :c1 => Capacitor(n2, g, C = 100.0)
        :c2 => Capacitor(n3, g, C = 10.0)
        :r3 => NonlinearResistor(n3, g, Ga = -0.757576, Gb = -0.409091, Ve = 1.0)
    ]
end



"""
Heating resistor

This is a very simple circuit consisting of a voltage source and a
resistor. The loss power in the resistor is transported to the
environment via its heatPort.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.HeatingResistorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingResistor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingResistor)
"""
function HeatingResistor()
    @variables n1(t) hp1(t) hp2(t)
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 220, f = 1.0)
        :r1   => Resistor(n1, g, hp1, R = 100.0, T_ref = 20 + 273.15, alpha = 1e-3)
        :tc   => ThermalConductor(hp1, hp2, G = 50.0)
        :tsrc => FixedTemperature(hp2, T = 20 + 273.15)
    ]
end


"""
Heating rectifier

The heating rectifier shows a heat flow always if the electrical
capacitor is loaded. 

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.HeatingRectifierD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingRectifier)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingRectifier)

"""
function HeatingRectifier()
    @variables n1(t) n2(t)
    @variables hp1(t) hp2(t)
    g = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = 1.0, f = 1.0)
        :d1 => HeatingDiode(n1, n2, T = hp1)
        :c1 => Capacitor(n2, g, C = 1.0)
        :r1 => Resistor(n2, g, R = 1.0)
        :tc1 => ThermalConductor(hp1, hp2, G = 10.0)
        :hc1 => HeatCapacitor(hp2, C = 1)
    ]
end


"""
B6 diode bridge

The rectifier example shows a B6 diode bridge fed by a three phase
sinusoidal voltage, loaded by a DC current. DC capacitors start at
ideal no-load voltage, thus making easier initial transient.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.RectifierD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.Rectifier)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.Rectifier)

"""
function Rectifier()
    @named n = Unknown()
    VAC = 400.0
    n1 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]))
    n2 = Voltage(VAC .* sqrt(2/3) .* sin([0,-2pi/3, 2pi/3]))
    np = Voltage( VAC*sqrt(2)/2, "Vp")
    nn = Voltage(-VAC*sqrt(2)/2, "Vn")
    nout = Voltage("Vout")
    g = Voltage()   # source floating neutral 
    f = 50.0
    LAC = 60e-6
    Ron = 1e-3
    Goff = 1e-3
    Vknee = 2.0
    CDC = 15e-3
    IDC = 500.0
    [
        :v1 => SineVoltage(n1[1], g, V = VAC .* sqrt(2/3), f = f, ang =  0.0)
        :v2 => SineVoltage(n1[2], g, V = VAC .* sqrt(2/3), f = f, ang = -2pi/3)
        :v3 => SineVoltage(n1[3], g, V = VAC .* sqrt(2/3), f = f, ang =  2pi/3)
        :l1 => Inductor(n1, n2, L = LAC)
        :d1 => IdealDiode(n2[1], np, Vknee = Vknee, Ron = Ron, Goff = Goff)
        :d2 => IdealDiode(n2[2], np, Vknee = Vknee, Ron = Ron, Goff = Goff)
        :d3 => IdealDiode(n2[3], np, Vknee = Vknee, Ron = Ron, Goff = Goff)
        :d4 => IdealDiode(nn, n2[1], Vknee = Vknee, Ron = Ron, Goff = Goff)
        :d5 => IdealDiode(nn, n2[2], Vknee = Vknee, Ron = Ron, Goff = Goff)
        :d6 => IdealDiode(nn, n2[3], Vknee = Vknee, Ron = Ron, Goff = Goff)
        :c1 => Capacitor(np, 0.0, C = 2 * CDC)
        :c2 => Capacitor(nn, 0.0, C = 2 * CDC)
        :i1 => SignalCurrent(np, nn, I = IDC)
    ]
end



## m = Rectifier()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 0.1)



"""
Simple demo to show behaviour of SaturatingInductor component

This simple circuit uses the saturating inductor which has a changing
inductivity.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ShowSaturatingInductorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowSaturatingInductor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowSaturatingInductor)

NOTE: CURRENTLY BROKEN
"""
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
    [
        :vsrc => SineVoltage(n1, g, V = U, f = f, angle = phase)
        ## SaturatingInductor(n1, g, Inom, Lnom, Linf, Lzer)
        :i1 => SaturatingInductor(n1, g, Inom = Inom, Lnom = Lnom)
    ]
end


function ShowSaturatingInductor2()
    n1 = Voltage()
    g = 0.0
    U = 1.25
    f = 1/(2pi)
    phase = 0.0
    [
        :vsrc => SineVoltage(n1, g, V = U, f = f, angle = phase)
        :i1 => SaturatingInductor2(n1, g, a = 71.0, b = 0.1, c = 0.04)
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
    [
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
    [
        SineVoltage(n1, g, U, f, phase)
        SaturatingInductor4(n1, g, .50, 0.7, 0.0)
    ]
end
## m = ShowSaturatingInductor4()
## f = elaborate(m)
## s = create_sim(f)
## y = sim(s, 10.0)
## y | dump


"""
Simple demo of a VariableResistor model

It is a simple test circuit for the VariableResistor. The
VariableResistor sould be compared with R2. `isig1` and `isig2` are
current monitors

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ShowVariableResistorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowVariableResistor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowVariableResistor)
"""
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
    [
        n2 ~ n3 + isig1    # current monitor
        n5 ~ n3 + isig2    # current monitor
        n5 ~ n4 + vres 
        :vx => SineVoltage(n, g, V = 1.0, f = 1.0)
        :r1 => Resistor(n, n1,  R = 1.0)
        :r2 => Resistor(n1, n2, R = 1.0)
        :r3 => Resistor(n2, n3, R = 1.0)
        :r4 => Resistor(n, n4,  R = 1.0)
        :r5 => Resistor(n4, n5, R = 2 + 2.5 * t)
        :r6 => Resistor(n5, n3, R = 1.0)
    ]
end



"""
Comparison of controlled switch models both with and without arc

This example is to compare the behaviour of switch models with and without an electric arc taking into consideration.

a3 and b3 are proportional to the switch currents. The difference in
the closing area shows that the simple arc model avoids the suddenly
switching.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ControlledSwitchWithArcD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc)
"""
function ControlledSwitchWithArc()
    a1 = Voltage()
    a2 = Voltage("a2")
    a3 = Voltage("a3")
    b1 = Voltage()
    b2 = Voltage("b2")
    b3 = Voltage("b3")
    vs = Voltage()
    g = 0.0
    [
        :vsrc => SineVoltage(vs, g, V = 1.0, f = 1.0)
        ## SignalVoltage(a1, g, 50.0)
        ## ControlledIdealClosingSwitch(a1, a2, vs, 0.5, 1e-5, 1e-5)
        ## Inductor(a2, a3, 0.1)
        ## Resistor(a3, g, 1.0)
        :vsrc2 => SignalVoltage(b1, g, V = 50.0)
        :ccwa => ControlledCloserWithArc(b1, b2, vs, V0 = 30.0, dVdt = 10000.0, Vmax = 60.0)
        :l1 => Inductor(b2, b3, L = 0.1)
        :r1 => Resistor(b3, g, R = 1.0)
    ]
end


function dc()
    @variables n1(t) n2(t)
    g = 0.0
    [
        :vsrc => SignalVoltage(n1, g, V = 50.0)
        :r1 => Resistor(n1, n2, R = 0.1)
        :l1 => Inductor(n2, g, L = 0.1)
    ]
end

"""
Characteristic of ideal thyristors

Two examples of thyristors are shown: the ideal thyristor and the
ideal GTO thyristor with Vknee=5.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CharacteristicThyristorsD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicThyristors)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicThyristors)
"""
function CharacteristicThyristors()
    @named n1 = Voltage()
    @named n2 = Voltage()
    @named n3 = Voltage()
    @named x = Unknown()
    sig = Discrete(false)
    g = 0.0
    [
        x - sig
        BooleanPulse(sig, width = 20.0, period = 1.0, startTime = 0.15)
        SineVoltage(n1, g, 10.0, 1.0, -0.006) 
        IdealThyristor(n1, n2, sig, 5.0)
        IdealGTOThyristor(n1, n3, sig, 0.0)
        BoolEvent(sig, t - 1.25)  
        Resistor(n2, g, 1e-3)
        Resistor(n3, g, 1e-3)
    ]
end




function docutil()
    
    template = """
        @doc+ \"\"\"
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
    

## Run the electrical examples from Examples.Lib
function run_electrical_examples()
    clpa  = sim(CauerLowPassAnalog(), 60.0)
    clpo  = sim(CauerLowPassOPV(), 60.0)
    clpo2 = sim(CauerLowPassOPV2(), 60.0)
    cid   = sim(CharacteristicIdealDiodes(), 1.0)
    cc    = sim(ChuaCircuit(), 5000.0)
    hr    = sim(HeatingResistor(), 5.0)
    svr   = sim(ShowVariableResistor(), 6.2832)
    # ct    = sim(CharacteristicThyristors(), 2.0)
    # s     = create_simstate(HeatingRectifier())
    # initialize!(s)
    # hr    = sim(s, 5.0)
    # r     = sim(Rectifier(), tstop = 0.1, alg = false)
    # cswa  = sunsim(ControlledSwitchWithArc(), tstop = 6.0, alg = false) # doesn't solve with DASSL
    ## -- Broken examples --
    ## ssi   = sim(ShowSaturatingInductor(), 6.2832)
end


