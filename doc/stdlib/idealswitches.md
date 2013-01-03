## ControlledIdealOpeningSwitch

The ideal opening switch has a positive pin *p* and a negative pin *n*. The
switching behaviour is controlled by the input signal *control*. If
control is true, pin p is not connected with negative pin n. Otherwise,
pin p is connected with negative pin n.

In order to prevent singularities during switching, the opened switch
has a (very low) conductance *Goff* and the closed switch has a (very low)
resistance *Ron*. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.


### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| control    | true => switch open, false => p--n connected                     |
+------------+------------------------------------------------------------------+


### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ron           | 1.E-5     | Closed switch resistance [Ohm]                        |
+---------------+-----------+-------------------------------------------------------+
| Goff          | 1.E-5     | Opened switch conductance [S]                         |
+---------------+-----------+-------------------------------------------------------+

## ControlledIdealClosingSwitch

The ideal closing switch has a positive pin *p* and a negative pin *n*. The
switching behaviour is controlled by input signal *control*. If control is
true, pin p is connected with negative pin n. Otherwise, pin p is not
connected with negative pin n.

In order to prevent singularities during switching, the opened switch
has a (very low) conductance *Goff* and the closed switch has a (very low)
resistance *Ron*. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.


### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| control    | true => switch open, false => p--n connected                     |
+------------+------------------------------------------------------------------+


### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ron           | 1.E-5     | Closed switch resistance [Ohm]                        |
+---------------+-----------+-------------------------------------------------------+
| Goff          | 1.E-5     | Opened switch conductance [S]                         |
+---------------+-----------+-------------------------------------------------------+

## ControlledIdealClosingSwitch

The ideal closing switch has a positive pin *p* and a negative pin *n*. The
switching behaviour is controlled by input signal *control*. If control is
true, pin p is connected with negative pin n. Otherwise, pin p is not
connected with negative pin n.

In order to prevent singularities during switching, the opened switch
has a (very low) conductance *Goff* and the closed switch has a (very low)
resistance *Ron*. The limiting case is also allowed, i.e., the resistance
Ron of the closed switch could be exactly zero and the conductance Goff
of the open switch could be also exactly zero. Note, there are circuits,
where a description with zero Ron or zero Goff is not possible.


### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| control    | true => switch open, false => p--n connected                     |
+------------+------------------------------------------------------------------+


### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ron           | 1.E-5     | Closed switch resistance [Ohm]                        |
+---------------+-----------+-------------------------------------------------------+
| Goff          | 1.E-5     | Opened switch conductance [S]                         |
+---------------+-----------+-------------------------------------------------------+

## ControlledOpenerWithArc
## ControlledCloserWithArc

This model is an extension to the `IdealOpeningSwitch`.

The basic model interupts the current through the switch in an
infinitesimal time span. If an inductive circuit is connected, the
voltage across the swicth is limited only by numerics. In order to give
a better idea for the voltage across the switch, a simple arc model is
added:

When the Boolean input ``control`` signals to open the switch, a voltage
across the opened switch is impressed. This voltage starts with ``V0``
(simulating the voltage drop of the arc roots), then rising with slope
``dVdt`` (simulating the rising voltage of an extending arc) until a
maximum voltage ``Vmax`` is reached.

::

         | voltage
    Vmax |      +-----
         |     /
         |    /
    V0   |   +
         |   |
         +---+-------- time

This arc voltage tends to lower the current following through the
switch; it depends on the connected circuit, when the arc is quenched.
Once the arc is quenched, i.e., the current flowing through the switch
gets zero, the equation for the off-state is activated ``i=Goff*v``.

When the Boolean input ``control`` signals to close the switch again,
the switch is closed immediately, i.e., the equation for the on-state is
activated ``v=Ron*i``.

Please note: In an AC circuit, at least the arc quenches when the next
natural zero-crossing of the current occurs. In a DC circuit, the arc
will not quench if the arc voltage is not sufficient that a
zero-crossing of the current occurs.

### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| control    | Switch open/close signal                                         |
+------------+------------------------------------------------------------------+

### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ron           | 1E-5      | Closed switch resistance [Ohm]                        |
+---------------+-----------+-------------------------------------------------------+
| Goff          | 1E-5      | Opened switch conductance [S]                         |
+---------------+-----------+-------------------------------------------------------+
| V0            | 30.0      | Initial arc voltage [V]                               |
+---------------+-----------+-------------------------------------------------------+
| dVdt          | 10e3      | Arc voltage slope [V/s]                               |
+---------------+-----------+-------------------------------------------------------+
| Vmax          | 60.0      | Max. arc voltage [V]                                  |
+---------------+-----------+-------------------------------------------------------+
