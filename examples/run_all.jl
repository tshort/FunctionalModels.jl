#######################
## Run all _working_ examples
##
## Examples commented out probably don't work.
##
#######################

module ex

using Sims

path = Pkg.dir() * "/Sims/examples/"

@show include("breaking_pendulum_in_box.jl")

@show include("breaking_pendulum.jl")

@show include("circuit_complex.jl")

@show include("dc_motor_w_shaft.jl")

@show include("half_wave_rectifiers.jl")

@show include("m_blocks.jl")
sim_PID_Controller()

@show include("m_electrical.jl")
run_electrical_examples()

@show include("m_heat_transfer.jl")
sim_TwoMasses()
## sim_Motor()

@show include("m_powersystems.jl")
## sim_RLModel()
## sim_PiModel()

@show include("m_rotational.jl")
sim_First()

@show include("vanderpol.jl")

@show include("vanderpol_with_events.jl")

end # module
