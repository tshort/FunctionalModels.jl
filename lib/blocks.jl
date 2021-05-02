
########################################
## Continuous Blocks
########################################

# What we really need here is something like:
#  Continuous(u::Signal, y::Signal, ss::ContinuousType)
# so a user could use:
#    Continuous(u, y, SS.TransferFunction(a,b))
# or
#    Continuous(u, y, SS.StateSpace(a,b,c,d))
# A discrete counterpart could look like:
#    DiscreteBlock(u, y, Ts, SS.TransferFunction(a,b)) # fuzzy


"""
# Control and signal blocks

These components are modeled after the `Modelica.Blocks.*` library.
"""
@comment 


"""
## Continuous linear
"""
@comment 



"""
Output the integral of the input signals

```julia
Integrator(u::Signal, y::Signal; k = 1.0, y_start = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k` : integrator gains
* `y_start` : output initial value

"""
function Integrator(u::Signal, y::Signal; 
                    k = 1.0,       # Gain
                    y_start = 0.0) # output initial value
    y.value = y_start
    [
        der(y) ~ k .* u
    ]
end


"""
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
Derivative(u::Signal, y::Signal; T = 1.0, k = 1.0, x_start = 0.0, y_start = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k` : gains
* `T` : Time constants [sec]

"""
function Derivative(u::Signal, y::Signal;
                    T,         # pole's time constant
                    k = 1.0,   # Gain
                    x_start = 0.0, # initial value of state
                    y_start = 0.0) # output initial value
    y.value = y_start
    x = Unknown(x_start)  # state of the block
    zeroGain = abs(k) < eps()
    [
        der(x) ~ zeroGain ? 0 : (u - x) ./ T
        y ~ zeroGain ? 0 : (k ./ T) .* (u - x)
    ]
end



"""
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
FirstOrder(u::Signal, y::Signal; T = 1.0, k = 1.0, y_start = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `k` : gains
* `T` : Time constants [sec]

"""
function FirstOrder(u::Signal, y::Signal;
                    T = 1.0,       # pole's time constant
                    k = 1.0,       # Gain
                    y_start = 0.0) # output initial value
    y.value = y_start
    [
        der(y) ~ (k*u - y) / T
    ]
end

           
"""
PID controller with limited output, anti-windup compensation and setpoint weighting

![diagram](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica.Blocks.Continuous.LimPIDD.png)

```julia
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

* `u_s::Signal` : input setpoint
* `u_m::Signal` : input measurement
* `y_s::Signal` : output

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

"""
function LimPID(u_s::Signal, u_m::Signal, y::Signal; 
                controllerType = "PID",
                k = 1.0,      # Gain of controller
                Ti = 1.0,     # Time constant fo the Integrator block, s 
                Td = 1.0,     # Time constant fo the Derivative block, s 
                yMax = 1.0,   # Upper limit of the output
                yMin = -yMax, # Lower limit of the output
                wp = 1.0,     # Set-point weight for the Proportional block [0..1]
                wd = 0.0,     # Set-point weight for the Derivative block [0..1]
                Ni = 0.9,     # Ni * Ti is the time constant of the anti-windup compensation
                Nd = 10.0,    # The higher Nd, the more ideal the derivative block
                xi_start = 0.0, # initial value of state
                xd_start = 0.0, # initial value of state
                y_start = 0.0)  # output initial value
    with_I = any(controllerType .== ["PI", "PID"])
    with_D = any(controllerType .== ["PD", "PID"])
    @named x = Unknown(xi_start)  # node just in front of the limiter
    @named d = Unknown(xd_start)  # input of derivative block
    @named D = Unknown()  # output of derivative block
    @named i = Unknown()  # input of integrator block
    @named I = Unknown()  # output of integrator block
    zeroGain = abs(k) < eps()
    [
        i ~ u_s - u_m + (y - x) / (k * Ni)
        with_I ? Integrator(i, I, 1/Ti) : []
        with_D ? Derivative(d, D, Td, max(Td/Nd, 1e-14)) : []
        d ~ wd * u_s - u_m
        Limiter(x, y, yMax, yMin)
        x ~ k * ((with_I ? I : 0.0) + (with_D ? D : 0.0) + wp * u_s - u_m)
    ]
end


"""
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


NOTE: untested / probably broken

"""
function StateSpace(u::Signal, y::Signal; 
                    A = [1.0],
                    B = [1.0],
                    C = [1.0],
                    D = [0.0])
    x = Unknown(zeros(size(A, 1)))  # state vector
    [
        der(x) ~ A * x + B * u
        y      ~ C * x + D * u
    ]
end



