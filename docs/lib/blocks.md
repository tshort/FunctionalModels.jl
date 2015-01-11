



# Control and signal blocks

These components are modeled after the `Modelica.Blocks.*` library.





# Continuous linear




## Integrator

Output the integral of the input signals

```julia
Integrator(u::Signal, y::Signal, k = 1.0, y_start = 0.0)
Integrator(u::Signal, y::Signal; k = 1.0, y_start = 0.0) # keyword arg version
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k` : integrator gains
* `y_start` : output initial value


[Sims/src/../lib/blocks.jl:45](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L45)



## Derivative

Approximated derivative block

This blocks defines the transfer function between the input `u` and
the output `y` element-wise as the approximated derivative:

```
             k[i] * s
     y[i] = ------------ * u[i]
            T[i] * s + 1
```

If you would like to be able to change easily between different
transfer functions (FirstOrder, SecondOrder, ... ) by changing
parameters, use the general block TransferFunction instead and model a
derivative block with parameters as:

```julia
    b = [k,0]; a = [T, 1]
```

```julia
Derivative(u::Signal, y::Signal, T = 1.0, k = 1.0, x_start = 0.0, y_start = 0.0)
Derivative(u::Signal, y::Signal; T = 1.0, k = 1.0, x_start = 0.0, y_start = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k` : gains
* `T` : Time constants [sec]


[Sims/src/../lib/blocks.jl:93](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L93)



## FirstOrder

First order transfer function block (= 1 pole)

This blocks defines the transfer function between the input u=inPort.signal and the output y=outPort.signal element-wise as first order system:

```
               k[i]
     y[i] = ------------ * u[i]
            T[i] * s + 1
```

If you would like to be able to change easily between different
transfer functions (FirstOrder, SecondOrder, ... ) by changing
parameters, use the general block TransferFunction instead and model a
derivative block with parameters as:

```julia
    b = [k,0]; a = [T, 1]
```

```julia
FirstOrder(u::Signal, y::Signal, T = 1.0, k = 1.0, y_start = 0.0)
FirstOrder(u::Signal, y::Signal; T = 1.0, k = 1.0, y_start = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k` : gains
* `T` : Time constants [sec]


[Sims/src/../lib/blocks.jl:150](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L150)



## LimPID

PID controller with limited output, anti-windup compensation and setpoint weighting

```julia
LimPID(u_s::Signal, u_m::Signal, y::Signal, 
       controllerType = "PID",
       k = 1.0,      
       Ti = 1.0,    
       Td = 1.0,   
       yMax = 1.0,   
       yMin = -yMax, 
       wp = 1.0,     
       wd = 0.0,     
       Ni = 0.9,    
       Nd = 10.0,    
       xi_start = 0.0, 
       xd_start = 0.0,
       y_start = 0.0)
LimPID(u_s::Signal, u_m::Signal, y::Signal; 
       controllerType = "PID",
       k = 1.0,      
       Ti = 1.0,    
       Td = 1.0,   
       yMax = 1.0,   
       yMin = -yMax, 
       wp = 1.0,     
       wd = 0.0,     
       Ni = 0.9,    
       Nd = 10.0,    
       xi_start = 0.0, 
       xd_start = 0.0,
       y_start = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k`    : Gain of PID block                                  
* `Ti`   : Time constant of Integrator block [s]
* `Td`   : Time constant of Derivative block [s]
* `yMax` : Upper limit of output
* `yMin` : Lower limit of output
* `wp`   : Set-point weight for Proportional block (0..1)
* `wd`   : Set-point weight for Derivative block (0..1)
* `Ni`   : Ni*Ti is time constant of anti-windup compensation
* `Nd`   : The higher Nd, the more ideal the derivative block


### Details

This is a PID controller incorporating several practical aspects. It
is designed according to chapter 3 of the book:

K. Astroem, T. Haegglund: PID Controllers: Theory, Design, and
Tuning. 2nd edition, 1995.

Besides the additive proportional, integral and derivative part of
this controller, the following practical aspects are included:

* The output of this controller is limited. If the controller is in
  its limits, anti-windup compensation is activated to drive the
  integrator state to zero.

* The high-frequency gain of the derivative part is limited to avoid
  excessive amplification of measurement noise.

* Setpoint weighting is present, which allows to weight the setpoint
  in the proportional and the derivative part independantly from the
  measurement. The controller will respond to load disturbances and
  measurement noise independantly of this setting (parameters wp,
  wd). However, setpoint changes will depend on this setting. For
  example, it is useful to set the setpoint weight wd for the
  derivative part to zero, if steps may occur in the setpoint signal.


