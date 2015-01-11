



# Sims.Lib examples

Examples using models from the Sims standard library (Sims.Lib).

Many of these are patterned after the examples in the Modelica
Standard Library.

These are available in **Sims.Examples.Lib**. Here is an example of use:

```julia
using Sims
m = Sims.Examples.Lib.ChuaCircuit()
z = sim(m, 5000.0)

using Winston
wplot(z)
```





# Blocks




## PID_Controller

Demonstrates the usage of a Continuous.LimPID controller


This is a simple drive train controlled by a PID controller:

* The two blocks "kinematic_PTP" and "integrator" are used to generate
  the reference speed (= constant acceleration phase, constant speed
  phase, constant deceleration phase until inertia is at rest). To
  check whether the system starts in steady state, the reference speed
  is zero until time = 0.5 s and then follows the sketched trajectory.

* The block "PI" is an instance of "Blocks.Continuous.LimPID" which is
  a PID controller where several practical important aspects, such as
  anti-windup-compensation has been added. In this case, the control
  block is used as PI controller.

* The output of the controller is a torque that drives a motor inertia
  "inertia1". Via a compliant spring/damper component, the load
  inertia "inertia2" is attached. A constant external torque of 10 Nm
  is acting on the load inertia.

Key parameters for plotting are:

* s2 - output of the integrator
* s3 - speed sensor on inertia1

* s4 - output of the PI control
* s5 - speed sensor on inertia2

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Blocks.Examples.PID_ControllerD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Blocks_Examples.html#Modelica.Blocks.Examples.PID_Controller)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Blocks_Examples.html#Modelica.Blocks.Examples.PID_Controller)

[Sims/src/../examples/lib/blocks.jl:49](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/blocks.jl#L49)




# Electrical




## CauerLowPassAnalog

Cauer low-pass filter with analog components

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network. The voltage source on `n1` is the
input voltage (step), and `n4` is the filter output voltage. The
pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassAnalogD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)

[Sims/src/../examples/lib/electrical.jl:39](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L39)



## CauerLowPassOPV

Cauer low-pass filter with operational amplifiers

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network with op amps. The voltage source
on `n[1]` is the input voltage (step), and `n[10]` is the filter output
voltage. The pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassOPVD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)

[Sims/src/../examples/lib/electrical.jl:79](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L79)



## CauerLowPassOPV2

Cauer low-pass filter with operational amplifiers (alternate implementation)

The example Cauer Filter is a low-pass-filter of the fifth order. It
is realized using an analog network with op amps. The voltage source
on `n1` is the input voltage (step), and `n10` is the filter output
voltage. The pulse response is calculated.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CauerLowPassOPVD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CauerLowPassOPV)

[Sims/src/../examples/lib/electrical.jl:132](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L132)



## CharacteristicIdealDiodes

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

[Sims/src/../examples/lib/electrical.jl:215](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L215)



## ChuaCircuit

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

[Sims/src/../examples/lib/electrical.jl:270](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L270)



## HeatingResistor

Heating resistor

This is a very simple circuit consisting of a voltage source and a
resistor. The loss power in the resistor is transported to the
environment via its heatPort.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.HeatingResistorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingResistor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingResistor)

[Sims/src/../examples/lib/electrical.jl:313](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L313)



## HeatingRectifier

Heating rectifier

The heating rectifier shows a heat flow always if the electrical
capacitor is loaded. 

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.HeatingRectifierD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingRectifier)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.HeatingRectifier)

NOTE: CURRENTLY UNFINISHED

[Sims/src/../examples/lib/electrical.jl:340](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L340)



## Rectifier

B6 diode bridge

The rectifier example shows a B6 diode bridge fed by a three phase
sinusoidal voltage, loaded by a DC current. DC capacitors start at
ideal no-load voltage, thus making easier initial transient.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.RectifierD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.Rectifier)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.Rectifier)

NOTE: CURRENTLY BROKEN

[Sims/src/../examples/lib/electrical.jl:403](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L403)



## ShowSaturatingInductor

Simple demo to show behaviour of SaturatingInductor component

This simple circuit uses the saturating inductor which has a changing
inductivity.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ShowSaturatingInductorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowSaturatingInductor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowSaturatingInductor)

NOTE: CURRENTLY BROKEN

[Sims/src/../examples/lib/electrical.jl:462](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L462)



## ShowVariableResistor

Simple demo of a VariableResistor model

It is a simple test circuit for the VariableResistor. The
VariableResistor sould be compared with R2. `isig1` and `isig2` are
current monitors

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ShowVariableResistorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowVariableResistor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ShowVariableResistor)

[Sims/src/../examples/lib/electrical.jl:545](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L545)



## ControlledSwitchWithArc

Comparison of controlled switch models both with and without arc

This example is to compare the behaviour of switch models with and without an electric arc taking into consideration.

a3 and b3 are proportional to the switch currents. The difference in
the closing area shows that the simple arc model avoids the suddenly
switching.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.ControlledSwitchWithArcD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.ControlledSwitchWithArc)

[Sims/src/../examples/lib/electrical.jl:586](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L586)



## CharacteristicThyristors

Characteristic of ideal thyristors

Two examples of thyristors are shown: the ideal thyristor and the
ideal GTO thyristor with Vknee=5.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Electrical.Analog.Examples.CharacteristicThyristorsD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicThyristors)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Electrical_Analog_Examples.html#Modelica.Electrical.Analog.Examples.CharacteristicThyristors)

[Sims/src/../examples/lib/electrical.jl:642](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L642)



## run_electrical_examples

Run the electrical examples from Examples.Lib

[Sims/src/../examples/lib/electrical.jl:734](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/electrical.jl#L734)




# Heat transfer




## TwoMasses

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

[Sims/src/../examples/lib/heat_transfer.jl:30](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/heat_transfer.jl#L30)



## Motor

Second order thermal model of a motor

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Thermal.HeatTransfer.Examples.MotorD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.Motor)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Thermal_HeatTransfer_Examples.html#Modelica.Thermal.HeatTransfer.Examples.Motor)

[Sims/src/../examples/lib/heat_transfer.jl:49](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/heat_transfer.jl#L49)




# Power systems




## RLModel

Three-phase RL line model

See also sister models: PiModel and ModalModal.

WARNING: immature / possibly broken!


[Sims/src/../examples/lib/powersystems.jl:19](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/powersystems.jl#L19)



## PiModel

Three-phase Pi line model

See also sister models: RLModel and ModalModal.

WARNING: immature / possibly broken!


[Sims/src/../examples/lib/powersystems.jl:53](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/powersystems.jl#L53)



## ModalModel

Three-phase modal line model

See also sister models: PiModel and RLModal.

WARNING: immature / possibly broken!


[Sims/src/../examples/lib/powersystems.jl:104](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/powersystems.jl#L104)




# Rotational




## First

First example: simple drive train

The drive train consists of a motor inertia which is driven by a
sine-wave motor torque. Via a gearbox the rotational energy is
transmitted to a load inertia. Elasticity in the gearbox is modeled by
a spring element. A linear damper is used to model the damping in the
gearbox bearing.

Note, that a force component (like the damper of this example) which
is acting between a shaft and the housing has to be fixed in the
housing on one side via component Fixed.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Mechanics.Rotational.Examples.FirstD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Mechanics_Rotational_Examples.html#Modelica.Mechanics.Rotational.Examples.First)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Mechanics_Rotational_Examples.html#Modelica.Mechanics.Rotational.Examples.First)

[Sims/src/../examples/lib/rotational.jl:33](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/lib/rotational.jl#L33)

