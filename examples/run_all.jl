#######################
## Run all _working_ examples
##
## Examples commented out probably don't work.
#######################

load("Sims")
using Sims

path = julia_pkgdir() * "/Sims/examples/"

load(path * "breaking_pendulum_in_box.jl")

load(path * "breaking_pendulum.jl")

## load(path * "circuit_complex.jl")

## load(path * "dc_motor_w_shaft.jl")

## load(path * "half_wave_rectifiers.jl")

load(path * "m_blocks.jl")
sim_PID_Controller()

load(path * "m_electrical.jl")
run_electrical_examples()

load(path * "m_heat_transfer.jl")
sim_TwoMasses()
## sim_Motor()

load(path * "m_rotational.jl")
sim_First()

load(path * "vanderpol.jl")

load(path * "vanderpol_with_events.jl")
