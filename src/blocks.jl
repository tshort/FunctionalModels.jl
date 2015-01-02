
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


function Integrator(u::Signal, y::Signal, k::Real)
    @equations begin
        der(y) = k .* u
    end
end

function Integrator(u::Signal, y::Signal, 
                    k = 1.0,       # Gain
                    y_start = 0.0) # output initial value
    y.value = y_start
    @equations begin
        der(y) = k .* u
    end
end
Integrator(u::Signal, y::Signal) = Integrator(u, y, 1.0)

function Derivative(u::Signal, y::Signal, k::Real, T::Real)
    x = Unknown()  # state of the block
    zeroGain = abs(k) < eps()
    @equations begin
        der(x) = zeroGain ? 0 : (u - x) ./ T
        y = zeroGain ? 0 : (k ./ T) .* (u - x)
    end
end

function Derivative(u::Signal, y::Signal, 
                    T = 1.0,   # pole's time constant
                    k = 1.0,   # Gain
                    x_start = 0.0, # initial value of state
                    y_start = 0.0) # output initial value
    y.value = y_start
    x = Unknown(x_start)  # state of the block
    zeroGain = abs(k) < eps()
    @equations begin
        der(x) = zeroGain ? 0 : (u - x) ./ T
        y = zeroGain ? 0 : (k ./ T) .* (u - x)
    end
end
Derivative(u::Signal, y::Signal; 
           T = 1.0,
           k = 1.0,
           x_start = 0.0,
           y_start = 0.0) = Derivative(u, y, T, k, x_start, y_start)

function FirstOrder(u::Signal, y::Signal,
                    T = 1.0,       # pole's time constant
                    k = 1.0,       # Gain
                    y_start = 0.0) # output initial value
    y.value = y_start
    @equations begin
        y + T*der(y) = k*u
    end
end
FirstOrder(u::Signal, y::Signal;
           T = 1.0,
           k = 1.0,
           y_start = 0.0) = FirstOrder(u, T, k, y_start)

           
function LimPID(u_s::Signal, u_m::Signal, y::Signal, 
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
    x = Unknown(xi_start)  # node just in front of the limiter
    d = Unknown(xd_start)  # input of derivative block
    D = Unknown()  # output of derivative block
    i = Unknown()  # input of integrator block
    I = Unknown()  # output of integrator block
    zeroGain = abs(k) < eps()
    @equations begin
        i = u_s - u_m + (y - x) / (k * Ni)
        with_I ? Integrator(i, I, 1/Ti) : Equation[]
        with_D ? Derivative(d, D, Td, max(Td/Nd, 1e-14)) : Equation[]
        d = u_s - u_m
        Limiter(x, y, yMax, yMin)
        x = k * ((with_I ? I : 0.0) + (with_D ? D : 0.0) + u_s - u_m)
    end
end

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
    LimPID(u_s, u_m, y, controllerType, k, Ti, Td, yMax, yMin, wp, wd, Ni, Nd, xi_start, xd_start, y_start)
end


# Warning: untested
function StateSpace(u::Signal, y::Signal, 
                    A = [1.0],
                    B = [1.0],
                    C = [1.0],
                    D = [0.0])
    x = Unknown(zeros(size(A, 1)))  # state vector
    @equations begin
        der(x) = A * x + B * u
        y      = C * x + D * u
    end
end
StateSpace(u::Signal, y::Signal; 
           A = [1.0],
           B = [1.0],
           C = [1.0],
           D = [0.0]) = StateSpace(u, y, A, B, C, D)

function TransferFunction(u::Signal, y::Signal, 
                          b = [1],  # Numerator; 2*s + 3 is specified as [2,3]
                          a = [1])  # Denominator
    na = length(a)
    nb = length(b)
    nx = length(a) - 1
    bb = [zeros(max(0, na - nb)), b]
    d = bb[1] / a[1]
    a_end = (a[end] > 100 * eps() * sqrt(a' * a)[1]) ? a[end] : 1.0
    
    x = Unknown(zeros(nx))
    x_scaled = Unknown(zeros(nx))
    
    if nx == 0
        y - d * u
    else
        @equations begin
            der(x_scaled[1]) = (dot(-a[2:na], x_scaled) + a_end * u) / a[1]
            der(x_scaled[2:nx]) = x_scaled[1:nx-1]
            y = dot(bb[2:na] - d * a[2:na], x_scaled) / a_end + d * u
            x = x_scaled / a_end
        end
    end
end
TransferFunction(u::Signal, y::Signal, 
                 b = [1],
                 a = [1]) = TransferFunction(u, y, b, a)


########################################
## Nonlinear Blocks
########################################



## function Limiter(u::Signal, y::Signal, uMax::Real, uMin::Real)
##     @equations begin
##         y = ifelse(u > uMax, uMax,
##                    ifelse(u < uMin, uMin,
##                           u))
##     end
## end

function Limiter(u::Signal, y::Signal, 
                 uMax = 1.0,
                 uMin = -uMax)
    clamped_pos = Discrete(false)
    clamped_neg = Discrete(false)
    @equations begin
        BoolEvent(clamped_pos, u - uMax)
        BoolEvent(clamped_neg, uMin - u)
        y = ifelse(clamped_pos, uMax,
                   ifelse(clamped_neg, uMin, u))
    end
end
Limiter(u::Signal, y::Signal; 
        uMax = 1.0,
        uMin = -uMax) = Limiter(u, y, uMax, uMin)
VariableLimiter = Limiter

function Step(y::Signal, 
              height = 1.0,
              offset = 0.0, 
              startTime = 0.0)
    ymag = Discrete(offset)
    @equations begin
        y = ymag  
        Event(MTime - startTime,
              Equation[reinit(ymag, offset + height)],   # positive crossing
              Equation[reinit(ymag, offset)])            # negative crossing
    end
end
Step(y::Signal; 
     height = 1.0,
     offset = 0.0, 
     startTime = 0.0) = Step(y, height, offset, startTime)

function DeadZone(u::Signal, y::Signal, 
                  uMax = 1.0,
                  uMin = -uMax)
    pos = Discrete(false)
    neg = Discrete(false)
    @equations begin
        BoolEvent(pos, u - uMax)
        BoolEvent(neg, uMin - u)
        y = ifelse(pos, u - uMax,
                   ifelse(neg, u - uMin,
                          0.0))
    end
end
DeadZone(u::Signal, y::Signal; 
         uMax = 1.0,
         uMin = -uMax) = DeadZone(u, y, uMax, uMin)

