
###########################################
## Interpolated event grid (requires Grid)
###########################################

@comment """
# Interpolated event grid
"""

using Requires

@require Grid begin

    using Grid
    
    function search_grid(g::InterpGrid, x::Float64)
        i = searchsortedfirst(g, x)
        g[i]
    end

    function grid_point(x::Float64, v::Float64)
        x - v
    end
    
"""
Interpolated event grid (requires Grid library).

```julia

make_grid(events, dt)

grid_input(grid)
```

Given a vector with event times sorted in ascending order and a
sampling step, creates a continuous interpolated function that has a
negative value between events, and crosses zero at each event time.
The function grid_input can be used to detect events in model equations.

### Arguments

* `events` : Vector of event times
* `dt` : event grid sampling time

### Example

```julia

## Events occur at t = 1.0, 2.0, 3.0 

input = make_grid([1.0,2.0,3.0],0.1)

Event(grid_input(input),
      Equation[
                reinit(x, x + k)
              ],
      Equation[])

```
"""

function make_grid(events,dt)
    
    g0 = InterpGrid(events, 0.0, InterpNearest)

    x = 0.0:dt:events[end]
    y = map(x -> let v = search_grid(g0, x); grid_point(x,v) end, x)

    g = CoordInterpGrid(x,y,BCperiodic,InterpQuadratic)
    
    return g
end


grid_input(g) = mexpr(:call,getindex,g,MTime)


    
end
