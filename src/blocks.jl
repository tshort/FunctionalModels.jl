
########################################
## Continuous Blocks
########################################


function Integrator(u::Signal, y::Signal, k::Real)
    {
     der(y) - k .* u
     }
end


function Derivative(u::Signal, y::Signal, k::Real, T::Real)
    x = Unknown()  # state of the block
    zeroGain = abs(k) < eps()
    {
     der(x) - (zeroGain ? 0 : (u - x) ./ T)
     y - (zeroGain ? 0 : (k ./ T) .* (u - x))
     }
end


function LimPID(u_s::Signal, u_m::Signal, y::Signal,
                controllerType::String,
                k::Real, Ti::Real, Td::Real, yMax::Real, yMin::Real, wp::Real, wd::Real, Ni::Real, Nd::Real)
    with_I = any(controllerType .== ["PI", "PID"])
    with_D = any(controllerType .== ["PD", "PID"])
    x = Unknown()  # node just in front of the limiter
    d = Unknown()  # input of derivative block
    D = Unknown()  # output of derivative block
    i = Unknown()  # input of integrator block
    I = Unknown()  # output of integrator block
    zeroGain = abs(k) < eps()
    {
     u_s - u_m + (y - x) / (k * Ni) - i
     with_I ? Integrator(i, I, 1/Ti) : {}
     with_D ? Derivative(d, D, Td, max(Td/Nd, 1e-14)) : {}
     u_s - u_m - d
     Limiter(x, y, yMax, yMin)
     x - k * ((with_I ? I : 0.0) + (with_D ? D : 0.0) + u_s - u_m)
     }
end

function StateSpace(u::Signal, y::Signal,
                    A::Array{Real}, B::Array{Real}, C::Array{Real}, D::Array{Real})
    x = Unknown(zeros(size(A, 1)))  # state vector
    {
     A * x + B * u - der(x)
     C * x + D * u - y
     }
end



########################################
## Nonlinear Blocks
########################################



function Limiter(u::Signal, y::Signal, uMax::Real, uMin::Real)
    {
     y - ifelse(u > uMax, uMax,
                ifelse(u < uMin, uMin,
                       u))
     }
end

function Limiter(u::Signal, y::Signal, uMax::Real, uMin::Real)
    clamped_pos = Discrete(false)
    clamped_neg = Discrete(false)
    {
     BoolEvent(clamped_pos, u - uMax)
     BoolEvent(clamped_neg, uMin - u)
     y - ifelse(clamped_pos, uMax,
                ifelse(clamped_neg, uMin,
                       u))
     }
end

function DeadZone(u::Signal, y::Signal, uMax::Real, uMin::Real)
    pos = Discrete(false)
    neg = Discrete(false)
    {
     BoolEvent(pos, u - uMax)
     BoolEvent(neg, uMin - u)
     y - ifelse(pos, u - uMax,
                ifelse(neg, u - uMin,
                       0.0))
     }
end



########################################
## Examples
########################################



function ex_PID_Controller()
    driveAngle = 1.57
    n1 = Angle("n1")
    n2 = Angle("n2")
    n3 = Angle("n3")
    n4 = Angle("n4")
    s1 = Unknown("s1") 
    s2 = Unknown("s2") 
    s3 = Unknown("s3")
    s4 = Unknown("s4")
    k = 100.0
    Ti = 0.1
    Td = 0.1
    yMax = 12.0
    yMin = -yMax
    wp = 1.0
    wd = 0.0
    Ni = 0.1
    Nd = 10.0
    {
     ## KinematicPTP(s1, 0.5, driveAngle, 1.0, 1.0)
     ## Integrator(s1, s2, 1.0)
     s2 - ifelse((MTime < 0.5) | (MTime >= 3.2), 0.0,
                 ifelse(MTime < 1.5, MTime - 0.5,
                        ifelse(MTime < 2.2, 1.0, 3.2 - MTime)))
     SpeedSensor(n2, s3)
     LimPID(s2, s3, s4, "PI",
            k, Ti, Td, yMax, yMin, wp, wd, Ni, Nd)
     SignalTorque(n1, 0.0, s4)
     Inertia(n1, n2, 1.0)
     SpringDamper(n2, n3, 1e4, 100)
     Inertia(n3, n4, 2.0)
     SignalTorque(n4, 0.0, 10.0)
     }
end
# Results of this example match Dymola with the exception of
# starting transients. This example only solves if info[11] = 0
# after event restarts (don't recalc initial conditions). it info[11]
# is 1, it fails after the limiter kicks in.
