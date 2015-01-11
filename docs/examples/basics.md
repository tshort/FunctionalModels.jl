



# Examples using basic models

These are available in **Sims.Examples.Basics**.

Here is an example of use:

```julia
using Sims
m = Sims.Examples.Basics.Vanderpol()
v = sim(m, 50.0)

using Winston
wplot(v)
```




## BreakingPendulum

Models a pendulum that breaks at 5 secs. This model uses a
StructuralEvent to switch between `Pendulum` mode and `FreeFall` mode.

Based on an example by George Giorgidze's
thesis](http://eprints.nottingham.ac.uk/12554/1/main.pdf) that's in
[Hydra](https://github.com/giorgidze/Hydra/blob/master/examples/BreakingPendulum.hs).

[Sims/src/../examples/basics/breaking_pendulum.jl:41](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/breaking_pendulum.jl#L41)



## BreakingPendulumInBox

An extension of Sims.Examples.Basics.BreakingPendulum.

Floors and a wall are added. These are handled by `Events` in the
`FreeFall` model. Velocities are reversed to bounce the ball.

[Sims/src/../examples/basics/breaking_pendulum_in_box.jl:47](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/breaking_pendulum_in_box.jl#L47)



## DcMotorWithShaft

A DC motor with a flexible shaft. The shaft is made of multiple
elements. These are collected together algorithmically.

This is a smaller version of an example on p. 117 of David Broman's
[thesis](http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf).

I don't know if the results are reasonable or not.

[Sims/src/../examples/basics/dc_motor_w_shaft.jl:81](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/dc_motor_w_shaft.jl#L81)



## HalfWaveRectifier

A half-wave rectifier. The diode uses Events to toggle switching.

See F. E. Cellier and E. Kofman, *Continuous System Simulation*,
Springer, 2006, fig 9.27.

[Sims/src/../examples/basics/half_wave_rectifiers.jl:57](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/half_wave_rectifiers.jl#L57)



## StructuralHalfWaveRectifier

This is the same circuit used in
Sims.Examples.Basics.HalfWaveRectifier, but a structurally variable
diode is used instead of a diode that uses Events.

[Sims/src/../examples/basics/half_wave_rectifiers.jl:79](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/half_wave_rectifiers.jl#L79)



## InitialCondition

A basic test of solving for initial conditions for two simultaineous
equations.

[Sims/src/../examples/basics/initial_conditions.jl:19](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/initial_conditions.jl#L19)



## MkinInitialCondition

A basic test of solving for initial conditions for two simultaineous
equations.

[Sims/src/../examples/basics/initial_conditions.jl:31](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/initial_conditions.jl#L31)



## Vanderpol

The Van Der Pol oscillator is a simple problem with two equations
and two unknowns.

[Sims/src/../examples/basics/vanderpol.jl:24](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/vanderpol.jl#L24)



## VanderpolWithEvents()

An extension of Sims.Examples.Basics.Vanderpol. Events are triggered
every 2 sec that change the quantity `mu`.

[Sims/src/../examples/basics/vanderpol_with_events.jl:13](https://github.com/tshort/Sims.jl/tree/d39a15c1969c6fad87a4a7ab7f25088963690512/src/../examples/basics/vanderpol_with_events.jl#L13)

