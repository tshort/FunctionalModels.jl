# Analog electrical library

This library of components is modeled after the
Modelica.Electrical.Analog library.

Voltage nodes with type *Voltage* are the main Unknown type used in
electrical circuits. *Voltage* nodes can be single floating point
unknowns representing a single voltage node. A *Voltage* can also be
an array representing multiphase circuits or multiple node positions.
Lastly, *Voltage* unknowns can also be complex for use with
quasiphasor-type solutions.

The type *ElectricalNode* is a Union type that can be an Array, a
number, an expression, or an Unknown. This is used in model functions
to allow passing a *Voltage* node or a real value (like 0.0 for
ground).

## Example

```jul
function ex_ChuaCircuit()
    n1 = Voltage("n1")
    n2 = Voltage("n2")
    n3 = Voltage(4.0, "n3")
    g = 0.0
    function NonlinearResistor(n1::ElectricalNode, n2::ElectricalNode, Ga, Gb, Ve)
        i = Current(compatible_values(n1, n2))
        v = Voltage(compatible_values(n1, n2))
        {
         Branch(n1, n2, v, i)
         i - ifelse(v < -Ve, Gb .* (v + Ve) - Ga .* Ve,
                    ifelse(v > Ve, Gb .* (v - Ve) + Ga*Ve, Ga*v))
         }
    end
    {
     Resistor(n1, g, 12.5e-3) 
     Inductor(n1, n2, 18.0)
     Resistor(n2, n3, 1 / 0.565) 
     Capacitor(n2, g, 100.0)
     Capacitor(n3, g, 10.0)
     NonlinearResistor(n3, g, -0.757576, -0.409091, 1.0)
     }
end

function sim_ChuaCircuit()
    y = sim(ex_ChuaCircuit(), 200.0)
    wplot(y, "ChuaCircuit.pdf")
end
```


## Components

Help is available for each of the following components

- SeriesProbe 
- BranchHeatPort
- Resistor
- Capacitor
- Inductor
- Transformer
- EMF       
- IdealDiode
- IdealThyristor   
- IdealGTOTyristor
- IdealOpAmp     
- ControlledIdealOpeningSwitch 
- ControlledIdealClosingSwitch
- ControlledOpenerWithArc    
- ControlledCloserWithArc   
- Diode         
- HeatingDiode  
- SignalVoltage 
- SineVoltage   
- StepVoltage   
- SignalCurrent 
