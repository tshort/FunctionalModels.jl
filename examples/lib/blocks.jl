
########################################
## Blocks examples
##
## These attempt to mimic the Modelica.Blocks.Examples
########################################

export PID_Controller

"""
# Blocks
"""
@comment 

"""
Demonstrates the usage of a Continuous.LimPID controller


This is a simple drive train controlled by a PID controller:

* The two blocks "kinematic_PTP" and "integrator" are used to generate
  the reference speed (= constant acceleration phase, constant speed
  phase, constant deceleration phase until inertia is at rest). To
  check whether the system starts in steady state, the reference speed
  is zero until time = 0.5 s and then follows the sketched
  trajectory. Note: the "kinematic_PTP" isn't used; that comment is
  based on the Modelica model.

* The block "PI" is an instance of "LimPID" which is a PID controller
  where several practical important aspects, such as
  anti-windup-compensation has been added. In this case, the control
  block is used as PI controller.

* The output of the controller is a torque that drives a motor inertia
  "inertia1". Via a compliant spring/damper component, the load
  inertia "inertia2" is attached. A constant external torque of 10 Nm
  is acting on the load inertia.

![diagram](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica.Blocks.Examples.PID_ControllerD.png)

[LBL doc link](http://simulationresearch.lbl.gov/modelica/releases/msl/3.2/help/Modelica_Blocks_Examples.html#Modelica.Blocks.Examples.PID_Controller)
 | [MapleSoft doc link](http://www.maplesoft.com/documentation_center/online_manuals/modelica/Modelica_Blocks_Examples.html#Modelica.Blocks.Examples.PID_Controller)
"""
function PID_Controller()
    n1 = Angle()
    n2 = Angle()
    @named setpoint = Unknown() 
    @named shaftspeed = Unknown()
    @named tau = Unknown()
    [
        setpoint ~ ifelse((t < 0.5) | (t >= 3.2), 0.0,
                          ifelse(t < 1.5, t - 0.5,
                                 ifelse(t < 2.2, 1.0, 3.2 - t)))
        :ss1 => SpeedSensor(n1, shaftspeed)
        :pid => LimPID(setpoint, shaftspeed, tau, 
               controllerType = "PI",
               k  = 100.0,
               Ti = 0.1,
               Td = 0.1,
               yMax = 12.0,
               Ni = 0.1)
         :st1 => SignalTorque(n1, 0.0, tau)
         :in1 => Inertia(n1, 1.0)
         :sd1 => SpringDamper(n1, n2, 1e4, 100)
         :in2 => Inertia(n2, 2.0)
         :st2 => SignalTorque(n2, 0.0, 10.0)
    ]
end


