Resistor
--------

The linear resistor connects the branch voltage *v* with the branch
current *i* by *i\*R = v*. The Resistance *R* is allowed to be positive,
zero, or negative.

Arguments
~~~~~~~~~

+---------+---------------------------------------+
|         | Description                           |
+=========+=======================================+
| n1      | Positive node                         |
+---------+---------------------------------------+
| n2      | Negative node                         |
+---------+---------------------------------------+
| R       | Resistance, ohms                      |
+---------+---------------------------------------+
| hp      | Heat port                             |
+---------+---------------------------------------+
| opts    | Options (see below)                   |
+---------+---------------------------------------+

Options
~~~~~~~

+-----------+--------+----------------------------------------------------------+
| Name      | Defaul | Description                                              |
|           | t      |                                                          |
+===========+========+==========================================================+
| R         | 1.0    | Resistance at temperature T\_ref [Ohm]                   |
+-----------+--------+----------------------------------------------------------+
| T\_ref    | 300.15 | Reference temperature [K]                                |
+-----------+--------+----------------------------------------------------------+
| alpha     | 0      | Temperature coefficient of resistance (R\_actual = R\*(1 |
|           |        | + alpha\*(T\_heatPort - T\_ref)) [1/K]                   |
+-----------+--------+----------------------------------------------------------+
| T         | T\_ref | Fixed device temperature [K]                             |
+-----------+--------+----------------------------------------------------------+

Details
~~~~~~~

The resistance **R** is optionally temperature dependent according to
the following equation:

::

::

        R = R_ref*(1 + alpha*(heatPort.T - T_ref))

With the optional **hp** HeatPort argument, the power will be dissipated
into this HeatPort.

The resistance **R** can be a constant numeric value or an Unknown,
meaning it can vary with time. *Note*: it is recommended that the R
signal should not cross the zero value. Otherwise, depending on the
surrounding circuit, the probability of singularities is high.

This device is vectorizable using array inputs for one or both of **n1**
and **n2**.

See Also
~~~~~~~~

`ex\_CauerLowPassAnalog </HELP/ex_CauerLowPassAnalog>`_

Example
~~~~~~~

::

    function model()
        n1 = Voltage("n1")
        g = 0.0
        {
         SineVoltage(n1, g, 100.0)
         Resistor(n1, g, 3.0, @options(T => 330.0, alpha => 1.0))
         }
    end
    y = sim(model())