"""
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
TransferFunction(u::Signal, y::Signal; b = [1], a = [1])
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `b` : Numerator coefficients of transfer function
* `a` : Denominator coefficients of transfer function

"""
function TransferFunction(u::Signal, y::Signal;
                          b,        # Numerator; 2*s + 3 is specified as [2,3]
                          a = [1])  # Denominator
    na = length(a)
    nb = length(b)
    nx = length(a) - 1
    bb = [zeros(max(0, na - nb)), b]
    d = bb[1] / a[1]
    a_end = (a[end] > 100 * eps() * sqrt(a' * a)[1]) ? a[end] : 1.0
    
    x = Unknown(zeros(nx))
    x_scaled = Unknown(zeros(nx))
    
    ;if nx == 0
        [y ~ d * u]
    else
        [
            der(x_scaled[1]) ~ (dot(-a[2:na], x_scaled) + a_end * u) / a[1]
            der(x_scaled[2:nx]) ~ x_scaled[1:nx-1]
            y ~ dot(bb[2:na] - d * a[2:na], x_scaled) / a_end + d * u
            x ~ x_scaled / a_end
        ]
    end
end


########################################
## Nonlinear Blocks
########################################
"""
## Nonlinear
"""
@comment 




"""
Limit the range of a signal

The Limiter block passes its input signal as output signal as long as
the input is within the specified upper and lower limits. If this is
not the case, the corresponding limits are passed as output.

```julia
Limiter(u::Signal, y::Signal; uMax = 1.0, uMin = -uMax)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `uMax` : upper limits of signals
* `uMin` : lower limits of signals

"""
function Limiter(u::Signal, y::Signal; 
                 uMax,
                 uMin = -uMax)
    clamped_pos = Discrete(false)
    clamped_neg = Discrete(false)
    [
        BoolEvent(clamped_pos, u - uMax)
        BoolEvent(clamped_neg, uMin - u)
        y ~ ifelse(clamped_pos, uMax,
                   ifelse(clamped_neg, uMin, u))
    ]
end
const VariableLimiter = Limiter


"""
Generate step signals of type Real

```julia
Step(y::Signal; height = 1.0, offset = 0.0, startTime = 0.0)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `height` : heights of steps
* `offset` : offsets of output signals
* `startTime` : output = offset for time < startTime [s]

"""
function Step(y::Signal; 
              height = 1.0,
              offset = 0.0, 
              startTime = 0.0)
    # ymag = Discrete(offset)
    [
        y ~ ifelse(t > startTime, offset, 0.0)  
        # Event(t - startTime,
        #       [reinit(ymag, offset + height)],   # positive crossing
        #       [reinit(ymag, offset)])            # negative crossing
    ]
end


"""
Provide a region of zero output

The DeadZone block defines a region of zero output.

If the input is within uMin ... uMax, the output is zero. Outside of
this zone, the output is a linear function of the input with a slope
of 1.

```julia
DeadZone(u::Signal, y::Signal; uMax = 1.0, uMin = -uMax)
```

### Arguments

* `u::Signal` : input
* `y::Signal` : output

### Keyword/Optional Arguments

* `uMax` : upper limits of signals
* `uMin` : lower limits of signals

"""
function DeadZone(u::Signal, y::Signal;
                  uMax = 1.0,
                  uMin = -uMax)
    pos = Discrete(false)
    neg = Discrete(false)
    [
        BoolEvent(pos, u - uMax)
        BoolEvent(neg, uMin - u)
        y ~ ifelse(pos, u - uMax,
                   ifelse(neg, u - uMin,
                          0.0))
    ]
end


"""
Generate a Discrete boolean pulse signal

```julia
BooleanPulse(y; width = 50.0, period = 1.0, startTime = 0.0)
```

### Arguments

* `y::Signal` : output signal

### Keyword/Optional Arguments

* `width` : width of pulse in the percent of period [0 - 100]
* `period` : time for one period [sec]
* `startTime` : time instant of the first pulse [sec]

"""
function BooleanPulse(x; width, period = 1.0, startTime = 0.0)
    [BoolEvent(x, ifelse(t > startTime,
                        trianglewave(t - startTime, width, period),
                        -1.0))]
end
    

function Pulse(d; amplitude, width = 50.0, period = 1.0, offset = 0.0, startTime = 0.0)
    [
        Event(ifelse(t > startTime,
                     trianglewave(t - startTime, width, period),
                     -1.0),
              reinit(d, amplitude + offset),
              reinit(d, offset))
    ]
end
    
## function Pulse(x, amplitude = 1.0, width = 50.0, period = 1.0, offset = 0.0, startTime = 0.0)
##     b = Discrete(false)
##     [
##         BooleanPulse(b, width, period, startTime)
##         x = ifelse(b, amplitude + offset, offset)
##     end
## end
## Pulse(x; amplitude = 1.0, width = 50.0, period = 1.0, offset = 0.0, startTime = 0.0) =
##     Pulse(x, amplitude, width, period, offset, startTime)
    

function trianglewave(t, width, a)
    # handle offset:
    t = t - (width - 100) / 200 * a
    y = 2 * abs(2 * (t/a - floor(t/a + 1/2))) - 2 * (100 - width) / 100
end
