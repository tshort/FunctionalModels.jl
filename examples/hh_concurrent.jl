
##
## Concurrent implementation of the Hodgkin-Huxley neuron model.
##

include("hh_base.jl")

tf = 0.1
dt = 0.025

hhs = map (HodgkinHuxley, 5.0:0.1:10.0)

@time for hh in hhs
    simrun (hh, 500.0, 0.025)
end



