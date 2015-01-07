This document contains various thoughts on future development options.
Also on the table is a complete rewrite.

## Better symbolic preprocessing

Most Modelica tools do a number of preprocessing steps to simplify the
system. This makes it easier to calculate initial values and speed up
solutions. Here are some links:

* http://www.jmodelica.org/5109
* http://staff.polito.it/roberto.zanino/sub1/teach_files/modelica_minicourse/03%20-%20Symbolic%20Manipulation.pdf
* https://modelica.org/events/modelica2011/Proceedings/pages/papers/10_3_ID_110_a_fv.pdf  

## Better initialization

The current initialization support is weak. It relies on DASSL or
Sundials to calculate initial values, and that doesn't honor Unknowns
with fixed `initial` values. Placeholders are in the Unknowns for
this, but they are not honored. The idea is to use `solve` for
initialization. Right now, this works with Kinsol and can solve
non-differential systems. Better symbolic support should make this
easier.



## Mapping to a GUI

Though I have no plans for a GUI, it's interesting to think about. I'm
not sure this functional / nodal approach works very well for mapping
to a gui.

A gui can easily generate the functional representation of a model
pieced together in a gui. The reverse is the challenge. Can we have a
gui that reads the code and makes a graphical representation of that?

### Help 

This one's easy. Just use whatever format Julia settles on.

### Graphical representation 

The icon definition of an object could be returned as part of the
object's constructor call, either as an equation that's parsed
specially or as a separate component. A link to an SVG file would be
the easiest. A nice feature is having the icon image change based on
parameters. That's tougher to accomplish. Icon changing could be nice
to adjust the number of ports (optional heat port for example) or to
indicate grounding configuration.

### Model input parameters 

This one's tougher. How can we pull in parameter information? I'm not
sure how to retrieve method argument lists in Julia. For mapping to a
gui, this is probably the most important function. We want a
documentation string, a label, units, and more. Instead of arguments
being simple values (like nodal voltages), each would need to be
packed with more information. For example, a node voltage may become:

``` .jl
type ElectricalNode
    v::Unknown
    description::String
    unit::String # physical units
    X::Float64   # graphical coordinate
    Y::Float64   # graphical coordinate
end
``` 

The type above could be split into pieces, with standards for
annotation. In any case, we'd need standard extraction methods to pull
data out about parameters.

### Connections

This is the biggest deficiency of using a nodal approach. It's tough
to see how to map connections. As a user plops down models, where is a
given "Node" defined?

Maybe a node could have a graphical list of the connections to all
top-level models attached.

TODO: Look at how Simplorer (VHDL-AMS) works. 

### One option

One option to including GUI-related metadata is to use method
definitions. Here is an example of a resistor definition along with
methods defining metadata that use the same signature, except with a
leading "tag".

```julia
function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    Equation[
        Branch(n1, n2, v, i)
        R .* i - v   # == 0 is implied
    ]
end

# help info - returns a string in Markdown format
Resistor(::SIMS_HELP, n1::ElectricalNode, n2::ElectricalNode, R::Signal) = "
# Electrical resistor

The linear resistor connects the branch voltage v with the branch
current `i` by `i*R = v`. The Resistance `R` is allowed to be positive,
zero, or negative.

# Parameters

*`n1`* ::ElectricalNode -- Positive pin (potential `n1` > `n2` for positive voltage drop `v`)
*`n2`* ::ElectricalNode -- Negative pin
*`R`* ::Signal -- Electrical resistance
"

# Icon - returns a file in SVG format
Resistor(::SIMS_ICON, n1::ElectricalNode, n2::ElectricalNode, R::Signal) = readall("img/resistor1.svg")

# Parameter metadata
Resistor(::SIMS_PARAMETERS, n1::ElectricalNode, n2::ElectricalNode, R::Signal) = {
    {"n1", ElectricalNode, "Positive pin (potential `n1` > `n2` for positive voltage drop `v`)"}
    {"n2", ElectricalNode, "Negative pin"}
    {"R", Signal, "Electrical resistance"}
}

# Parameter metadata - alternate definition
Resistor(::SIMS_PARAMETERS, n1::ElectricalNode, n2::ElectricalNode, R::Signal) = {
    "Positive pin (potential `n1` > `n2` for positive voltage drop `v`)"
    "Negative pin"
    "Electrical resistance"
}
```

Some ways to improve on what's above are:

* Automate parameter metadata. Extract these right from method
  signatures.
* In the help file, automatically insert the method signature and
  parameter information.
* Parameter metadata could also include GUI information like
  checkboxes or menu selectors.
* Types could also be mapped to GUI menu's for fill-in of information.
  This could also apply to `options` (options.jl style with defaults).
  Tab/grouping information in dialogs could also be handled with
  method definitions like:

```julia
type MyType
    male::Bool      # converted to checkbox
    radius::Float64
    name::String
    state::Choices(["AL", "AK", "AZ"])  # not sure if this will work
end

MyType(::SIMS_PARAMETERS, male::Bool, radius::Float64, name::String, state::Choices) = {
    {"Male", "Tab1"}
    {"Conductor radius, m", "Tab1"}
    {"Name", "Tab2"}
    {"State", "Tab2"}
}

```

Also, this approach does allow changing the icon based on parameters.
I'm not sure it helps with the problem of mapping connections.

### Web interfaces

An easier application to think about is an autogenerated web interface
to a model. For that, we need the model input parameters and maybe a
diagram. We don't need a full two-way GUI. The diagram can be static.











