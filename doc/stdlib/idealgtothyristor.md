## IdealGTOThyristor

This is an ideal GTO thyristor model which is
 **open** (off), if the voltage drop is less than 0 or *fire* is false
 **closed** (on), if the voltage drop is greater or equal 0 and *fire* is
true.

This is the behaviour if all parameters are exactly zero.
 Note, there are circuits, where this ideal description with zero
resistance and zero cinductance is not possible. In order to prevent
singularities during switching, the opened thyristor has a small
conductance *Goff* and the closed thyristor has a low resistance *Ron*
which is default.

The parameter *Vknee* which is the forward threshold voltage, allows
to displace the knee point along the *Goff*-characteristic until *v =
Vknee*.

### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| fire       | Discrete bool variable indicating firing of the thyristor        |
+------------+------------------------------------------------------------------+
| opts       | See below                                                        |
+------------+------------------------------------------------------------------+

### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ron           | 1.E-5     | Closed thyristor resistance [Ohm]                     |
+---------------+-----------+-------------------------------------------------------+
| Goff          | 1.E-5     | Opened thyristor conductance [S]                      |
+---------------+-----------+-------------------------------------------------------+
| Vknee         | 0.0       | Forward threshold voltage [V]                         |
+---------------+-----------+-------------------------------------------------------+