[Sims/src/../lib/blocks.jl:244](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L244)



## StateSpace

Linear state space system

Modelica.Blocks.Continuous.StateSpace
Information

The State Space block defines the relation between the input u=inPort.signal and the output y=outPort.signal in state space form:

 
 
    der(x) = A * x + B * u
        y  = C * x + D * u

The input is a vector of length nu, the output is a vector of length ny and nx is the number of states. Accordingly

        A has the dimension: A(nx,nx), 
        B has the dimension: B(nx,nu), 
        C has the dimension: C(ny,nx), 
        D has the dimension: D(ny,nu) 

Example:

```julia
     StateSpace(u, y; A = [0.12, 2; 3, 1.5], 
                      B = [2,    7; 3, 1],
                      C = [0.1, 2],
                      D = zeros(length(y),length(u)))
```

results in the following equations:

```
  [der(x[1])]   [0.12  2.00] [x[1]]   [2.0  7.0] [u[1]]
  [         ] = [          ]*[    ] + [        ]*[    ]
  [der(x[2])]   [3.00  1.50] [x[2]]   [0.1  2.0] [u[2]]

                             [x[1]]            [u[1]]
       y[1]   = [0.1  2.0] * [    ] + [0  0] * [    ]
                             [x[2]]            [u[2]]
```


```julia
StateSpace(u::Signal, y::Signal, A = [1.0], B = [1.0], C = [1.0], D = [0.0])
StateSpace(u::Signal, y::Signal; A = [1.0], B = [1.0], C = [1.0], D = [0.0])
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `A` : Matrix A of state space model
* `B` : Vector B of state space model
* `C` : Vector C of state space model
* `D` : Matrix D of state space model

### Details


### Example

```julia
```

NOTE: untested / probably broken


[Sims/src/../lib/blocks.jl:364](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L364)



## TransferFunction

Linear transfer function

This block defines the transfer function between the input
u=inPort.signal[1] and the output y=outPort.signal[1] as (nb =
dimension of b, na = dimension of a):

```
           b[1]*s^[nb-1] + b[2]*s^[nb-2] + ... + b[nb]
   y(s) = --------------------------------------------- * u(s)
           a[1]*s^[na-1] + a[2]*s^[na-2] + ... + a[na]
```

State variables x are defined according to controller canonical
form. Initial values of the states can be set as start values of x.

Example:

```julia
     TransferFunction(u, y, b = [2,4], a = [1,3])
```

results in the following transfer function:

```
        2*s + 4
   y = --------- * u
         s + 3
```

```julia
TransferFunction(u::Signal, y::Signal, b = [1], a = [1])
TransferFunction(u::Signal, y::Signal; b = [1], a = [1])
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `b` : Numerator coefficients of transfer function
* `a` : Denominator coefficients of transfer function


[Sims/src/../lib/blocks.jl:429](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L429)




# Nonlinear




## Limiter

Limit the range of a signal

The Limiter block passes its input signal as output signal as long as
the input is within the specified upper and lower limits. If this is
not the case, the corresponding limits are passed as output.

```julia
Limiter(u::Signal, y::Signal, uMax = 1.0, uMin = -uMax)
Limiter(u::Signal, y::Signal; uMax = 1.0, uMin = -uMax)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `uMax` : upper limits of signals
* `uMin` : lower limits of signals


[Sims/src/../lib/blocks.jl:490](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L490)



## Step

Generate step signals of type Real

```julia
Step(y::Signal, height = 1.0, offset = 0.0, startTime = 0.0)
Step(y::Signal; height = 1.0, offset = 0.0, startTime = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `height` : heights of steps
* `offset` : offsets of output signals
* `startTime` : output = offset for time < startTime [s]


[Sims/src/../lib/blocks.jl:528](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L528)



## DeadZone

Provide a region of zero output

The DeadZone block defines a region of zero output.

If the input is within uMin ... uMax, the output is zero. Outside of
this zone, the output is a linear function of the input with a slope
of 1.

```julia
DeadZone(u::Signal, y::Signal, uMax = 1.0, uMin = -uMax)
DeadZone(u::Signal, y::Signal; uMax = 1.0, uMin = -uMax)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `uMax` : upper limits of signals
* `uMin` : lower limits of signals


[Sims/src/../lib/blocks.jl:571](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../lib/blocks.jl#L571)

