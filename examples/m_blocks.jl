using Sims


########################################
## Blocks examples
##
## These attempt to mimic the Modelica.Blocks.Examples
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
    s5 = Unknown("s5")
    {
     ## KinematicPTP(s1, 0.5, driveAngle, 1.0, 1.0)
     ## Integrator(s1, s2, 1.0)
     s1 - ifelse((MTime < 0.5) | (MTime >= 3.2), 0.0,
                 ifelse(MTime < 1.5, MTime - 0.5,
                        ifelse(MTime < 2.2, 1.0, 3.2 - MTime)))
     LimPID(s1, s2, s3, 
            @options(controllerType => "PI",
                     k  => 100.0,
                     Ti => 0.1,
                     Td => 0.1,
                     yMax => 12.0,
                     Ni => 0.1))
     SpeedSensor(n2, s2)
     SpeedSensor(n3, s4)
     s5 - (s4 - s2)
     InitialEquation(der(s5) - 0.0)  # force a constant initial spin of the shaft to tame initial conditions
     SignalTorque(n1, 0.0, s3)
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


f = elaborate(ex_PID_Controller())
sm = create_sim(f)


    
function sim_PID_Controller()

    
    y = sim(ex_PID_Controller(), 4.0)
    wplot(y, "PID_Controller.pdf")
    
end
