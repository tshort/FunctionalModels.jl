
########################################
## Blocks examples
##
## These attempt to mimic the Modelica.Blocks.Examples
########################################

export PID_Controller

@doc """
# Blocks
""" -> type DocHeadBlocks <: DocTag end


@doc* """
Demonstrates the usage of a Continuous.LimPID controller


This is a simple drive train controlled by a PID controller:

* The two blocks "kinematic_PTP" and "integrator" are used to generate
  the reference speed (= constant acceleration phase, constant speed
  phase, constant deceleration phase until inertia is at rest). To
  check whether the system starts in steady state, the reference speed
  is zero until time = 0.5 s and then follows the sketched trajectory.

* The block "PI" is an instance of "Blocks.Continuous.LimPID" which is
  a PID controller where several practical important aspects, such as
  anti-windup-compensation has been added. In this case, the control
  block is used as PI controller.

* The output of the controller is a torque that drives a motor inertia
  "inertia1". Via a compliant spring/damper component, the load
  inertia "inertia2" is attached. A constant external torque of 10 Nm
  is acting on the load inertia.

Key parameters for plotting are:

* s2 - output of the integrator
* s3 - speed sensor on inertia1

* s4 - output of the PI control
* s5 - speed sensor on inertia2

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Blocks.Examples.PID_ControllerD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Blocks_Examples.html#Modelica.Blocks.Examples.PID_Controller)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Blocks_Examples.html#Modelica.Blocks.Examples.PID_Controller)
""" ->
function PID_Controller()
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
    @equations begin
        ## KinematicPTP(s1, 0.5, driveAngle, 1.0, 1.0)
        ## Integrator(s1, s2, 1.0)
        s1 = ifelse((MTime < 0.5) | (MTime >= 3.2), 0.0,
                    ifelse(MTime < 1.5, MTime - 0.5,
                           ifelse(MTime < 2.2, 1.0, 3.2 - MTime)))
        SpeedSensor(n2, s3)
        SpeedSensor(n3, s4)
        LimPID(s2, s3, s4, 
               controllerType = "PI",
               k  = 100.0,
               Ti = 0.1,
               Td = 0.1,
               yMax = 12.0,
               Ni = 0.1)
        SignalTorque(n1, 0.0, s4)
        s5 = s4 - s2
        InitialEquation(der(s5) - 0.0)  # force a constant initial spin of the shaft to tame initial conditions
        SignalTorque(n1, 0.0, s3)
        Inertia(n1, n2, 1.0)
        SpringDamper(n2, n3, 1e4, 100)
        Inertia(n3, n4, 2.0)
        SignalTorque(n4, 0.0, 10.0)
    end
end
# Results of this example match Dymola with the exception of
# starting transients. This example only solves if info[11] = 0
# after event restarts (don't recalc initial conditions). If info[11]
# is 1, it fails after the limiter kicks in.


