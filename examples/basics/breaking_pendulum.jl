
########################################
## Breaking pendulum                  ##
########################################


export BreakingPendulum


function FreeFall(x,y,vx,vy)
    @equations begin
        der(x) = vx
        der(y) = vy
        der(vx) = 0.0
        der(vy) = -9.81
    end
end

function Pendulum(x,y,vx,vy)
    len = sqrt(x.value^2 + y.value^2)
    phi0 = atan2(x.value, -y.value) 
    phi = Unknown(phi0)
    phid = Unknown()
    @equations begin
        der(phi) = phid
        der(x) = vx
        der(y) = vy
        x = len * sin(phi)
        y = -len * cos(phi)
        der(phid) = -9.81 / len * sin(phi)
    end
end

@doc* """
Models a pendulum that breaks at 5 secs. This model uses a
StructuralEvent to switch between `Pendulum` mode and `FreeFall` mode.

Based on an example by George Giorgidze's
thesis](http://eprints.nottingham.ac.uk/12554/1/main.pdf) that's in
[Hydra](https://github.com/giorgidze/Hydra/blob/master/examples/BreakingPendulum.hs).
""" ->
function BreakingPendulum()
    x = Unknown(cos(pi/4), "x")
    y = Unknown(-cos(pi/4), "y")
    vx = Unknown()
    vy = Unknown()
    Equation[
        StructuralEvent(MTime - 5.0,     # when time hits 5 sec, switch to FreeFall
            Pendulum(x,y,vx,vy),
            () -> FreeFall(x,y,vx,vy))
    ]
end

