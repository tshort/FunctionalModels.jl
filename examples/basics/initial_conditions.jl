
## Examples of initial conditions

#
# These only work for "balanced" cases meaning the number of inputs
# equals the number of outputs.
#
# Still need to figure out how to make that happen for the more
# common underdetermined case.
#


export InitialCondition, MkinInitialCondition


@doc+ """
A basic test of solving for initial conditions for two simultaineous
equations.
""" ->
function InitialCondition()
    @unknown x y
    @equations begin
        2*x - y = exp(-x)
         -x + 2*y = exp(-y)
     end
end

@doc+ """
A basic test of solving for initial conditions for two simultaineous
equations.
""" ->
function MkinInitialCondition()
    @unknown x(1.0) y(1.0)
    @equations begin
        x^2 + y^2 = 1.0
        y = x^2
    end
end
