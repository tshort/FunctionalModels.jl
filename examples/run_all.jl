#######################
## Run all _working_ examples
##
## Examples commented out probably don't work.
##
#######################

module ex

using Sims
sim = sunsim
path = Pkg.dir() * "/Sims/examples/"

include(path * "basics/breaking_pendulum_in_box.jl")

include(path * "basics/breaking_pendulum.jl")

## include(path * "basics/circuit_complex.jl")

include(path * "basics/dc_motor_w_shaft.jl")

include(path * "basics/half_wave_rectifiers.jl")

include(path * "stdlib/m_blocks.jl")
#sim_PID_Controller()

include(path * "stdlib/m_electrical.jl")
run_electrical_examples()

include(path * "stdlib/m_heat_transfer.jl")
sim_TwoMasses()
## sim_Motor()

include(path * "stdlib/m_powersystems.jl")
## sim_RLModel()
## sim_PiModel()

include(path * "stdlib/m_rotational.jl")
sim_First()

include(path * "basics/vanderpol.jl")

include(path * "basics/vanderpol_with_events.jl")

include(path * "neural/hh.jl")



end # module
