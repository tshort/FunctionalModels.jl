
load("Sims")
using Sims

############################################
## Breaking pendulum with floor and walls ##
############################################

function FreeFall(x,y,vx,vy)
    {
     vx - der(x)
     vy - der(y)
     der(vx)
     der(vy) + 9.81
     Event(y + 1.01,                # Bounce up if it hits the floor
           {reinit(vy, 0.95 * abs(vy))},
           {reinit(vy, 0.95 * abs(vy))})
     Event(x + 1.01,                # Left wall
           {reinit(vx, 0.95 * abs(vx))},
           {reinit(vx, 0.95 * abs(vx))})
     Event(x - 1.01,                # Right wall
           {reinit(vx, -0.95 * abs(vx))},
           {reinit(vx, -0.95 * abs(vx))})
    }
end

function Pendulum(x,y,vx,vy)
    len = sqrt(x.value^2 + y.value^2)
    phi0 = atan2(x.value, -y.value) 
    phi = Unknown(phi0)
    phid = Unknown()
    {
     phid - der(phi)
     vx - der(x)
     vy - der(y)
     x - len * sin(phi)
     y + len * cos(phi)
     der(phid) + 9.81 / len * sin(phi)
    }
end

function BreakingPendulumInBox()
    x = Unknown(cos(pi/4), "x")
    y = Unknown(-cos(pi/4), "y")
    vx = Unknown()
    vy = Unknown()
    {
     StructuralEvent(MTime - 1.8,     # when time hits 1.8 sec, switch to FreeFall
         Pendulum(x,y,vx,vy),
         () -> FreeFall(x,y,vx,vy))
    }
end

p = BreakingPendulumInBox()
p_f = elaborate(p)
p_s = create_sim(p_f) 
p_y = sim(p_s, 5.0)  

wplot(p_y, "BreakingPendulumInBox.pdf")
