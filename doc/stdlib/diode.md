## Diode

The simple diode is a one port. It consists of the diode itself and an
parallel ohmic resistance *R*. The diode formula is:

                    v/vt
      i  =  ids ( e      - 1).

If the exponent *v/vt* reaches the limit *maxex*, the diode
characterisic is linearly continued to avoid overflow.


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
| Ids           | 1.e-6     | Saturation current [A]                                |
+---------------+-----------+-------------------------------------------------------+
| Vt            | 0.04      | Voltage equivalent of temperature (kT/qn) [V]         |
+---------------+-----------+-------------------------------------------------------+
| Maxexp        | 15        | Max. exponent for linear continuation                 |
+---------------+-----------+-------------------------------------------------------+
| R             | 1.e8      | Parallel ohmic resistance [Ohm]                       |
+---------------+-----------+-------------------------------------------------------+

## HeatingDiode


The simple diode is an electrical one port, where a heat port is added,
which is defined in the Thermal library. It consists of the
diode itself and an parallel ohmic resistance *R*. The diode formula is:

                    v/vt_t
      i  =  ids ( e        - 1).

where vt\_t depends on the temperature of the heat port:

      vt_t = k*temp/q

If the exponent *v/vt\_t* reaches the limit *maxex*, the diode
characterisic is linearly continued to avoid overflow. The thermal
power is calculated by *i\*v*.


### Parameters

+------------+------------------------------------------------------------------+
| Name       | Description                                                      |
+============+==================================================================+
| p          | Positive pin (potential p > n for positive voltage drop v)       |
+------------+------------------------------------------------------------------+
| n          | Negative pin                                                     |
+------------+------------------------------------------------------------------+
| T          | Heat port                                                        |
+------------+------------------------------------------------------------------+
| opts       | See below                                                        |
+------------+------------------------------------------------------------------+

### Options

+---------------+-----------+-------------------------------------------------------+
| Name          | Default   | Description                                           |
+===============+===========+=======================================================+
| Ids           | 1.e-6     | Saturation current [A]                                |
+---------------+-----------+-------------------------------------------------------+
| Maxexp        | 15        | Max. exponent for linear continuation                 |
+---------------+-----------+-------------------------------------------------------+
| R             | 1.e8      | Parallel ohmic resistance [Ohm]                       |
+---------------+-----------+-------------------------------------------------------+
| EG            | 1.11      | activation energy                                     |
+---------------+-----------+-------------------------------------------------------+
| N             | 1         | Emission coefficient                                  |
+---------------+-----------+-------------------------------------------------------+
| TNOM          | 300.15    | Parameter measurement temperature [K]                 |
+---------------+-----------+-------------------------------------------------------+
| XTI           | 3         | Temperature exponent of saturation current            |
+---------------+-----------+-------------------------------------------------------+


