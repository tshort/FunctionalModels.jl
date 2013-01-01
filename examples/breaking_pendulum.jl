
require("Sims")
using Sims

########################################
## Breaking pendulum                  ##
########################################

function FreeFall(x,y,vx,vy)
    {
     vx - der(x)
     vy - der(y)
     der(vx)
     der(vy) + 9.81
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

function BreakingPendulum()
    x = Unknown(cos(pi/4), "x")
    y = Unknown(-cos(pi/4), "y")
    vx = Unknown()
    vy = Unknown()
    {
     StructuralEvent(MTime - 5.0,     # when time hits 5 sec, switch to FreeFall
         Pendulum(x,y,vx,vy),
         () -> FreeFall(x,y,vx,vy))
    }
end

p = BreakingPendulum()
p_f = elaborate(p)
p_s = create_sim(p_f) 
p_y = sim(p_s, 6.0)  

wplot(p_y, "BreakingPendulum.pdf")
