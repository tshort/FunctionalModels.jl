

############################################
## Breaking pendulum with floor and walls ##
############################################

export BreakingPendulumInBox

function FreeFallinBox(x,y,vx,vy)
    @equations begin
        der(x) = vx
        der(y) = vy
        der(vx) 
        der(vy) = -9.81
        Event(y + 1.01,                # Bounce up if it hits the floor
              Equation[reinit(vy, 0.95 * abs(vy))],
              Equation[reinit(vy, 0.95 * abs(vy))])
        Event(x + 1.01,                # Left wall
              Equation[reinit(vx, 0.95 * abs(vx))],
              Equation[reinit(vx, 0.95 * abs(vx))])
        Event(x - 1.01,                # Right wall
              Equation[reinit(vx, -0.95 * abs(vx))],
              Equation[reinit(vx, -0.95 * abs(vx))])
    end
end

function PenduluminBox(x,y,vx,vy)
    len = sqrt(x.value^2 + y.value^2)
    phi0 = atan2(x.value, -y.value) 
    phi = Unknown(phi0)
    phid = Unknown()
    @equations begin
        der(phi) = phid
        der(x)   = vx
        der(y)   = vy
        x = len * sin(phi)
        y = -len * cos(phi)
        der(phid) = -9.81 / len * sin(phi)
    end
end

"""
An extension of Sims.Examples.Basics.BreakingPendulum.

Floors and a wall are added. These are handled by `Events` in the
`FreeFall` model. Velocities are reversed to bounce the ball.
"""
function BreakingPendulumInBox()
    x = Unknown(cos(pi/4), "x")
    y = Unknown(-cos(pi/4), "y")
    vx = Unknown()
    vy = Unknown()
    Equation[
    StructuralEvent(MTime - 1.8,     # when time hits 1.8 sec, switch to FreeFall
        PenduluminBox(x,y,vx,vy),
        () -> FreeFallinBox(x,y,vx,vy))
    ]
end

