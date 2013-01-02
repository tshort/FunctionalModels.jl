## Inductor

The linear inductor connects the branch voltage *v* with the branch
current *i* by *v = L \* di/dt*. 


### Arguments

+-----+------------------------------------+
|     | Description                        |
+=====+====================================+
| n1  | Positive node                      |
+-----+------------------------------------+
| n2  | Negative node                      |
+-----+------------------------------------+
| L   | Inductance [H]                     |
+-----+------------------------------------+

### Example

**L** can be a constant numeric value or an Unknown,
meaning it can vary with time. If **L** is a constant, it may be
positive, zero, or negative. If **L** is a signal, it should be
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
         Inductor(n1, g, 6.0)
         }
    end
