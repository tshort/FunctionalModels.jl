
########################################
## Elaboration / flattening           ##
########################################

#
# This converts a hierarchical model into a flat set of equations.
# 
# After elaboration, the following structure is returned. This sort-of
# follows Hydra's SymTab structure.
#

#
type EquationSet
    model           # The active model, a hierachichal set of equations.
    equations       # A flat list of equations.
    events
    pos_responses
    neg_responses
    nodeMap::Dict
end
# In EquationSet, model contains equations and StructuralEvents. When
# a StructuralEvent triggers, the entire model is elaborated again.
# The first step is to replace StructuralEvents that have activated
# with their new_relation in model. Then, the rest of the EquationSet
# is reflattened using model as the starting point.


# 
# elaborate is the main elaboration function. There is no real symbolic
# processing (sorting, index reduction, or any of the other stuff a
# fancy modeling tool would do).
# 
elaborate(a::Model) = elaborate(EquationSet(a, {}, {}, {}, {}, Dict()))

function elaborate(x::EquationSet)
    eq = EquationSet({}, {}, {}, {}, {}, Dict())
    eq.model = handle_events(x.model)
    eq.equations = elaborate_unit(eq.model, eq) # This will also modify eq.

    # Add in equations for each node to sum flows to zero:
    for (key, nodeset) in eq.nodeMap
        push!(eq.equations, nodeset)
    end
    # last fixups: 
    eq.equations = remove_empties(strip_mexpr(eq.equations))
    eq
end

# Generic model traversing helper.
# Applies a function to each element of the model tree.
function traverse_mod(f::Function, a::Model)
    emodel = {}
    for el in a
        el1 = f(el)
        if isa(el1, Array)
            append!(emodel, el1)
        else  # this handles symbols
            push!(emodel, el1)
        end
    end
    emodel
end

#
# handle_events traverses the model tree and replaces
# StructuralEvent's that have activated.
#
handle_events(a::Model) = traverse_mod(handle_events, a)
handle_events(x) = x
handle_events(ev::StructuralEvent) = ev.activated ? ev.new_relation() : ev

#
# elaborate_unit flattens the set of equations while building up
# events, event responses, and a Dict of nodes.
#
elaborate_unit(a::Any, eq::EquationSet) = Any[] # The default is to ignore undefined types.
elaborate_unit(a::ModelType, eq::EquationSet) = a
function elaborate_unit(a::Model, eq::EquationSet)
    traverse_mod((x) -> elaborate_unit(x, eq), a)
end

function elaborate_unit(b::RefBranch, eq::EquationSet)
    if (isa(b.n, Unknown))
        eq.nodeMap[b.n] = get(eq.nodeMap, b.n, 0.0) + b.i
    elseif (isa(b.n, RefUnknown))
        vec = compatible_values(b.n.u)
        vec[b.n.idx...] = 1.0
        eq.nodeMap[b.n.u] = get(eq.nodeMap, b.n.u, 0.0) + b.i .* vec 
    end
    {}
end

function elaborate_unit(ev::Event, eq::EquationSet)
    push!(eq.events, strip_mexpr(elaborate_unit(ev.condition, eq)))
    push!(eq.pos_responses, strip_mexpr(elaborate_unit(ev.pos_response, eq)))
    push!(eq.neg_responses, strip_mexpr(elaborate_unit(ev.neg_response, eq)))
    {}
end

function elaborate_unit(ev::StructuralEvent, eq::EquationSet)
    # Set up the event:
    push!(eq.events, strip_mexpr(elaborate_unit(ev.condition, eq)))
    # A positive zero crossing initiates a change:
    push!(eq.pos_responses, (t,y,yp) -> begin global __sim_structural_change = true; ev.activated = true; end)
    # Dummy negative zero crossing
    push!(eq.neg_responses, (t,y,yp) -> return)
    strip_mexpr(elaborate_unit(ev.default, eq))
end


# These methods strip the MExpr's from expressions.
strip_mexpr(a) = a
strip_mexpr{T}(a::Vector{T}) = map(strip_mexpr, a)
strip_mexpr(a::MExpr) = strip_mexpr(a.ex)
## strip_mexpr(a::MSymbol) = a.sym 
strip_mexpr(e::Expr) = Expr(e.head, (isempty(e.args) ? e.args : map(strip_mexpr, e.args))...)

# Other utilities:
remove_empties(l::Vector{Any}) = filter(x -> !isequal(x, {}), l)
eval_all(x) = eval(x)
eval_all{T}(x::Array{T,1}) = map(eval_all, x)


