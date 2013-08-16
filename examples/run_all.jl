#######################
## Run all _working_ examples
##
## Examples commented out probably don't work.
##
#######################

module ex

using Sims

path = Pkg.dir() * "/Sims/examples/"

include(path * "breaking_pendulum_in_box.jl")

include(path * "breaking_pendulum.jl")

## include(path * "circuit_complex.jl")

include(path * "dc_motor_w_shaft.jl")

include(path * "half_wave_rectifiers.jl")

include(path * "m_blocks.jl")
sim_PID_Controller()

include(path * "m_electrical.jl")
run_electrical_examples()

include(path * "m_heat_transfer.jl")
sim_TwoMasses()
## sim_Motor()

include(path * "m_powersystems.jl")
## sim_RLModel()
## sim_PiModel()

include(path * "m_rotational.jl")
sim_First()

include(path * "vanderpol.jl")

include(path * "vanderpol_with_events.jl")

end # module
