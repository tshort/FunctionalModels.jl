#######################
## Run all _working_ examples
##
## Examples commented out probably don't work.
##
#######################

using Sims

path = Pkg.dir() * "/Sims/examples/"

include("breaking_pendulum_in_box.jl")

include("breaking_pendulum.jl")

include("circuit_complex.jl")

include("dc_motor_w_shaft.jl")

include("half_wave_rectifiers.jl")

include("m_blocks.jl")
sim_PID_Controller()

include("m_electrical.jl")
run_electrical_examples()

include("m_heat_transfer.jl")
sim_TwoMasses()
## sim_Motor()

include("m_powersystems.jl")
## sim_RLModel()
sim_PiModel()

include("m_rotational.jl")
sim_First()

include("vanderpol.jl")

include("vanderpol_with_events.jl")
