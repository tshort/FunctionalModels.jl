## Capacitor

The linear capacitor connects the branch voltage *v* with the branch
current *i* by *i = C \* dv/dt*. 


### Arguments

+-----+------------------------------------+
|     | Description                        |
+=====+====================================+
| n1  | Positive node                      |
+-----+------------------------------------+
| n2  | Negative node                      |
+-----+------------------------------------+
| C   | Capacitance [F]                    |
+-----+------------------------------------+

### Details

**C** can be a constant numeric value or an Unknown,
meaning it can vary with time. If **C** is a constant, it may be
positive, zero, or negative. If **C** is a signal, it should be
greater than zero.

This device is vectorizable using array inputs for one or both of
**n1** and **n2**.

### Example

    
    function model()
        n1 = Voltage("n1")
        g = 0.0
        {
         SineVoltage(n1, g, 100.0)
         Resistor(n1, g, 3.0)
         Capacitor(n1, g, 1.0)
         }
    end
