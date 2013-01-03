## Diode

This is an ideal switch which is **open** (off), if it is reversed
biased (voltage drop less than 0) **closed** (on), if it is conducting
(current > 0). This is the behaviour if all parameters are exactly
zero. Note, there are circuits, where this ideal description with zero
resistance and zero cinductance is not possible. In order to prevent
singularities during switching, the opened diode has a small
conductance *Gon* and the closed diode has a low resistance *Roff*
which is default.

The parameter *Vknee* which is the forward threshold voltage, allows
to displace the knee point along the *Gon*-characteristic until *v =
Vknee*. 


### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| opts       | See below                                                        |
+------------+------------------------------------------------------------------+

### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ron           | 1.E-5     | Closed diode resistance [Ohm]                         |
+---------------+-----------+-------------------------------------------------------+
| Goff          | 1.E-5     | Opened diode conductance [S]                          |
+---------------+-----------+-------------------------------------------------------+
| Vknee         | 0.0       | Forward threshold voltage [V]                         |
+---------------+-----------+-------------------------------------------------------+
