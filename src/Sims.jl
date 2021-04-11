
module Sims

using ModelingToolkit: Differential, ODESystem, Equation, @parameters, @variables

export Branch, RefBranch, system


##############################################
## Non-causal time-domain modeling in Julia ##
##############################################

# Tom Short, tshort@epri.com
#
#
# Copyright (c) 2012-2021, Electric Power Research Institute 
# BSD license - see the LICENSE file
 
# 
# This file is an experiment in doing non-causal modeling in Julia.
# The idea behind non-causal modeling is that the user develops models
# based on components which are described by a set of equations. A
# tool can then transform the equations and solve the differential
# algebraic equations. Non-causal models tend to match their physical
# counterparts in terms of their specification and implementation.
#
# Causal modeling is where all signals have an input and an output,
# and the flow of information is clear. Simulink is the
# highest-profile example.
# 
# The highest profile noncausal modeling tools are in the Modelica
# (www.modelica.org) family. The MathWorks also has Simscape that uses
# Matlab notation. Modelica is an object-oriented, open language with
# multiple implementations. It is a large, complex, powerful language
# with an extensive standard library of components.
#
# This implementation follows the work of David Broman and his MKL
# simulator and the work of George Giorgidze and Henrik Nilsson and
# their functional hybrid modeling.
#
# A nodal formulation is used based on David's work. His thesis
# documents this nicely:
# 
#   David Broman. Meta-Languages and Semantics for Equation-Based
#   Modeling and Simulation. PhD thesis, Thesis No 1333. Department of
#   Computer and Information Science, Link�ping University, Sweden,
#   2010.
#   http://www.bromans.com/david/publ/thesis-2010-david-broman.pdf
#
# Here is David's code and home page:
# 
#   http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
#   http://www.ida.liu.se/~davbr/
#   
# Modeling of dynamically varying systems is handled similarly to
# functional hybrid modelling (FHM), specifically the Hydra
# implementation by George. See here for links:
# 
#   https://github.com/giorgidze/Hydra
#   http://db.inf.uni-tuebingen.de/team/giorgidze
#   http://www.cs.nott.ac.uk/~nhn/
# 
# FHM is also a functional approach. Hydra is implemented as a domain
# specific language embedded in Haskell. Their implementation handles
# dynamically changing systems with JIT-compiled code from an
# amazingly small amount of code.
# 
# As stated, this file implements something like David's approach. A
# model constructor returns a list of equations. Models are made of
# models, so this builds up a hierarchical structure of equations that
# then need to be flattened. David's approach is nodal; nodes are
# passed in as parameters to models to perform connections between
# devices.
#
# Downsides of this approach:
#   - No connect-like capability. Must be nodal.
#   - Tougher to do model introspection.
#   - Tougher to map to a GUI. This is probably true with most
#     functional approaches. Tougher to add annotations.
#

"""
# Building models

The API for building models with Sims. Includes basic types, models,
and functions.
"""

@parameters t
const D = Differential(t)

"""
The model time - a special unknown variable.
"""
# const MTime = Unknown{DefaultUnknown,Normal}(:time, 0.0, "", false)


"""
A special ModelType to specify branch flows into nodes. When the model
is flattened, equations are created to zero out branch flows into
nodes. 

See also [Branch](#branch).

```julia
RefBranch(n, i) 
```

### Arguments

* `n` : the reference node.
* `i` : the flow variable that goes with this node.

### References

This nodal description is based on work by [David
Broman](http://web.ict.kth.se/~dbro/). See the following:

* http://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf
* http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
* https://github.com/david-broman/modelyze

[Modelyze](https://github.com/david-broman/modelyze) has both
`RefBranch` and `Branch`.

### Examples

Here is an example of RefBranch used in the definition of a
HeatCapacitor in the standard library. `hp` is the reference node (a
HeatPort aka Temperature), and `Q_flow` is the flow variable.

```julia
function HeatCapacitor(hp::HeatPort, C::Signal)
    Q_flow = HeatFlow(compatible_values(hp))
    [
        RefBranch(hp, Q_flow)
        C .* der(hp) ~ Q_flow
    ]
end
```

Here is the definition of SignalCurrent from the standard library a
model that injects current (a flow variable) between two nodes:

```julia
function SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  
    @equations begin
        RefBranch(n1, I) 
        RefBranch(n2, -I) 
    end
end
```
"""
struct RefBranch
    n     # This is the reference node.
    i     # This is the flow variable that goes with this reference.
end


"""
A helper Model to connect a branch between two different nodes and
specify potential between nodes and the flow between nodes.

See also [RefBranch](#refbranch).

```julia
Branch(n1, n2, v, i)
```

### Arguments

* `n1` : the positive reference node.
* `n2` : the negative reference node.
* `v` : the potential variable between nodes.
* `i` : the flow variable between nodes.

### Returns

* The model, consisting of a RefBranch entry for
  each node and an equation assigning `v` to `n1 - n2`.

### References

This nodal description is based on work by [David
Broman](http://web.ict.kth.se/~dbro/). See the following:

* http://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf
* http://www.bromans.com/software/mkl/mkl-source-1.0.0.zip
* https://github.com/david-broman/modelyze

### Examples

Here is the definition of an electrical resistor in the standard
library:

```julia
function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)
    i = Current(compatible_values(n1, n2))
    v = Voltage(value(n1) - value(n2))
    [
        Branch(n1, n2, v, i)
        v ~ R .* i
    ]
end
```
"""
function Branch(n1, n2, v, i)
    [
        RefBranch(n1, i)
        RefBranch(n2, -i)
        v ~ n1 - n2
    ]
end


########################################
## Elaboration / flattening           ##
########################################

#
# This converts a hierarchical model into a flat set of equations.
# 


"""
`elaborate` is the main elaboration function that returns
an `ODESystem`.

```julia
elaborate(a)
```

### Arguments

* `a` : the input model containing a nested vector of equations

### Returns

* `::ODESystem` : the flattened model

"""

function system(a; simplify = true)
    eq = Equation[]
    nodemap = Dict()
    elaborate_unit!(a, eq, nodemap)
    # Add in equations for each node to sum flows to zero:
    for (key, nodeset) in nodemap
        push!(eq, 0 ~ nodeset)
    end
    sys = ODESystem(eq)
    if simplify
        return structural_simplify(sys)
    else
        return sys
    end
end

#
# elaborate_unit flattens the set of equations while building up
# events, event responses, and a Dict of nodes.
#
elaborate_unit!(a::Any, eq::Vector{Equation}, nodemap::Dict) = nothing # The default is to ignore undefined types.
function elaborate_unit!(a::Equation, eq::Vector{Equation}, nodemap::Dict)
    push!(eq, a)
end
function elaborate_unit!(a::Vector, eq::Vector{Equation}, nodemap::Dict)
    map(x -> elaborate_unit!(x, eq, nodemap), a)
end

function elaborate_unit!(b::RefBranch, eq::Vector{Equation}, nodemap::Dict)
    if b.n isa Num
        nodemap[b.n] = get(nodemap, b.n, 0.0) + b.i
    end
end


# load standard Sims libraries

# include("../lib/Lib.jl")

# load standard Sims examples

# include("../examples/Examples.jl")


end # module Sims


