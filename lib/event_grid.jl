
###########################################
## Interpolated event grid (requires Grid)
###########################################

@comment """
# Interpolated event grid
"""

using Requires

@require Grid begin

    using Grid
    
    function search_grid (g::InterpGrid, x::Float64)
        i = searchsortedfirst (g, x)
        g[i]
    end

    function grid_point (x::Float64, v::Float64)
        x - v
    end
    
@doc* """
Interpolated event grid (requires Grid library).

```julia

EventGrid(events, tf, dt)
```

### Arguments

* `event` : Vector of event times
* `tf` : grid end time
* `dt` : event grid sampling time

### Example

```julia

input = EventGrid([1.0,2.0,3.0],tstop,0.1)

Event(grid_input(input),
      Equation[
                reinit(x, x + k)
              ],
      Equation[])

```
""" ->

function EventGrid(events,tf,dt)
    
    g0 = InterpGrid(events, 0.0, InterpNearest)

    x = 0.0:dt:tf
    y = map (x -> let v = search_grid (g0, x); grid_point (x,v) end, x)

    g = CoordInterpGrid (x,y,BCperiodic,InterpQuadratic)
    
    return g
end


grid_input(g::CoordInterpGrid) = mexpr(:call,getindex,g,MTime)

    
end
