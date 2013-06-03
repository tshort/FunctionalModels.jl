#######################
## Run all _working_ examples
##
## Examples commented out probably don't work.
##
#######################

module ex

using Sims

path = Pkg.dir() * "/Sims/examples/"

@show include(path * "breaking_pendulum_in_box.jl")

@show include(path * "breaking_pendulum.jl")

@show include(path * "circuit_complex.jl")

@show include(path * "dc_motor_w_shaft.jl")

@show include(path * "half_wave_rectifiers.jl")

@show include(path * "m_blocks.jl")
sim_PID_Controller()

@show include(path * "m_electrical.jl")
run_electrical_examples()

@show include(path * "m_heat_transfer.jl")
sim_TwoMasses()
## sim_Motor()

@show include(path * "m_powersystems.jl")
## sim_RLModel()
## sim_PiModel()

@show include(path * "m_rotational.jl")
sim_First()

@show include(path * "vanderpol.jl")

@show include(path * "vanderpol_with_events.jl")

end # module
