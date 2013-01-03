## SignalVoltage

The signal voltage source is a parameterless converter of real valued
signals into a the source voltage.

This voltage source may be vectorized.

### Parameters

+--------+-------------------------------------------------------------+
| Name   | Description                                                 |
+========+=============================================================+
| p      | Positive voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| n      | Negative voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| V      | Voltage between pin p and n (= p - n) as input signal       |
+--------+-------------------------------------------------------------+

## SineVoltage

A sinusoidal voltage source. An offset parameter is introduced,
which is added to the value calculated by the blocks source. The
startTime parameter allows to shift the blocks source behavior on the
time axis.

This voltage source may be vectorized.

### Parameters

+--------+-------------------------------------------------------------+
| Name   | Description                                                 |
+========+=============================================================+
| p      | Positive voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| n      | Negative voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| opts   | See below                                                   |
+--------+-------------------------------------------------------------+

### Options

+-------------+-----------+-------------------------------+
| Name        | Default   | Description                   |
+=============+===========+===============================+
| V           | 1.0       | Amplitude of sine wave [V]    |
+-------------+-----------+-------------------------------+
| phase       | 0         | Phase of sine wave [rad]      |
+-------------+-----------+-------------------------------+
| freqHz      | 1.0       | Frequency of sine wave [Hz]   |
+-------------+-----------+-------------------------------+
| offset      | 0         | Voltage offset [V]            |
+-------------+-----------+-------------------------------+
| startTime   | 0         | Time offset [s]               |
+-------------+-----------+-------------------------------+

## StepVoltage

A step voltage source. An event is introduced at the transition.
Probably cannot be vectorized.

### Parameters

+--------+-------------------------------------------------------------+
| Name   | Description                                                 |
+========+=============================================================+
| p      | Positive voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| n      | Negative voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| opts   | See below                                                   |
+--------+-------------------------------------------------------------+

### Options

+-------------+-----------+----------------------+
| Name        | Default   | Description          |
+=============+===========+======================+
| V           | 1.0       | Height of step [V]   |
+-------------+-----------+----------------------+
| offset      | 0.0       | Voltage offset [V]   |
+-------------+-----------+----------------------+
| startTime   | 0.0       | Time offset [s]      |
+-------------+-----------+----------------------+


## SignalCurrent

The signal voltage source is a parameterless converter of real valued
signals into a the source voltage.

This voltage source may be vectorized.

### Parameters

+--------+-------------------------------------------------------------+
| Name   | Description                                                 |
+========+=============================================================+
| p      | Positive voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| n      | Negative voltage node [V]                                   |
+--------+-------------------------------------------------------------+
| I      | Current flowing from p to n as input signal                 |
+--------+-------------------------------------------------------------+
