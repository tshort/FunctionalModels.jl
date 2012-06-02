
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
     der(x) - zeroGain ? 0 : (u - x) ./ T
     y - zeroGain ? 0 : (k ./ T) .* (u - x)
     }
end


function LimPID(u_s::Signal, u_m::Signal, y::Signal,
                controllerType::String,
                k::Real, Ti::Real, Td::Real, yMax::Real, yMin::Real, wp::Real, wd::Real, Ni::Real, Nd::Real)
    with_I = any(controllerType .== ["PI", "PID"])
    with_D = any(controllerType .== ["PD", "PID"])
    x = Unknown()  # node just in front of the limiter
    D = Unknown()  # output of derivative block
    I = Unknown()  # output of integrator block
    zeroGain = abs(k) < eps()
    {
     with_I ? Integrator(u_s - u_m + (y - x) / (k * Ni), I, 1/Ti) : {}
     with_D ? Derivative(u_s - u_m, D, Td, max(Td/Nd, 1e-14)) : {}
     Limiter(x, y, yMax, yMin)
     x - k * ((with_I ? I : 0.0) + (with_D ? D : 0.0) + u_s - u_m))
     y - zeroGain ? 0 : (k ./ T) .* (u - x)
     }
end

function StateSpace(u::Signal, y::Signal, A::Array{Real}, B::Array{Real}, C::Array{Real}, D::Array{Real})
    x = Unknown(zeros(size(A, 1))  # state vector
    {
     A * x + B * u - der(x)
     C * x + D * u - y
     }
end



########################################
## Continuous Blocks
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
     BoolEvent(u - uMax, clamped_pos)
     BoolEvent(uMin - u, clamped_neg)
     y - ifelse(clamped_pos, uMax,
                ifelse(clamped_neg, uMin,
                       u))
     }
end

function DeadZone(u::Signal, y::Signal, uMax::Real, uMin::Real)
    pos = Discrete(false)
    neg = Discrete(false)
    {
     BoolEvent(u - uMax, pos)
     BoolEvent(uMin - u, neg)
     y - ifelse(pos, u - uMax,
                ifelse(neg, u - uMin,
                       0.0))
     }
end
