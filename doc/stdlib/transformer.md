
## Transformer

The transformer is a two port. The left port voltage *v1*, left port
current *i1*, right port voltage *v2* and right port current *i2* are
connected by the following relation:

    | v1 |         | L1   M  |  | i1' |
    |    |    =    |         |  |     |
    | v2 |         | M    L2 |  | i2' |

*L1*, *L2*, and *M* are the primary, secondary, and coupling inductances
respectively.

### Arguments

+------+---------------------------------------------------------------------------------+
| Name | Description                                                                     |
+------+---------------------------------------------------------------------------------+
| p1   | Positive pin of the left port (potential p1 > n1 for positive voltage drop v1)  |
+------+---------------------------------------------------------------------------------+
| n1   | Negative pin of the left port                                                   |
+------+---------------------------------------------------------------------------------+
| p2   | Positive pin of the right port (potential p2 > n2 for positive voltage drop v2) |
+------+---------------------------------------------------------------------------------+
| n2   | Negative pin of the right port                                                  |
+------+---------------------------------------------------------------------------------+
| opts | Options (see below)                                                             |
+------+---------------------------------------------------------------------------------+

### Options

+--------+-----------+----------------------------+
| Name   | Default   | Description                |
+========+===========+============================+
| L1     | 1.0       | Primary inductance [H]     |
+--------+-----------+----------------------------+
| L2     | 1.0       | Secondary inductance [H]   |
+--------+-----------+----------------------------+
| M      | 1.0       | Coupling inductance [H]    |
+--------+-----------+----------------------------+


