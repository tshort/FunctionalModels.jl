## SeriesProbe

Connect a series current probe between two nodes. This is vectorizable.

### Arguments

+---------+------------------------------+
|         | Description                  |
+---------+------------------------------+
| n1      | Positive electrical node [V] |
+---------+------------------------------+
| n2      | Negative electrical node [V] |
+---------+------------------------------+
| name    | Name of the probe            |
+---------+------------------------------+


### Example

    
    function model()
        n1 = Voltage("n1")
        n2 = Voltage()
        g = 0.0
        {
         SineVoltage(n1, g, 100.0)
         SeriesProbe(n1, n2, "current")
         Resistor(n2, g, 2.0)
         }
    end
    y = sim(model())

