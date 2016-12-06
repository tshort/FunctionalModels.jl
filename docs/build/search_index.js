var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Sims.jl-1",
    "page": "Home",
    "title": "Sims.jl",
    "category": "section",
    "text": "A Julia package for equation-based modeling and simulations."
},

{
    "location": "index.html#Background-1",
    "page": "Home",
    "title": "Background",
    "category": "section",
    "text": "Sims is like a lite version of Modelica. This package is for non-causal modeling in Julia. The idea behind non-causal modeling is that the user develops models based on components which are described by a set of equations. A tool can then transform the equations and solve the differential algebraic equations. Non-causal models tend to match their physical counterparts in terms of their specification and implementation.Causal modeling is where all signals have an input and an output, and the flow of information is clear. Simulink is the highest-profile example. The problem with causal modeling is that it is difficult to build up models from components.The highest profile noncausal modeling tools are in the Modelica family. The MathWorks company also has Simscape that uses Matlab notation. Modelica is an object-oriented, open language with multiple implementations. It is a large, complex, powerful language with an extensive standard library of components.This implementation follows the work of David Broman (thesis and code) and George Giorgidze (Hydra code and thesis) and Henrik Nilsson and their functional hybrid modeling. Sims is most similar to Modelyze by David Broman (report).Two solvers are available to solve the implicit DAE's generated. The default is DASKR, a derivative of DASSL with root finding. A solver based on the Sundials package is also available."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Sims is an installable package. To install Sims, use the following:Pkg.add(\"Sims\")Sims.jl has one main module named Sims and the following submodules:Sims.Lib – the standard library\nSims.Examples – example models, including:\nSims.Examples.Basics\nSims.Examples.Lib\nSims.Examples.Neural"
},

{
    "location": "index.html#Basic-example-1",
    "page": "Home",
    "title": "Basic example",
    "category": "section",
    "text": "Sims defines a basic symbolic class used for unknown variables in the model. As unknown variables are evaluated, expressions (of type MExpr) are built up.julia> using Sims\n\njulia> a = Unknown()\n##1243\n\njulia> a * (a + 1)\nMExpr(*(##1243,+(##1243,1)))In a simulation, the unknowns are to be solved based on a set of equations. Equations are built from device models. A device model is a function that returns a vector of equations or other devices that also return lists of equations. The equations each are assumed equal to zero. So,der(y) = x + 1Should be entered as:der(y) - (x+1)der indicates a derivative.The Van Der Pol oscillator is a simple problem with two equations and two unknowns:function Vanderpol()\n    y = Unknown(1.0, \"y\")   # The 1.0 is the initial value. \"y\" is for plotting.\n    x = Unknown(\"x\")        # The initial value is zero if not given.\n    # The following gives the return value which is a list of equations.\n    # Expressions with Unknowns are kept as expressions. Expressions of\n    # regular variables are evaluated immediately.\n    Equation[\n        # The -1.0 in der(x, -1.0) is the initial value for the derivative \n        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed\n        der(y) - x\n    ]\nend\n\ny = sim(Vanderpol(), 10.0) # Run the simulation to 10 seconds and return\n                           # the result as an array.\n# plot the results with Winston\nusing Winston\nwplot(y)Here are the results:(Image: plot results)An @equations macro is provided to return Equation[] allowing for the use of equals in equations, so the example above can be:function Vanderpol()\n    y = Unknown(1.0, \"y\") \n    x = Unknown(\"x\")\n    @equations begin\n        der(x, -1.0) = (1 - y^2) * x - y\n        der(y) = x\n    end\nend\n\ny = sim(Vanderpol(), 10.0) # Run the simulation to 10 seconds and return\n                           # the result as an array.\n# plot the results with Winston\nwplot(y)"
},

{
    "location": "index.html#Electrical-example-1",
    "page": "Home",
    "title": "Electrical example",
    "category": "section",
    "text": "This example shows definitions of several electrical components. Each is again a function that returns a list of equations. Equations are expressions (type MExpr) that includes other expressions and unknowns (type Unknown).Arguments to each function are model parameters. These normally include nodes specifying connectivity followed by parameters specifying model characteristics.Models can contain models or other functions that return equations. The function Branch is a special function that returns an equation specifying relationships between nodes and flows. It also acts as an indicator to mark nodes. In the flattening/elaboration process, equations are created to sum flows (in this case electrical currents) to zero at all nodes. RefBranch is another special function for marking nodes and flow variables.Nodes passed as parameters or created with ElectricalNode() are simply unknowns. For these electrical examples, a node is simply an unknown voltage.function Resistor(n1, n2, R::Real) \n    i = Current()   # This is simply an Unknown. \n    v = Voltage()\n    @equations begin\n        Branch(n1, n2, v, i)\n        R * i = v\n    end\nend\n\nfunction Capacitor(n1, n2, C::Real) \n    i = Current()\n    v = Voltage()\n    @equations begin\n        Branch(n1, n2, v, i)\n        C * der(v) = i\n    end\nendWhat follows is a top-level circuit definition. In this case, there are no input parameters. The ground reference \"g\" is assigned zero volts.All of the equations returned in the list of equations are other models with various parameters.function Circuit()\n    n1 = Voltage(\"Source voltage\")   # The string indicates labeling for plots\n    n2 = Voltage(\"Output voltage\")\n    n3 = Voltage()\n    g = 0.0  # A ground has zero volts; it's not an unknown.\n    Equation[\n        SineVoltage(n1, g, 10.0, 60.0)\n        Resistor(n1, n2, 10.0)\n        Resistor(n2, g, 5.0)\n        SeriesProbe(n2, n3, \"Capacitor current\")\n        Capacitor(n3, g, 5.0e-3)\n    ]\nend\n\nckt = Circuit()\nckt_y = sim(ckt, 0.1)\ngplot(ckt_y)Here are the results:(Image: plot results)"
},

{
    "location": "index.html#Initialization-and-Solving-Sets-of-Equations-1",
    "page": "Home",
    "title": "Initialization and Solving Sets of Equations",
    "category": "section",
    "text": "Sims initialization is still weak, but it is developed enough to be able to solve non-differential equations. Here is a small example where two Unknowns, x and y, are solved based on the following two equations:function test()\n    @unknown x y\n    @equations begin\n        2*x - y   = exp(-x)\n         -x + 2*y = exp(-y)\n    end\nend\n\nsolution = solve(create_sim(test()))"
},

{
    "location": "index.html#Hybrid-Modeling-and-Structural-Variability-1",
    "page": "Home",
    "title": "Hybrid Modeling and Structural Variability",
    "category": "section",
    "text": "Sims supports basic hybrid modeling, including the ability to handle structural model changes. Consider the following example:Breaking pendulumThis model starts as a pendulum, then the wire breaks, and the ball goes into free fall. Sims handles this much like Hydra; the model is recompiled. Because Julia can compile code just-in-time (JIT), this happens relatively quickly. After the pendulum breaks, the ball bounces around in a box. This shows off another feature of Sims: handling nonstructural events. Each time the wall is hit, the velocity is adjusted for the \"bounce\".Here is an animation of the results. Note that the actual animation was done in R, not Julia.(Image: plot results)"
},

{
    "location": "basics.html#",
    "page": "Basics",
    "title": "Basics",
    "category": "page",
    "text": ""
},

{
    "location": "basics.html#Documentation-1",
    "page": "Basics",
    "title": "Documentation",
    "category": "section",
    "text": "This document provides a general introduction to Sims."
},

{
    "location": "basics.html#Unknowns-1",
    "page": "Basics",
    "title": "Unknowns",
    "category": "section",
    "text": "Models consist of equations and unknown variables. The number of equations should match the number of unknowns. In Sims, the type Unknown is used to define unknown variables. Without the constructor parts, the definition of Unknown is:type Unknown{T<:UnknownCategory} <: UnknownVariable\n    sym::Symbol\n    value         # holds initial values (and type info)\n    label::AbstractString \nendUnknowns can be grouped into categories. That's what the T is for in the definition above. One can define different types of Unknowns (electrical vs. mechanical for example). The default is DefaultUnknown. Unknowns of different types can also be used to define models of the same name that act differently depending on what type of node they are connected to.Unknowns also contain a value. This is used for setting initial values, and these values are updated if there is a structural change in the model. Unknowns can be different types. Eventually, all Unknowns are converted to Float64's in an array for simulation. Currently, Sim supports Unknowns of type Float64, Complex128, and arrays of either of these. Adding support for other structures is not hard as long as they can be converted to Float64's.The label string is used for labeling simulation outputs. Unlabeled Unknowns are not included in results.Here are several ways to define Unknowns:x = Unknown()          # An initial value of 0.0 with no labeling.\ny = Unknown(1.0, \"y\")  # An initial value of 1.0 and a label of \"y\" on outputs.\nz = Unknown([1.0, 0.0], \"vector\")  # An Unknown with array values.\nV = Unknown{Voltage}(10.0, \"Output voltage\")  # An Unknown of type VoltageHere are ways to create new Unknown types:# Untyped Unknowns:\nAngle = AngularVelocity = AngularAcceleration = Torque = RotationalNode = Unknown\n\n# Typed Unknowns:\ntype UVoltage <: UnknownCategory\nend\ntype UCurrent <: UnknownCategory\nend\ntypealias ElectricalNode Unknown{UVoltage}\ntypealias Voltage Unknown{UVoltage}\ntypealias Current Unknown{UCurrent}In model equations, derivatives are specified with der:   der(y)Derivatives of Unknowns are an object of type DerUnknown. DerUnknown objects contain an initial value, and a pointer to the Unknown object it references. Initial values can be entered as the second parameter to the der function:   der(y, 3.0) - (x+1)   #  The derivative of y starts with the value 3.0"
},

{
    "location": "basics.html#Models-1",
    "page": "Basics",
    "title": "Models",
    "category": "section",
    "text": "Here is a model of the Van Der Pol oscillator:function Vanderpol()\n    y = Unknown(1.0, \"y\")   \n    x = Unknown(\"x\")       \n    # The following gives the return value which is a list of equations.\n    # Expressions with Unknowns are kept as expressions. Regular\n    # variables are evaluated immediately (like normal).\n    Equation[\n        der(x, -1.0) - ((1 - y^2) * x - y)   # == 0 is assumed\n        der(y) - x\n    ]\nendA device model is a function that returns a list of equations or other devices that also return lists of equations. The equations each are assumed equal to zero. In Julia, this is the best we can do, because there isn't an equality operator (== doesn't fit the bill, either).Models should normally be locally balanced, meaning the number of unknowns matches the number of equations. It's pretty easy to match unknowns and equations as shown below:function Capacitor(n1, n2, C::Real) \n    i = Current()              # Unknown #1\n    v = Voltage()              # Unknown #2\n    Equation[\n        Branch(n1, n2, v, i)      # Equation #1 - this returns n1 - n2 - v\n        C * der(v) - i            # Equation #2\n    ]\nendIn the model above, the nodes n1 and n2 are also Unknowns, but they are defined outside of this model.Here is the top-level circuit definition. In this case, there are no input parameters. The ground reference g is assigned zero volts.function Circuit()\n    n1 = ElectricalNode(\"Source voltage\")   # The string indicates labeling for plots\n    n2 = ElectricalNode(\"Output voltage\")\n    n3 = ElectricalNode()\n    g = 0.0  # a ground has zero volts; it's not an Unknown.\n    Equation[\n        VSource(n1, g, 10.0, 60.0)\n        Resistor(n1, n2, 10.0)\n        Resistor(n2, g, 5.0)\n        SeriesProbe(n2, n3, \"Capacitor current\")\n        Capacitor(n3, g, 5.0e-3)\n    ]\nendAll of the equations returned in this list of equations are other models with different parameters.In this top-level model, three new Unknowns are introduced (n1, n2, and n2). Because these are nodes, each Unknown node will also cause an equation to be generated that sums the flows into the node to be zero.In this model, the voltages n1 and n2 are labeled, so they will appear in the output. A SeriesProbe is used to label the current through the capacitor."
},

{
    "location": "basics.html#Simulating-a-Model-1",
    "page": "Basics",
    "title": "Simulating a Model",
    "category": "section",
    "text": "Steps to building and simulating a model are straightforward.v = Vanderpol()       # returns the hierarchical model\nv_f = elaborate(v)    # returns the flattened model\nv_s = create_sim(v_f) # returns a \"Sim\" ready for simulation\nv_yout = sim(v_s, 10.0) # run the simulation to 10 seconds and return\n                        # the result as an array plus column headingsTwo solvers are available: dasslsim and sunsim using the Sundials. Right now, sim is equivalent to dasslsim.Simulations can also be run directly from a hierarchical model:v_yout = sim(v, 10.0) Right now, there are really no options available for simulation parameters."
},

{
    "location": "basics.html#Simulation-Output-1",
    "page": "Basics",
    "title": "Simulation Output",
    "category": "section",
    "text": "The result of a sim run is an object with components y and colnames. y is a two-dimensional array with time slices along rows and variables along columns. The first column is simulation time. The remaining columns are for each unknown in the model including derivatives. colnames contains the names of each of the columns in y after the time column."
},

{
    "location": "basics.html#Hybrid-Modeling-1",
    "page": "Basics",
    "title": "Hybrid Modeling",
    "category": "section",
    "text": "Sims provides basic support for hybrid modeling. Discrete variables are variables that are not involved in integration but apply when \"events\" occur. Models can define events denoting changes in behavior.Event is the main type used for hybrid modeling. It contains a condition for root finding and model expressions to process after positive and negative root crossings are detected.type Event <: ModelType\n    condition::ModelType   # An expression used for the event detection. \n    pos_response::Model    # An expression indicating what to do when\n                           # the condition crosses zero positively.\n    neg_response::Model    # An expression indicating what to do when\n                           # the condition crosses zero in the\n                           # negative direction.\nendThe function reinit is used in Event responses to redefine variables. Here is an example of a voltage source defined with a square wave:function VSquare(n1, n2, V::Real, f::Real)  \n    i = Current()\n    v = Voltage()\n    v_mag = Discrete(V)\n    Equation[\n        Branch(n1, n2, v, i)\n        v - v_mag\n        Event(sin(2 * pi * f * MTime),\n              Equation[reinit(v_mag, V)],    # positive crossing\n              Equation[reinit(v_mag, -V)])   # negative crossing\n    ]\nendThe variable v_mag is the Discrete variable that is changed using reinit whenever the sin(2 * pi * f * MTime) crosses zero. A response is provided for both positive and negative zero crossings.Two other constructs that are useful are BoolEvent and ifelse.  ifelse is like an if-then-else block, but for ModelTypes (you can't use a regular if-then-else block, at least not without macros).   BoolEvent is a helper for attaching an event to a boolean variable. Here is an example for an ideal diode:function IdealDiode(n1, n2)\n    i = Current()\n    v = Voltage()\n    s = Unknown()  # dummy variable\n    openswitch = Discrete(false)  # on/off state of diode\n    Equation[\n        Branch(n1, n2, v, i)\n        BoolEvent(openswitch, -s)  # openswitch becomes true when s goes negative\n        v - ifelse(openswitch, s, 0.0) \n        i - ifelse(openswitch, 0.0, s) \n    ]\nendDiscrete variables are based on Signals from the Reactive.jl package. This provides Reactive Programming capabilities where variables have data flow. This is similar to how spreadsheets dynamically update and how Simulink works. This lift operator defines dependencies based on a function, and reinit is used to update inputs. Here is an example:a = Discrete(2.0)\nb = Discrete(4.0)\nc = lift((x,y) -> x * y, a, b)   # 8.0\nreinit(a, 4.0)  # c becomes 16.0Parameters are a special type of Discrete variable. These can be used as input to models. These stay alive through flattening and simulation creation. They can be updated externally from one simulation to the next."
},

{
    "location": "basics.html#Structurally-Varying-Systems-1",
    "page": "Basics",
    "title": "Structurally Varying Systems",
    "category": "section",
    "text": "StructuralEvent defines a type for elements that change the structure of the model. An event is created, and when the event is triggered, the model is re-flattened after replacing default with new_relation in the model.type StructuralEvent <: ModelType\n    condition::ModelType   # Expression indicating a zero crossing for event detection.\n    default                # The default relation.\n    new_relation::Function # Function to call when the new relation is needed.\n    activated::Bool        # Used internally to indicate whether the event fired.\nendHere is an example for a breaking pendulum. The model starts with the Pendulum construct. Then, when five seconds is reached, the StructuralEvent triggers, and the model is recompiled with the FreeFall construct.function BreakingPendulum()\n    x = Unknown(cos(pi/4), \"x\")\n    y = Unknown(-cos(pi/4), \"y\")\n    vx = Unknown()\n    vy = Unknown()\n    Equation[\n        StructuralEvent(MTime - 5.0,     # when time hits 5 sec, switch to FreeFall\n            Pendulum(x,y,vx,vy),\n            () -> FreeFall(x,y,vx,vy))\n    ]\nendOne special thing to note is that new_relation must be a function (in the case above, an anonymous function). If new_relation is not a function, it will evaluate right away. The use of a function delays evaluation until the model is recompiled."
},

{
    "location": "api\\main.html#",
    "page": "Building models",
    "title": "Building models",
    "category": "page",
    "text": "CurrentModule = SimsPages = [\"main.md\"]\nDepth = 5"
},

{
    "location": "api\\main.html#Building-models-1",
    "page": "Building models",
    "title": "Building models",
    "category": "section",
    "text": "The API for building models with Sims. Includes basic types, models, and functions."
},

{
    "location": "api\\main.html#Sims.verbosity",
    "page": "Building models",
    "title": "Sims.verbosity",
    "category": "Function",
    "text": "Control the verbosity of output.\n\nverbosity(i)\n\nArguments\n\ni : Int indicator with the following meanings:\ni == 0 : don't print information\ni == 1 : minimal info\ni == 2 : all info, including events\n\nMore options may be added in the future. This function is not exported, so you must qualify it as Sims.verbosity(0).\n\n\n\n"
},

{
    "location": "api\\main.html#verbosity-1",
    "page": "Building models",
    "title": "verbosity",
    "category": "section",
    "text": "verbosity"
},

{
    "location": "api\\main.html#Sims.ModelType",
    "page": "Building models",
    "title": "Sims.ModelType",
    "category": "Type",
    "text": "The main overall abstract type in Sims.\n\n\n\n"
},

{
    "location": "api\\main.html#ModelType-1",
    "page": "Building models",
    "title": "ModelType",
    "category": "section",
    "text": "ModelType"
},

{
    "location": "api\\main.html#Sims.UnknownVariable",
    "page": "Building models",
    "title": "Sims.UnknownVariable",
    "category": "Type",
    "text": "An abstract type for variables to be solved. Examples include Unknown, DerUnknown, and Parameter.\n\n\n\n"
},

{
    "location": "api\\main.html#UnknownVariable-1",
    "page": "Building models",
    "title": "UnknownVariable",
    "category": "section",
    "text": "UnknownVariable"
},

{
    "location": "api\\main.html#Sims.UnknownCategory",
    "page": "Building models",
    "title": "Sims.UnknownCategory",
    "category": "Type",
    "text": "Categories of Unknown types; used to subtype Unknowns.\n\n\n\n"
},

{
    "location": "api\\main.html#UnknownCategory-1",
    "page": "Building models",
    "title": "UnknownCategory",
    "category": "section",
    "text": "UnknownCategory"
},

{
    "location": "api\\main.html#Sims.DefaultUnknown",
    "page": "Building models",
    "title": "Sims.DefaultUnknown",
    "category": "Type",
    "text": "The default UnknownCategory.\n\n\n\n"
},

{
    "location": "api\\main.html#DefaultUnknown-1",
    "page": "Building models",
    "title": "DefaultUnknown",
    "category": "section",
    "text": "DefaultUnknown"
},

{
    "location": "api\\main.html#Sims.UnknownConstraint",
    "page": "Building models",
    "title": "Sims.UnknownConstraint",
    "category": "Type",
    "text": "Categories of constraints on Unknowns; used to create positive, negative, etc., constraints.\n\n\n\n"
},

{
    "location": "api\\main.html#UnknownConstraint-1",
    "page": "Building models",
    "title": "UnknownConstraint",
    "category": "section",
    "text": "UnknownConstraint"
},

{
    "location": "api\\main.html#Sims.Normal",
    "page": "Building models",
    "title": "Sims.Normal",
    "category": "Type",
    "text": "Indicates no constraint is imposed.\n\n\n\n"
},

{
    "location": "api\\main.html#Normal-1",
    "page": "Building models",
    "title": "Normal",
    "category": "section",
    "text": "Normal"
},

{
    "location": "api\\main.html#Sims.Negative",
    "page": "Building models",
    "title": "Sims.Negative",
    "category": "Type",
    "text": "Indicates unknowns of this type must be constrained to negative values.\n\n\n\n"
},

{
    "location": "api\\main.html#Negative-1",
    "page": "Building models",
    "title": "Negative",
    "category": "section",
    "text": "Negative"
},

{
    "location": "api\\main.html#Sims.NonNegative",
    "page": "Building models",
    "title": "Sims.NonNegative",
    "category": "Type",
    "text": "Indicates unknowns of this type must be constrained to positive or zero values.\n\n\n\n"
},

{
    "location": "api\\main.html#NonNegative-1",
    "page": "Building models",
    "title": "NonNegative",
    "category": "section",
    "text": "NonNegative"
},

{
    "location": "api\\main.html#Sims.Positive",
    "page": "Building models",
    "title": "Sims.Positive",
    "category": "Type",
    "text": "Indicates unknowns of this type must be constrained to positive values.\n\n\n\n"
},

{
    "location": "api\\main.html#Positive-1",
    "page": "Building models",
    "title": "Positive",
    "category": "section",
    "text": "Positive"
},

{
    "location": "api\\main.html#Sims.NonPositive",
    "page": "Building models",
    "title": "Sims.NonPositive",
    "category": "Type",
    "text": "Indicates unknowns of this type must be constrained to negative or zero values.\n\n\n\n"
},

{
    "location": "api\\main.html#NonPositive-1",
    "page": "Building models",
    "title": "NonPositive",
    "category": "section",
    "text": "NonPositive"
},

{
    "location": "api\\main.html#Sims.Unknown",
    "page": "Building models",
    "title": "Sims.Unknown",
    "category": "Type",
    "text": "An Unknown represents variables to be solved in Sims. An Unknown is a symbolic type. When used in Julia expressions, Unknowns combine into MExprs which are symbolic representations of equations.\n\nExpressions (of type MExpr) are built up based on Unknown's. Unknown is a symbol with a uniquely generated symbol name. If you have\n\nUnknowns can contain Float64, Complex, and Array{Float64} values. Additionally, Unknowns can be extended to support other types. All Unknown types currently map to positions in an Array{Float64}.\n\nIn addition to a value, Unknowns can carry additional metadata, including an identification symbol and a label. In the future, unit information may be added.\n\nUnknowns can also have type parameters. Two parameters are provided:\n\nT: type of unknown; several are defined in Sims.Lib, including UVoltage and UAngularVelocity.\nC: contstraint on the unknown; possibilities include Normal (the default), Positive, NonNegative, `Negative, and NonPositive.\n\nAs an example, Voltage is defined as Unknown{UVoltage,Normal} in the standard library. The UVoltage type parameter is a marker to distinguish those Unknown from others. Users can add their own Unknown types. Different Unknown types makes it easier to dispatch on model arguments.\n\nUnknown(s::Symbol, x, label::AbstractString, fixed::Bool)\nUnknown()\nUnknown(x)\nUnknown(s::Symbol, label::AbstractString)\nUnknown(x, label::AbstractString)\nUnknown(label::AbstractString)\nUnknown(s::Symbol, x, fixed::Bool)\nUnknown(s::Symbol, x)\nUnknown{T,C}(s::Symbol, x, label::AbstractString, fixed::Bool)\nUnknown{T,C}()\nUnknown{T,C}(x)\nUnknown{T,C}(s::Symbol, label::AbstractString)\nUnknown{T,C}(x, label::AbstractString)\nUnknown{T,C}(label::AbstractString)\nUnknown{T,C}(s::Symbol, x, fixed::Bool)\nUnknown{T,C}(s::Symbol, x)\n\nArguments\n\ns::Symbol : identification symbol, defaults to gensym()\nx : initial value and type information, defaults to 0.0\nlabel::AbstractString : labeling string, defaults to \"\"\n\nExamples\n\n  a = 4\n  b = Unknown(3.0, \"len\")\n  a * b + b^2\n\n\n\n"
},

{
    "location": "api\\main.html#Unknown-1",
    "page": "Building models",
    "title": "Unknown",
    "category": "section",
    "text": "Unknown"
},

{
    "location": "api\\main.html#Sims.is_unknown",
    "page": "Building models",
    "title": "Sims.is_unknown",
    "category": "Function",
    "text": "Is the object an UnknownVariable?\n\n\n\n"
},

{
    "location": "api\\main.html#is_unknown-1",
    "page": "Building models",
    "title": "is_unknown",
    "category": "section",
    "text": "is_unknown"
},

{
    "location": "api\\main.html#Sims.DerUnknown",
    "page": "Building models",
    "title": "Sims.DerUnknown",
    "category": "Type",
    "text": "An UnknownVariable representing the derivitive of an Unknown, normally created with der(x).\n\nArguments\n\nx::Unknown : the Unknown variable\nval : initial value, defaults to 0.0\n\nExamples\n\na = Unknown()\nder(a) + 1\ntypeof(der(a))\n\n\n\n"
},

{
    "location": "api\\main.html#DerUnknown-1",
    "page": "Building models",
    "title": "DerUnknown",
    "category": "section",
    "text": "DerUnknown"
},

{
    "location": "api\\main.html#Sims.der",
    "page": "Building models",
    "title": "Sims.der",
    "category": "Function",
    "text": "Represents the derivative of an Unknown.\n\nder(x::Unknown)\nder(x::Unknown, val)\n\nArguments\n\nx::Unknown : the Unknown variable\nval : initial value, defaults to 0.0\n\nExamples\n\na = Unknown()\nder(a) + 1\n\n\n\n"
},

{
    "location": "api\\main.html#der-1",
    "page": "Building models",
    "title": "der",
    "category": "section",
    "text": "der"
},

{
    "location": "api\\main.html#Sims.MExpr",
    "page": "Building models",
    "title": "Sims.MExpr",
    "category": "Type",
    "text": "Represents expressions used in models.\n\nMExpr(ex::Expr)\n\nArguments\n\nex::Expr : an expression\n\nExamples\n\na = Unknown()\nb = Unknown()\nd = a + sin(b)\ntypeof(d)\n\n\n\n"
},

{
    "location": "api\\main.html#MExpr-1",
    "page": "Building models",
    "title": "MExpr",
    "category": "section",
    "text": "MExpr"
},

{
    "location": "api\\main.html#Sims.mexpr",
    "page": "Building models",
    "title": "Sims.mexpr",
    "category": "Function",
    "text": "Create MExpr's (model expressions). Analogous to expr in Base.\n\nThis is also useful for wrapping user-defined functions where the built-in mechanisms don't work.\n\nmexpr(head::Symbol, args::ANY...)\n\nArguments\n\nhead::Symbol : the expression head\nargs... : values and expressions passed to expression arguments\n\nReturns\n\nex::MExpr : a model expression\n\nExamples\n\na = Unknown()\nb = Unknown()\nd = a + sin(b)\ntypeof(d)\nmyfun(x) = mexpr(:call, :myfun, x)\n\n\n\n"
},

{
    "location": "api\\main.html#mexpr-1",
    "page": "Building models",
    "title": "mexpr",
    "category": "section",
    "text": "mexpr"
},

{
    "location": "api\\main.html#Sims.Equation",
    "page": "Building models",
    "title": "Sims.Equation",
    "category": "Type",
    "text": "Equations are used in Models. Right now, Equation is defined as Any, but that may change.  Normally, Equations are of type Unknown, DerUnknown, MExpr, or Array{Equation} (for nesting models).\n\nExamples\n\nModels return Arrays of Equations. Here is an example:\n\nfunction Vanderpol()\n    y = Unknown(1.0, \"y\")\n    x = Unknown(\"x\")\n    Equation[\n        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed\n        der(y) - x\n    ]\nend\ndump( Vanderpol() )\n\n\n\n"
},

{
    "location": "api\\main.html#Equation-1",
    "page": "Building models",
    "title": "Equation",
    "category": "section",
    "text": "Equation"
},

{
    "location": "api\\main.html#Sims.Model",
    "page": "Building models",
    "title": "Sims.Model",
    "category": "Type",
    "text": "Represents a vector of Equations. For now, Equation equals Any, but in the future, it may only include ModelType's.\n\nModels return Arrays of Equations. \n\nExamples\n\nfunction Vanderpol()\n    y = Unknown(1.0, \"y\")\n    x = Unknown(\"x\")\n    Equation[\n        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed\n        der(y) - x\n    ]\nend\ndump( Vanderpol() )\nx = sim(Vanderpol(), 50.0)\n\n\n\n"
},

{
    "location": "api\\main.html#Model-1",
    "page": "Building models",
    "title": "Model",
    "category": "section",
    "text": "Model"
},

{
    "location": "api\\main.html#Sims.RefUnknown",
    "page": "Building models",
    "title": "Sims.RefUnknown",
    "category": "Type",
    "text": "An UnknownVariable used to allow Arrays as Unknowns. Normally created with getindex. Defined methods include:\n\ngetindex\nlength\nsize\nhcat\nvcat\n\n\n\n"
},

{
    "location": "api\\main.html#RefUnknown-1",
    "page": "Building models",
    "title": "RefUnknown",
    "category": "section",
    "text": "RefUnknown"
},

{
    "location": "api\\main.html#Sims.value",
    "page": "Building models",
    "title": "Sims.value",
    "category": "Function",
    "text": "The value of an object or UnknownVariable.\n\nvalue(x)\n\nArguments\n\nx : an object\n\nReturns\n\nFor standard Julia objects, value(x) returns x. For Unknowns and other ModelTypes, returns the current value of the object. value evaluates immediately, so don't expect to use this in model expressions, except to grab an immediate value.\n\nExamples\n\nv = Voltage(value(n1) - value(n2))\n\n\n\n"
},

{
    "location": "api\\main.html#value-1",
    "page": "Building models",
    "title": "value",
    "category": "section",
    "text": "value"
},

{
    "location": "api\\main.html#Sims.name",
    "page": "Building models",
    "title": "Sims.name",
    "category": "Function",
    "text": "The name of an UnknownVariable.\n\nname(a::UnknownVariable)\n\nArguments\n\nx::UnknownVariable\n\nReturns\n\ns::AbstractString : either the label of the Unknown or if that's blank, the symbol name of the Unknown.\n\nExamples\n\na = Unknown(\"var1\")\nname(a)\n\n\n\n"
},

{
    "location": "api\\main.html#name-1",
    "page": "Building models",
    "title": "name",
    "category": "section",
    "text": "name"
},

{
    "location": "api\\main.html#Sims.compatible_values",
    "page": "Building models",
    "title": "Sims.compatible_values",
    "category": "Function",
    "text": "A helper functions to return the base value from an Unknown to use when creating other Unknowns. It is especially useful for taking two model arguments and creating a new Unknown compatible with both arguments.\n\ncompatible_values(x,y)\ncompatible_values(x)\n\nIt's still somewhat broken but works for basic cases. No type promotion is currently done.\n\nArguments\n\nx, y : objects or Unknowns\n\nReturns\n\nThe returned object has zeros of type and length common to both x and y.\n\nExamples\n\na = Unknown(45.0 + 10im)\nx = Unknown(compatible_values(a))   # Initialized to 0.0 + 0.0im.\na = Unknown()\nb = Unknown([1., 0.])\ny = Unknown(compatible_values(a,b)) # Initialized to [0.0, 0.0].\n\n\n\n"
},

{
    "location": "api\\main.html#compatible_values-1",
    "page": "Building models",
    "title": "compatible_values",
    "category": "section",
    "text": "compatible_values"
},

{
    "location": "api\\main.html#Sims.MTime",
    "page": "Building models",
    "title": "Sims.MTime",
    "category": "Constant",
    "text": "The model time - a special unknown variable.\n\n\n\n"
},

{
    "location": "api\\main.html#MTime-1",
    "page": "Building models",
    "title": "MTime",
    "category": "section",
    "text": "MTime"
},

{
    "location": "api\\main.html#Sims.RefBranch",
    "page": "Building models",
    "title": "Sims.RefBranch",
    "category": "Type",
    "text": "A special ModelType to specify branch flows into nodes. When the model is flattened, equations are created to zero out branch flows into nodes. \n\nSee also Branch.\n\nRefBranch(n, i) \n\nArguments\n\nn : the reference node.\ni : the flow variable that goes with this node.\n\nReferences\n\nThis nodal description is based on work by David Broman. See the following:\n\nhttp://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf\nhttp://www.bromans.com/software/mkl/mkl-source-1.0.0.zip\nhttps://github.com/david-broman/modelyze\n\nModelyze has both RefBranch and Branch.\n\nExamples\n\nHere is an example of RefBranch used in the definition of a HeatCapacitor in the standard library. hp is the reference node (a HeatPort aka Temperature), and Q_flow is the flow variable.\n\nfunction HeatCapacitor(hp::HeatPort, C::Signal)\n    Q_flow = HeatFlow(compatible_values(hp))\n    @equations begin\n        RefBranch(hp, Q_flow)\n        C .* der(hp) = Q_flow\n    end\nend\n\nHere is the definition of SignalCurrent from the standard library a model that injects current (a flow variable) between two nodes:\n\nfunction SignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  \n    @equations begin\n        RefBranch(n1, I) \n        RefBranch(n2, -I) \n    end\nend\n\n\n\n"
},

{
    "location": "api\\main.html#RefBranch-1",
    "page": "Building models",
    "title": "RefBranch",
    "category": "section",
    "text": "RefBranch"
},

{
    "location": "api\\main.html#Sims.Branch",
    "page": "Building models",
    "title": "Sims.Branch",
    "category": "Function",
    "text": "A helper Model to connect a branch between two different nodes and specify potential between nodes and the flow between nodes.\n\nSee also RefBranch.\n\nBranch(n1, n2, v, i)\n\nArguments\n\nn1 : the positive reference node.\nn2 : the negative reference node.\nv : the potential variable between nodes.\ni : the flow variable between nodes.\n\nReturns\n\n::Array{Equation} : the model, consisting of a RefBranch entry for each node and an equation assigning v to n1 - n2.\n\nReferences\n\nThis nodal description is based on work by David Broman. See the following:\n\nhttp://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf\nhttp://www.bromans.com/software/mkl/mkl-source-1.0.0.zip\nhttps://github.com/david-broman/modelyze\n\nExamples\n\nHere is the definition of an electrical resistor in the standard library:\n\nfunction Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)\n    i = Current(compatible_values(n1, n2))\n    v = Voltage(value(n1) - value(n2))\n    @equations begin\n        Branch(n1, n2, v, i)\n        v = R .* i\n    end\nend\n\n\n\n"
},

{
    "location": "api\\main.html#Branch-1",
    "page": "Building models",
    "title": "Branch",
    "category": "section",
    "text": "Branch"
},

{
    "location": "api\\main.html#Sims.InitialEquation",
    "page": "Building models",
    "title": "Sims.InitialEquation",
    "category": "Type",
    "text": "A ModelType describing initial equations. Current support is limited and may be broken. There are no tests. The idea is that the equations provided will only be used during the initial solution.\n\nInitialEquation(eqs)\n\nArguments\n\nx::Unknown : the quantity to be initialized\neqs::Array{Equation} : a vector of equations, each to be equated to zero during the initial equation solution.\n\n\n\n"
},

{
    "location": "api\\main.html#InitialEquation-1",
    "page": "Building models",
    "title": "InitialEquation",
    "category": "section",
    "text": "InitialEquation"
},

{
    "location": "api\\main.html#Sims.PassedUnknown",
    "page": "Building models",
    "title": "Sims.PassedUnknown",
    "category": "Type",
    "text": "An UnknownVariable used as a helper for the delay function.  It is an identity unknown, but it doesn't replace with a reference to the y array.\n\nPassedUnknown(ref::UnknownVariable)\n\nArguments\n\nref::UnknownVariable : an Unknown\n\n\n\n"
},

{
    "location": "api\\main.html#PassedUnknown-1",
    "page": "Building models",
    "title": "PassedUnknown",
    "category": "section",
    "text": "PassedUnknown"
},

{
    "location": "api\\main.html#Sims.delay",
    "page": "Building models",
    "title": "Sims.delay",
    "category": "Function",
    "text": "A Model specifying a delay to an Unknown.\n\nInternally, Unknowns that are delayed store past history. This is interpolated as needed to find the delayed quantity.\n\ndelay(x::Unknown, val)\n\nArguments\n\nx::Unknown : the quantity to be delayed.\nval : the value of the delay; may be an object or Unknown.\n\nReturns\n\n::MExpr : a delayed Unknown\n\n\n\n"
},

{
    "location": "api\\main.html#delay-1",
    "page": "Building models",
    "title": "delay",
    "category": "section",
    "text": "delay"
},

{
    "location": "api\\main.html#Sims.UnknownReactive",
    "page": "Building models",
    "title": "Sims.UnknownReactive",
    "category": "Type",
    "text": "An abstract type representing Unknowns that use the Reactive.jl package. The main types included are Discrete and Parameter. Discrete is normally used as inputs inside of models and includes an initial value that is reset at every simulation run. Parameter is used to pass information from outside to the model. Use this for repeated simulation runs based on parameter variations.\n\nBecause they are Unknowns, UnknownReactive types form MExpr's when used in expressions just like Unknowns.\n\nMany of the methods from Reactive.jl are supported, including lift, foldl, filter, dropif, droprepeats, keepwhen, dropwhen, sampleon, and merge. Use reinit to reinitialize a Discrete or a Parameter (equivalent to Reactive.push!).\n\n\n\n"
},

{
    "location": "api\\main.html#UnknownReactive-1",
    "page": "Building models",
    "title": "UnknownReactive",
    "category": "section",
    "text": "UnknownReactive"
},

{
    "location": "api\\main.html#Sims.Discrete",
    "page": "Building models",
    "title": "Sims.Discrete",
    "category": "Type",
    "text": "Discrete is a type for discrete variables. These are only changed during events. They are not used by the integrator. Because they are not used by the integrator, almost any type can be used as a discrete variable. Discrete variables wrap a Signal from the Reactive.jl package.\n\nConstructors\n\nDiscrete(initialvalue = 0.0)\nDiscrete(x::Reactive.Signal, initialvalue)\n\nWithout arguments, Discrete() uses an initial value of 0.0.\n\nArguments\n\ninitialvalue : initial value and type information, defaults to 0.0\nx::Reactive.Signal : a Signal from the Reactive.jl package.\n\nDetails\n\nDiscrete is the main input type for discrete variables. By default, it wraps a Reactive.Signal type. Discrete variables support data flow using Reactive.jl. Use reinit to update Discrete variables. Use lift to create additional UnknownReactive types that depend on the Discrete input. Use foldl for actions that remember state. For more information on Reactive Programming, see the Reactive.jl package.\n\n\n\n"
},

{
    "location": "api\\main.html#Discrete-1",
    "page": "Building models",
    "title": "Discrete",
    "category": "section",
    "text": "Discrete"
},

{
    "location": "api\\main.html#Sims.Parameter",
    "page": "Building models",
    "title": "Sims.Parameter",
    "category": "Type",
    "text": "An UnknownReactive type that is useful for passing parameters at the top level.\n\nArguments\n\nParameter(x = 0.0)\nParameter(sig::Reactive.Signal}\n\nArguments\n\nx : initial value and type information, defaults to 0.0\nsig : A `Reactive.Signal \n\nDetails\n\nParameters can be reinitialized with reinit, either externally or inside models. If you want Parameters to be read-only, wrap them in another UnknownReactive before passing to models. For example, use param_read_only = lift(x -> x, param).\n\nExamples\n\nSims.Examples.Basics.VanderpolWithParameter takes one model argument mu. Here is an example of it used externally with a Parameter:\n\nmu = Parameter(1.0)\nss = create_simstate(VanderpolWithParameter(mu))\nvwp1 = sim(ss, 10.0)\nreinit(mu, 1.5)\nvwp2 = sim(ss, 10.0)\nreinit(mu, 1.0)\nvwp3 = sim(ss, 10.0) # should be the same as vwp1\n\n\n\n"
},

{
    "location": "api\\main.html#Parameter-1",
    "page": "Building models",
    "title": "Parameter",
    "category": "section",
    "text": "Parameter"
},

{
    "location": "api\\main.html#Sims.reinit",
    "page": "Building models",
    "title": "Sims.reinit",
    "category": "Function",
    "text": "reinit is used in Event responses to redefine variables. \n\nreinit(x, y)\n\nArguments\n\nx : the object to be reinitialized; can be a Discrete, Parameter, an Unknown, or DerUnknown\ny : value for redefinition.\n\nReturns\n\nA value stored just prior to an event.\n\nExamples\n\nHere is the definition of Step in the standard library:\n\nfunction Step(y::Signal, \n              height = 1.0,\n              offset = 0.0, \n              startTime = 0.0)\n    ymag = Discrete(offset)\n    @equations begin\n        y = ymag  \n        Event(MTime - startTime,\n              Equation[reinit(ymag, offset + height)],   # positive crossing\n              Equation[reinit(ymag, offset)])            # negative crossing\n    end\nend\n\nSee also IdealThyristor in the standard library.\n\n\n\n"
},

{
    "location": "api\\main.html#reinit-1",
    "page": "Building models",
    "title": "reinit",
    "category": "section",
    "text": "reinit"
},

{
    "location": "api\\main.html#Sims.LeftVar",
    "page": "Building models",
    "title": "Sims.LeftVar",
    "category": "Type",
    "text": "A helper type needed to mark unknowns as left-side variables in assignments during event responses.\n\n\n\n"
},

{
    "location": "api\\main.html#LeftVar-1",
    "page": "Building models",
    "title": "LeftVar",
    "category": "section",
    "text": "LeftVar"
},

{
    "location": "api\\main.html#Reactive.lift",
    "page": "Building models",
    "title": "Reactive.lift",
    "category": "Function",
    "text": "Create a new UnknownReactive type that links to existing UnknownReactive types (like Discrete and Parameter).\n\nlift{T}(f::Function, inputs::UnknownReactive{T}...)\nlift{T}(f::Function, t::Type, inputs::UnknownReactive{T}...)\nmap{T}(f::Function, inputs::UnknownReactive{T}...)\nmap{T}(f::Function, t::Type, inputs::UnknownReactive{T}...)\n\nSee also Reactive.lift] and the @liftd helper macro to ease writing expressions.\n\nNote that lift is being transitioned to Base.map.\n\nArguments\n\nf::Function : the transformation function; takes one argument for each inputs argument\ninputs::UnknownReactive : signals to apply f to\nt::Type : optional output type\n\nNote: you cannot use Unknowns or MExprs in f, the transformation function.\n\nExamples\n\na = Discrete(1)\nb = lift(x -> x + 1, a)\nc = lift((x,y) -> x * y, a, b)\nreinit(a, 3)\nb    # now 4\nc    # now 12\n\nSee IdealThyristor in the standard library.\n\nNote that you can use Discretes and Parameters in expressions that create MExprs. Compare the following:\n\nj = lift((x,y) = x * y, a, b)\nk = a * b\n\nIn this example, j uses lift to immediately connect to a and b. k is an MExpr with a * b embedded inside. When j is used in a model, the j UnknownReactive object is embedded in the model, and it is updated automatically. With k, a * b is inserted into the model, so it's more like a macro; a * b will be evaluated every time in the residual calculation. The advantage of the a * b approach is that the expression can include Unknowns.\n\n\n\n"
},

{
    "location": "api\\main.html#lift-1",
    "page": "Building models",
    "title": "lift",
    "category": "section",
    "text": "lift"
},

{
    "location": "api\\main.html#Base.foldl",
    "page": "Building models",
    "title": "Base.foldl",
    "category": "Function",
    "text": "\"Fold over time\" – an UnknownReactive updated based on stored state and additional inputs.\n\nSee also Reactive.foldl].\n\nfoldl(f::Function, v0, inputs::UnknownReactive{T}...)\n\nArguments\n\nf::Function : the transformation function; the first argument is the stored state followed by one argument for each inputs argument\nv0 : initial value of the stored state\ninputs::UnknownReactive : signals to apply f to\n\nReturns\n\n::UnknownReactive\n\nExamples\n\nSee the definition of pre for an example.\n\n\n\n"
},

{
    "location": "api\\main.html#foldl-1",
    "page": "Building models",
    "title": "foldl",
    "category": "section",
    "text": "foldl"
},

{
    "location": "api\\main.html#Sims.@liftd",
    "page": "Building models",
    "title": "Sims.@liftd",
    "category": "Macro",
    "text": "A helper for an expression of UnknownReactive variables\n\n@liftd exp\n\nNote that the expression should not contain Unknowns. To mark the Discrete variables, enter them as Symbols. This uses lift().\n\nArguments\n\nexp : an expression, usually containing other Discrete variables\n\nReturns\n\n::Discrete : a signal\n\nExamples\n\nx = Discrete(true)\ny = Discrete(false)\nz = @liftd :x & !:y\n## equivalent to:\nz2 = lift((x, y) -> x & !y, x, y)\n\n\n\n"
},

{
    "location": "api\\main.html#@liftd-1",
    "page": "Building models",
    "title": "@liftd",
    "category": "section",
    "text": "@liftd"
},

{
    "location": "api\\main.html#Sims.pre",
    "page": "Building models",
    "title": "Sims.pre",
    "category": "Function",
    "text": "An UnknownReactive based on the previous value of x (normally prior to an event).\n\nSee also Event.\n\npre(x::UnknownReactive)\n\nArguments\n\nx::Discrete\n\nReturns\n\n::UnknownReactive\n\n\n\n"
},

{
    "location": "api\\main.html#pre-1",
    "page": "Building models",
    "title": "pre",
    "category": "section",
    "text": "pre"
},

{
    "location": "api\\main.html#Sims.Event",
    "page": "Building models",
    "title": "Sims.Event",
    "category": "Type",
    "text": "Event is the main type used for hybrid modeling. It contains a condition for root finding and model expressions to process after positive and negative root crossings are detected.\n\nSee also BoolEvent.\n\nEvent(condition::ModelType, pos_response, neg_response)\n\nArguments\n\ncondition::ModelType : an expression used for the event detection.\npos_response : an expression indicating what to do when the condition crosses zero positively. May be Model or MExpr.\nneg_response::Model : an expression indicating what to do when the condition crosses zero in the negative direction. Defaults to Equation[].\n\nExamples\n\nSee IdealThyristor in the standard library.\n\n\n\n"
},

{
    "location": "api\\main.html#Event-1",
    "page": "Building models",
    "title": "Event",
    "category": "section",
    "text": "Event"
},

{
    "location": "api\\main.html#Sims.BoolEvent",
    "page": "Building models",
    "title": "Sims.BoolEvent",
    "category": "Function",
    "text": "BoolEvent is a helper for attaching an event to a boolean variable. In conjunction with ifelse, this allows constructs like Modelica's if blocks.\n\nNote that the lengths of d and condition must match for arrays.\n\nBoolEvent(d::Discrete, condition::ModelType)\n\nArguments\n\nd::Discrete : the discrete variable.\ncondition::ModelType : the model expression(s) \n\nReturns\n\n::Event : a model Event\n\nExamples\n\nSee IdealDiode and Limiter in the standard library.\n\n\n\n"
},

{
    "location": "api\\main.html#BoolEvent-1",
    "page": "Building models",
    "title": "BoolEvent",
    "category": "section",
    "text": "BoolEvent"
},

{
    "location": "api\\main.html#Base.ifelse",
    "page": "Building models",
    "title": "Base.ifelse",
    "category": "Function",
    "text": "A function allowing if-then-else action for objections and expressions.\n\nNote that when this is used in a model, it does not trigger an event. You need to use Event or BoolEvent for that. It is used often in conjunction with Event.\n\nifelse(x, y)\nifelse(x, y, z)\n\nArguments\n\nx : the condition, a Bool or ModelType\ny : the value to return when true\nz : the value to return when false, defaults to nothing\n\nReturns\n\nEither y or z\n\nExamples\n\nSee DeadZone and Limiter in the standard library.\n\n\n\n"
},

{
    "location": "api\\main.html#ifelse-1",
    "page": "Building models",
    "title": "ifelse",
    "category": "section",
    "text": "ifelse"
},

{
    "location": "api\\main.html#Sims.StructuralEvent",
    "page": "Building models",
    "title": "Sims.StructuralEvent",
    "category": "Type",
    "text": "StructuralEvent defines a type for elements that change the structure of the model. An event is created where the condition crosses zero. When the event is triggered, the model is re-flattened after replacing default with new_relation in the model.\n\nStructuralEvent(condition::MExpr, default, new_relation::Function,\n                pos_response, neg_response)\n\nArguments\n\ncondition::MExpr : an expression that will trigger the event at a zero crossing\ndefault : the default Model used\nnew_relation : a function that returns a model that will replace the default model when the condition triggers the event.\npos_response : an expression indicating what to do when the condition crosses zero positively. Defaults to Equation[].\nneg_response::Model : an expression indicating what to do when the condition crosses zero in the negative direction. Defaults to Equation[].\n\nExamples\n\nHere is an example from examples/breaking_pendulum.jl:\n\nfunction FreeFall(x,y,vx,vy)\n    @equations begin\n        der(x) = vx\n        der(y) = vy\n        der(vx) = 0.0\n        der(vy) = -9.81\n    end\nend\n\nfunction Pendulum(x,y,vx,vy)\n    len = sqrt(x.value^2 + y.value^2)\n    phi0 = atan2(x.value, -y.value) \n    phi = Unknown(phi0)\n    phid = Unknown()\n    @equations begin\n        der(phi) = phid\n        der(x) = vx\n        der(y) = vy\n        x = len * sin(phi)\n        y = -len * cos(phi)\n        der(phid) = -9.81 / len * sin(phi)\n    end\nend\n\nfunction BreakingPendulum()\n    x = Unknown(cos(pi/4), \"x\")\n    y = Unknown(-cos(pi/4), \"y\")\n    vx = Unknown()\n    vy = Unknown()\n    Equation[\n        StructuralEvent(MTime - 5.0,     # when time hits 5 sec, switch to FreeFall\n            Pendulum(x,y,vx,vy),\n            () -> FreeFall(x,y,vx,vy))\n    ]\nend\n\np_y = sim(BreakingPendulum(), 6.0)  \n\n\n\n"
},

{
    "location": "api\\main.html#StructuralEvent-1",
    "page": "Building models",
    "title": "StructuralEvent",
    "category": "section",
    "text": "StructuralEvent"
},

{
    "location": "api\\main.html#Sims.@equations",
    "page": "Building models",
    "title": "Sims.@equations",
    "category": "Macro",
    "text": "A helper to make writing Models a little easier. It allows the use of = in model equations.\n\n@equations begin\n    ...\nend\n\nArguments\n\neq : the model equations, normally in a begin - end block.\n\nReturns\n\n::Array{Equation}\n\nExamples\n\nThe following are both equivalent:\n\nfunction Vanderpol1()\n    y = Unknown(1.0, \"y\")\n    x = Unknown(\"x\")\n    Equation[\n        der(x, -1.0) - ((1 - y^2) * x - y)      # == 0 is assumed\n        der(y) - x\n    ]\nend\nfunction Vanderpol2()\n    y = Unknown(1.0, \"y\") \n    x = Unknown(\"x\")\n    @equations begin\n        der(x, -1.0) = (1 - y^2) * x - y\n        der(y) = x\n    end\nend\n\n\n\n"
},

{
    "location": "api\\main.html#@equations-1",
    "page": "Building models",
    "title": "@equations",
    "category": "section",
    "text": "@equations"
},

{
    "location": "api\\sim.html#",
    "page": "Simulations",
    "title": "Simulations",
    "category": "page",
    "text": "CurrentModule = SimsPages = [\"sim.md\"]\nDepth = 5"
},

{
    "location": "api\\sim.html#Sims.dasslsim",
    "page": "Simulations",
    "title": "Sims.dasslsim",
    "category": "Function",
    "text": "The solver that uses DASKR, a variant of DASSL.\n\nSee sim for the interface.\n\n\n\n"
},

{
    "location": "api\\sim.html#dasslsim-1",
    "page": "Simulations",
    "title": "dasslsim",
    "category": "section",
    "text": "dasslsim"
},

{
    "location": "api\\sim.html#Sims.sunsim",
    "page": "Simulations",
    "title": "Sims.sunsim",
    "category": "Function",
    "text": "The solver that uses Sundials.\n\nSee sim for the interface.\n\n\n\n"
},

{
    "location": "api\\sim.html#sunsim-1",
    "page": "Simulations",
    "title": "sunsim",
    "category": "section",
    "text": "sunsim"
},

{
    "location": "api\\sim.html#Simulations-1",
    "page": "Simulations",
    "title": "Simulations",
    "category": "section",
    "text": "Various functions for simulations and building simulation objects from models."
},

{
    "location": "api\\sim.html#Sims.sim",
    "page": "Simulations",
    "title": "Sims.sim",
    "category": "Function",
    "text": "sim is the name of the default solver used to simulate Sims models and also shows the generic simulation API for available solvers (currently dasslsim and sunsim). The default solver is currently dasslsim if DASSL is available.\n\nsim has many method definitions to accomodate solutions based on intermediate model representations. Also, both positional and keyword arguments are supported (use one or the other after the first argument).\n\nsim(m::Model, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)\nsim(m::Model; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)\nsim(m::Sim, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)\nsim(m::Sim; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)\nsim(m::SimState, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)\nsim(m::SimState; tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool=true)\n\nArguments\n\nm::Model : a Model\nsm::Sim : a simulation object\nss::SimState : a simulation object\ntstop::Float64 : the simulation stopping time [secs], default = 1.0\nNsteps::Int : the number of simulation steps, default = 500\nreltol::Float64 : the relative tolerance, default = 1e-4\nabstol::Float64 : the absolute tolerance, default = 1e-4\ninit : initialization of the model; options include:\n:none : no initialization\n:Ya_Ydp :  given Y_d, calculate Y_a and Y'_d (the default)\n:Y :  given Y', calculate Y\nalg : indicates whether algebraic variables should be included in the error estimate (default is true)\n\nReturns\n\n::SimResult : the simulation result\n\nA number of optional packages can be used with results, including:\n\nWinston - plotting: plot(y::SimResult)\nGaston - plotting: gplot(y::SimResult) \nDataFrames - conversion to a DataFrame: convert(DataFrame, y::SimResult) \nGadfly - plotting: plot(y::SimResult, ...) \n\nFor each of these, the package must be installed, and the package pulled in with require or using.\n\nDetails\n\nThe main steps in converting to a model and doing a simulation are:\n\neqs::EquationSet = elaborate(m::Model)   # flatten the model\nsm::Sim = create_sim(eqs::EquationSet)   # prepare for simulation\nsm::SimState = create_simstate(sm::Sim)  # prepare for simulation II\ny::SimResult = sim(ss::SimState)         # simulate\n\nThe following are equivalent:\n\ny = sim(create_simstate(create_sim(elaborate(m))))\ny = sim(m)\n\nExample\n\nusing Sims\nfunction Vanderpol()\n    y = Unknown(1.0, \"y\")   # The 1.0 is the initial value. \"y\" is for plotting.\n    x = Unknown(\"x\")        # The initial value is zero if not given.\n    # The following gives the return value which is a list of equations.\n    # Expressions with Unknowns are kept as expressions. Expressions of\n    # regular variables are evaluated immediately (like normal).\n    @equations begin\n        # The -1.0 in der(x, -1.0) is the initial value for the derivative \n        der(x, -1.0) = (1 - y^2) * x - y \n        der(y) = x\n    end\nend\n\nv = Vanderpol()       # returns the hierarchical model\ny = sunsim(v, 50.0)\nusing Winston\nwplot(y)\n\n\n\n"
},

{
    "location": "api\\sim.html#sim-1",
    "page": "Simulations",
    "title": "sim",
    "category": "section",
    "text": "sim"
},

{
    "location": "api\\sim.html#Sims.EquationSet",
    "page": "Simulations",
    "title": "Sims.EquationSet",
    "category": "Type",
    "text": "A representation of a flattened model, normally created with elaborate(model). sim uses an elaborated model for simulations.\n\nContains the hierarchical equations, flattened equations, flattened initial equations, events, event response functions, and a map of Unknown nodes.\n\n\n\n"
},

{
    "location": "api\\sim.html#EquationSet-1",
    "page": "Simulations",
    "title": "EquationSet",
    "category": "section",
    "text": "EquationSet"
},

{
    "location": "api\\sim.html#Sims.elaborate",
    "page": "Simulations",
    "title": "Sims.elaborate",
    "category": "Function",
    "text": "elaborate is the main elaboration function that returns a flattened model representation that can be used by sim.\n\nelaborate(a::Model)\n\nArguments\n\na::Model : the input model\n\nReturns\n\n::EquationSet : the flattened model\n\nDetails\n\nThe main steps in flattening are:\n\nReplace fixed initial values.\nFlatten models and populate eq.equations.\nPull out InitialEquations and populate eq.initialequations\nPull out Events and populate eq.events.\nHandle StructuralEvents.\nCollect nodes and populate eq.nodeMap.\nStrip out MExpr's from expressions.\nRemove empty equations.\n\nThere is currently no real symbolic processing (sorting, index reduction, or any of the other stuff a fancy modeling tool would do).\n\nIn EquationSet, model contains equations and StructuralEvents. When a StructuralEvent triggers, the entire model is elaborated again. The first step is to replace StructuralEvents that have activated with their new_relation in model. Then, the rest of the EquationSet is reflattened using model as the starting point.\n\n\n\n"
},

{
    "location": "api\\sim.html#elaborate-1",
    "page": "Simulations",
    "title": "elaborate",
    "category": "section",
    "text": "elaborate"
},

{
    "location": "api\\sim.html#Sims.SimFunctions",
    "page": "Simulations",
    "title": "Sims.SimFunctions",
    "category": "Type",
    "text": "The set of functions used in the DAE solution. Includes an initial set of equations, a residual function, and several functions for detecting and responding to events.\n\nAll functions take (t,y,yp) as arguments. {TODO: is this still right?}\n\n\n\n"
},

{
    "location": "api\\sim.html#SimFunctions-1",
    "page": "Simulations",
    "title": "SimFunctions",
    "category": "section",
    "text": "SimFunctions"
},

{
    "location": "api\\sim.html#Sims.Sim",
    "page": "Simulations",
    "title": "Sims.Sim",
    "category": "Type",
    "text": "A type for holding several simulation objects needed for simulation, normally created with create_sim(eqs). \n\n\n\n"
},

{
    "location": "api\\sim.html#Sim-1",
    "page": "Simulations",
    "title": "Sim",
    "category": "section",
    "text": "Sim"
},

{
    "location": "api\\sim.html#Sims.SimState",
    "page": "Simulations",
    "title": "Sims.SimState",
    "category": "Type",
    "text": "The top level type for holding all simulation objects needed for simulation, including a Sim. Normally created with create_simstate(sim).\n\n\n\n"
},

{
    "location": "api\\sim.html#SimState-1",
    "page": "Simulations",
    "title": "SimState",
    "category": "section",
    "text": "SimState"
},

{
    "location": "api\\sim.html#Sims.create_sim",
    "page": "Simulations",
    "title": "Sims.create_sim",
    "category": "Function",
    "text": "create_sim converts a model to a Sim.\n\ncreate_sim(m::Model)\ncreate_sim(eq::EquationSet)\n\nArguments\n\nm::Model : a Model\neq::EquationSet : a flattened model\n\nReturns\n\n::Sim : a simulation object\n\n\n\n"
},

{
    "location": "api\\sim.html#create_sim-1",
    "page": "Simulations",
    "title": "create_sim",
    "category": "section",
    "text": "create_sim"
},

{
    "location": "api\\sim.html#Sims.create_simstate",
    "page": "Simulations",
    "title": "Sims.create_simstate",
    "category": "Function",
    "text": "create_simstate converts a Sim is the main conversion function that returns a SimState, a simulation object with state history.\n\ncreate_simstate(m::Model)\ncreate_simstate(eq::EquationSet)\ncreate_simstate(sm::Sim)\n\nArguments\n\nm::Model : a Model\neq::EquationSet : a flattened model\nsm::Sim : a simulation object\n\nReturns\n\n::Sim : a simulation object\n\n\n\n"
},

{
    "location": "api\\sim.html#create_simstate-1",
    "page": "Simulations",
    "title": "create_simstate",
    "category": "section",
    "text": "create_simstate"
},

{
    "location": "api\\sim.html#Sims.SimResult",
    "page": "Simulations",
    "title": "Sims.SimResult",
    "category": "Type",
    "text": "A type holding simulation results from sim, dasslsim, or sunsim. Includes a matrix of results and a vector of column names.\n\n\n\n"
},

{
    "location": "api\\sim.html#SimResult-1",
    "page": "Simulations",
    "title": "SimResult",
    "category": "section",
    "text": "SimResult"
},

{
    "location": "api\\utils.html#",
    "page": "Utilities",
    "title": "Utilities",
    "category": "page",
    "text": "CurrentModule = SimsPages = [\"utils.md\"]\nDepth = 5"
},

{
    "location": "api\\utils.html#Utilities-1",
    "page": "Utilities",
    "title": "Utilities",
    "category": "section",
    "text": "Several convenience methods are included for plotting, checking models, and converting results."
},

{
    "location": "api\\utils.html#Plotting-1",
    "page": "Utilities",
    "title": "Plotting",
    "category": "section",
    "text": ""
},

{
    "location": "api\\utils.html#Miscellaneous-1",
    "page": "Utilities",
    "title": "Miscellaneous",
    "category": "section",
    "text": ""
},

{
    "location": "api\\utils.html#Sims.@unknown",
    "page": "Utilities",
    "title": "Sims.@unknown",
    "category": "Macro",
    "text": "A macro to ease entry of many unknowns.\n\n@unknown a1 a2 a3 ...\n\nArguments\n\na : various representations of Unknowns:\nsymbol: equivalent to symbol = Unknown()\nsymbol(val): equivalent to symbol = Unknown(symbol, val)\nsymbol(x, y, z): equivalent to symbol = Unknown(x, y, z)\n\nFor `symbol(\n\nEffects\n\nCreates one or more Unknowns\n\n\n\n"
},

{
    "location": "api\\utils.html#@unknown-1",
    "page": "Utilities",
    "title": "@unknown",
    "category": "section",
    "text": "@unknown"
},

{
    "location": "api\\utils.html#Sims.check",
    "page": "Utilities",
    "title": "Sims.check",
    "category": "Function",
    "text": "Prints the number of equations and the number of unknowns.\n\ncheck(x)\n\nArguments\n\nx : a Model, EquationSet, Sim, or SimState\n\nReturns\n\nNvar : Number of floating point variables\nNeq : Number of equations\n\n\n\n"
},

{
    "location": "api\\utils.html#check-1",
    "page": "Utilities",
    "title": "check",
    "category": "section",
    "text": "check"
},

{
    "location": "api\\utils.html#Sims.initialize!",
    "page": "Utilities",
    "title": "Sims.initialize!",
    "category": "Function",
    "text": "Experimental function to initialize models.\n\ninitialize!(ss::SimState)\n\nArguments\n\nss::SimState : the SimState to be initialized\n\nReturns\n\n::JuMP.Model\n\nDetails\n\ninitialize! updates ss.y0 and ss.yp0 with values that satisfy the initial equations. If it does not converge, a warning is printed, and ss is not changed.\n\nJuMP.jl must be installed along with a nonlinear solver like Ipopt.jl or NLopt.jl. The JuMP model is set up without an objective function. Linear equality constraints are added for each fixed variable. Nonlinear equality constraints are added for each equation in the model (with some additional checking work, some of these could probably be converted to linear constraints).\n\nAlso, initialize! only works for scalar models. Models with Unknown vector components don't work. Internally, .* is replaced with *. It's rather kludgy, but right now, JuMP doesn't support .*. A better approach might be to fully flatten the model.\n\ninitialize! only runs at the beginning of simulations. It does not run after Events.\n\n\n\n"
},

{
    "location": "api\\utils.html#initialize!-1",
    "page": "Utilities",
    "title": "initialize!",
    "category": "section",
    "text": "initialize!"
},

{
    "location": "lib\\types.html#",
    "page": "The Sims standard library",
    "title": "The Sims standard library",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"types.md\"]\nDepth = 5"
},

{
    "location": "lib\\types.html#The-Sims-standard-library-1",
    "page": "The Sims standard library",
    "title": "The Sims standard library",
    "category": "section",
    "text": "These components are available with Sims.Lib.Normal usage is:using Sims\nusing Sims.Lib\n\n# modeling...Library components include models for:Electrical circuits\nPower system circuits\nHeat transfer\nRotational mechanicsMost of the components mimic those in the Modelica Standard Library.The main types for Unknowns and signals defined in Sims.Lib include:|                     | Flow/through variable | Node/across variable | Node helper type | | –––––––––- | ––––––––––- | –––––––––– | –––––––– | | Electrical systems  | Current             | Voltage            | ElectricalNode | | Heat transfer       | HeatFlow            | Temperature        | HeatPort       | | Mechanical rotation | Torque              | Angle              | Flange         |Each of the node-type variables have a helper type for quantities that can be Unknowns or objects.  For example, the type ElectricalNode is a Union type that can be a Voltage or a number. ElectricalNode is often used as the type for arguments to model functions to allow passing a Voltage node or a real value (like 0.0 for ground).The type Signal is also often used for a quantity that can be an Unknown or a concrete value.Most of the types and functions support Unknowns holding array values, and some support complex values."
},

{
    "location": "lib\\types.html#Basic-types-1",
    "page": "The Sims standard library",
    "title": "Basic types",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\types.html#Sims.Lib.NumberOrUnknown",
    "page": "The Sims standard library",
    "title": "Sims.Lib.NumberOrUnknown",
    "category": "Constant",
    "text": "NumberOrUnknown{T,C} is a typealias for Union{AbstractArray, Number, MExpr, RefUnknown{T}, Unknown{T,C}}.\n\nCan be an Unknown, an AbstractArray, a Number, or an MExpr. Useful where an object can be either an Unknown of a particular type or a real value, especially for use as a type in a model argument. It may be parameterized by an UnknownCategory, like NumberOrUnknown{UVoltage} (the definition of an ElectricalNode).\n\n\n\n"
},

{
    "location": "lib\\types.html#NumberOrUnknown-1",
    "page": "The Sims standard library",
    "title": "NumberOrUnknown",
    "category": "section",
    "text": "NumberOrUnknown"
},

{
    "location": "lib\\types.html#Sims.Lib.Signal",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Signal",
    "category": "Constant",
    "text": "Signal is a typealias for NumberOrUnknown{DefaultUnknown}.\n\nCan be an Unknown, an AbstractArray, a Number, or an MExpr.\n\n\n\n"
},

{
    "location": "lib\\types.html#Signal-1",
    "page": "The Sims standard library",
    "title": "Signal",
    "category": "section",
    "text": "Signal"
},

{
    "location": "lib\\types.html#Electrical-types-1",
    "page": "The Sims standard library",
    "title": "Electrical types",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\types.html#Sims.Lib.UVoltage",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UVoltage",
    "category": "Type",
    "text": "An UnknownCategory for electrical potential in volts.\n\n\n\n"
},

{
    "location": "lib\\types.html#UVoltage-1",
    "page": "The Sims standard library",
    "title": "UVoltage",
    "category": "section",
    "text": "UVoltage"
},

{
    "location": "lib\\types.html#Sims.Lib.UCurrent",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UCurrent",
    "category": "Type",
    "text": "An UnknownCategory for electrical current in amperes.\n\n\n\n"
},

{
    "location": "lib\\types.html#UCurrent-1",
    "page": "The Sims standard library",
    "title": "UCurrent",
    "category": "section",
    "text": "UCurrent"
},

{
    "location": "lib\\types.html#Sims.Lib.ElectricalNode",
    "page": "The Sims standard library",
    "title": "Sims.Lib.ElectricalNode",
    "category": "Constant",
    "text": "ElectricalNode is a typealias for NumberOrUnknown{UVoltage,Normal}.\n\nAn electrical node, either a Voltage (an Unknown) or a real value. Can include arrays or complex values. Used commonly as a model arguments for nodes. This allows nodes to be Unknowns or fixed values (like a ground that's zero volts).\n\n\n\n"
},

{
    "location": "lib\\types.html#ElectricalNode-1",
    "page": "The Sims standard library",
    "title": "ElectricalNode",
    "category": "section",
    "text": "ElectricalNode"
},

{
    "location": "lib\\types.html#Sims.Lib.Voltage",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Voltage",
    "category": "Type",
    "text": "Voltage is a typealias for Unknown{UVoltage,Normal}.\n\nElectrical potential with units of volts. Used as nodes and potential differences between nodes.\n\nOften used with ElectricalNode as a model argument.\n\n\n\n"
},

{
    "location": "lib\\types.html#Voltage-1",
    "page": "The Sims standard library",
    "title": "Voltage",
    "category": "section",
    "text": "Voltage"
},

{
    "location": "lib\\types.html#Sims.Lib.Current",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Current",
    "category": "Type",
    "text": "Current is a typealias for Unknown{UCurrent,Normal}.\n\nElectrical current with units of amperes. A flow variable.\n\n\n\n"
},

{
    "location": "lib\\types.html#Current-1",
    "page": "The Sims standard library",
    "title": "Current",
    "category": "section",
    "text": "Current"
},

{
    "location": "lib\\types.html#Thermal-types-1",
    "page": "The Sims standard library",
    "title": "Thermal types",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\types.html#Sims.Lib.UHeatPort",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UHeatPort",
    "category": "Type",
    "text": "An UnknownCategory for temperature in kelvin.\n\n\n\n"
},

{
    "location": "lib\\types.html#UHeatPort-1",
    "page": "The Sims standard library",
    "title": "UHeatPort",
    "category": "section",
    "text": "UHeatPort"
},

{
    "location": "lib\\types.html#Sims.Lib.UTemperature",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UTemperature",
    "category": "Type",
    "text": "An UnknownCategory for temperature in kelvin.\n\n\n\n"
},

{
    "location": "lib\\types.html#UTemperature-1",
    "page": "The Sims standard library",
    "title": "UTemperature",
    "category": "section",
    "text": "UTemperature"
},

{
    "location": "lib\\types.html#Sims.Lib.UHeatFlow",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UHeatFlow",
    "category": "Type",
    "text": "An UnknownCategory for heat flow rate in watts.\n\n\n\n"
},

{
    "location": "lib\\types.html#UHeatFlow-1",
    "page": "The Sims standard library",
    "title": "UHeatFlow",
    "category": "section",
    "text": "UHeatFlow"
},

{
    "location": "lib\\types.html#Sims.Lib.HeatPort",
    "page": "The Sims standard library",
    "title": "Sims.Lib.HeatPort",
    "category": "Constant",
    "text": "HeatPort is a typealias for NumberOrUnknown{UHeatPort,Normal}.\n\nA thermal node, either a Temperature (an Unknown) or a real value. Can include arrays. Used commonly as a model arguments for nodes. This allows nodes to be Unknowns or fixed values.\n\n\n\n"
},

{
    "location": "lib\\types.html#HeatPort-1",
    "page": "The Sims standard library",
    "title": "HeatPort",
    "category": "section",
    "text": "HeatPort"
},

{
    "location": "lib\\types.html#Sims.Lib.HeatFlow",
    "page": "The Sims standard library",
    "title": "Sims.Lib.HeatFlow",
    "category": "Type",
    "text": "HeatFlow is a typealias for Unknown{UHeatFlow,Normal}.\n\nHeat flow rate in units of watts.\n\n\n\n"
},

{
    "location": "lib\\types.html#HeatFlow-1",
    "page": "The Sims standard library",
    "title": "HeatFlow",
    "category": "section",
    "text": "HeatFlow"
},

{
    "location": "lib\\types.html#Sims.Lib.Temperature",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Temperature",
    "category": "Type",
    "text": "Temperature is a typealias for Unknown{UHeatPort,Normal}.\n\nA thermal potential, a Temperature (an Unknown) in units of kelvin.\n\n\n\n"
},

{
    "location": "lib\\types.html#Temperature-1",
    "page": "The Sims standard library",
    "title": "Temperature",
    "category": "section",
    "text": "Temperature"
},

{
    "location": "lib\\types.html#Rotational-types-1",
    "page": "The Sims standard library",
    "title": "Rotational types",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\types.html#Sims.Lib.UAngle",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UAngle",
    "category": "Type",
    "text": "An UnknownCategory for rotational angle in radians.\n\n\n\n"
},

{
    "location": "lib\\types.html#UAngle-1",
    "page": "The Sims standard library",
    "title": "UAngle",
    "category": "section",
    "text": "UAngle"
},

{
    "location": "lib\\types.html#Sims.Lib.UTorque",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UTorque",
    "category": "Type",
    "text": "An UnknownCategory for torque in newton-meters.\n\n\n\n"
},

{
    "location": "lib\\types.html#UTorque-1",
    "page": "The Sims standard library",
    "title": "UTorque",
    "category": "section",
    "text": "UTorque"
},

{
    "location": "lib\\types.html#Sims.Lib.Angle",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Angle",
    "category": "Type",
    "text": "Angle is a typealias for Unknown{UAngle,Normal}.\n\nThe angle in radians.\n\n\n\n"
},

{
    "location": "lib\\types.html#Angle-1",
    "page": "The Sims standard library",
    "title": "Angle",
    "category": "section",
    "text": "Angle"
},

{
    "location": "lib\\types.html#Sims.Lib.Torque",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Torque",
    "category": "Type",
    "text": "Torque is a typealias for Unknown{UTorque,Normal}.\n\nThe torque in newton-meters.\n\n\n\n"
},

{
    "location": "lib\\types.html#Torque-1",
    "page": "The Sims standard library",
    "title": "Torque",
    "category": "section",
    "text": "Torque"
},

{
    "location": "lib\\types.html#Sims.Lib.UAngularVelocity",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UAngularVelocity",
    "category": "Type",
    "text": "An UnknownCategory for angular velocity in radians/sec.\n\n\n\n"
},

{
    "location": "lib\\types.html#UAngularVelocity-1",
    "page": "The Sims standard library",
    "title": "UAngularVelocity",
    "category": "section",
    "text": "UAngularVelocity"
},

{
    "location": "lib\\types.html#Sims.Lib.AngularVelocity",
    "page": "The Sims standard library",
    "title": "Sims.Lib.AngularVelocity",
    "category": "Type",
    "text": "AngularVelocity is a typealias for Unknown{UAngularVelocity,Normal}.\n\nThe angular velocity in radians/sec.\n\n\n\n"
},

{
    "location": "lib\\types.html#AngularVelocity-1",
    "page": "The Sims standard library",
    "title": "AngularVelocity",
    "category": "section",
    "text": "AngularVelocity"
},

{
    "location": "lib\\types.html#Sims.Lib.UAngularAcceleration",
    "page": "The Sims standard library",
    "title": "Sims.Lib.UAngularAcceleration",
    "category": "Type",
    "text": "An UnknownCategory for angular acceleration in radians/sec^2.\n\n\n\n"
},

{
    "location": "lib\\types.html#UAngularAcceleration-1",
    "page": "The Sims standard library",
    "title": "UAngularAcceleration",
    "category": "section",
    "text": "UAngularAcceleration"
},

{
    "location": "lib\\types.html#Sims.Lib.AngularAcceleration",
    "page": "The Sims standard library",
    "title": "Sims.Lib.AngularAcceleration",
    "category": "Type",
    "text": "AngularAcceleration is a typealias for Unknown{UAngularAcceleration,Normal}.\n\nThe angular acceleration in radians/sec^2.\n\n\n\n"
},

{
    "location": "lib\\types.html#AngularAcceleration-1",
    "page": "The Sims standard library",
    "title": "AngularAcceleration",
    "category": "section",
    "text": "AngularAcceleration"
},

{
    "location": "lib\\types.html#Sims.Lib.Flange",
    "page": "The Sims standard library",
    "title": "Sims.Lib.Flange",
    "category": "Constant",
    "text": "Flange is a typealias for NumberOrUnknown{UAngle,Normal}.\n\nA rotational node, either an Angle (an Unknown) or a real value in radians. Can include arrays. Used commonly as a model argument for nodes. This allows nodes to be Unknowns or fixed values.  \n\n\n\n"
},

{
    "location": "lib\\types.html#Flange-1",
    "page": "The Sims standard library",
    "title": "Flange",
    "category": "section",
    "text": "Flange"
},

{
    "location": "lib\\kinetics.html#",
    "page": "Chemical kinetics",
    "title": "Chemical kinetics",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"kinetics.md\"]\nDepth = 5"
},

{
    "location": "lib\\kinetics.html#Chemical-kinetics-1",
    "page": "Chemical kinetics",
    "title": "Chemical kinetics",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\kinetics.html#Sims.Lib.ReactionEquation",
    "page": "Chemical kinetics",
    "title": "Sims.Lib.ReactionEquation",
    "category": "Function",
    "text": "Chemical kinetic reaction system\n\nReactionSystem(X, S, R, K)\n\nArguments\n\nX : State vector (array of unknowns N x 1)\nS : stoichiometric coefficients for reactants (array M x N)\nR : stoichiometric coefficients for products (array M x N)\nK : reaction rates (array M x 1)\n\nExample\n\nfunction concentration()\n\n    A0 = 0.25\n    rateA = 0.333\n    rateB = 0.16\n\n    X= { Unknown(A0), Unknown(0.0) }\n\n    S = [ [1, 0] [0, 1] ] ## stoichiometric coefficients for reactants\n    R = [ [0, 1] [1, 0] ] ## stoichiometric coefficients for products\n    K = [rateA , rateB] ## reaction rates\n    \n    return ReactionSystem(X, S, R, K)\n\nend\ny = sim(concentration())\n\n### Simple reaction syntax parser\n\nfunction simpleConcentration()\n\n    A0 = 0.25\n    rateA = 0.333\n    rateB = 0.16\n\n    A = Unknown(A0)\n    B = Unknown(0.0)\n    \n    reactions = Any[\n                     [ :-> A B rateA ]\n                     [ :-> B A rateB ]\n                   ]\n\n    return parse_reactions(reactions)\nend\n\ny = sim(simpleConcentration())\n\n\n\n"
},

{
    "location": "lib\\kinetics.html#ReactionEquation-1",
    "page": "Chemical kinetics",
    "title": "ReactionEquation",
    "category": "section",
    "text": "ReactionEquation"
},

{
    "location": "lib\\kinetics.html#Sims.Lib.parse_reactions",
    "page": "Chemical kinetics",
    "title": "Sims.Lib.parse_reactions",
    "category": "Function",
    "text": "Parses reactions of the form\n\nAny[ :-> a b rate ]\nAny[ :→ a b rate  ]\nAny[ :⇄ a b rate1 rate2 ]\n\nArguments\n\nV : Vector of reactions\n\nExample\n\n    A0 = 0.25\n    rateA = 0.333\n    rateB = 0.16\n\n    A = Unknown(A0)\n    B = Unknown(0.0)\n\n    reactions = Any[\n                     [ :⇄ A B rateA rateB ]\n                   ]\n\n    parse_reactions(reactions)\n\n\n\n"
},

{
    "location": "lib\\kinetics.html#parse_reactions-1",
    "page": "Chemical kinetics",
    "title": "parse_reactions",
    "category": "section",
    "text": "parse_reactions"
},

{
    "location": "lib\\blocks.html#",
    "page": "Control and signal blocks",
    "title": "Control and signal blocks",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"blocks.md\"]\nDepth = 5"
},

{
    "location": "lib\\blocks.html#Control-and-signal-blocks-1",
    "page": "Control and signal blocks",
    "title": "Control and signal blocks",
    "category": "section",
    "text": "These components are modeled after the Modelica.Blocks.* library."
},

{
    "location": "lib\\blocks.html#Continuous-linear-1",
    "page": "Control and signal blocks",
    "title": "Continuous linear",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\blocks.html#Sims.Lib.Integrator",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.Integrator",
    "category": "Function",
    "text": "Output the integral of the input signals\n\nIntegrator(u::Signal, y::Signal, k,       y_start = 0.0)\nIntegrator(u::Signal, y::Signal; k = 1.0, y_start = 0.0) # keyword arg version\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nk : integrator gains\ny_start : output initial value\n\n\n\n"
},

{
    "location": "lib\\blocks.html#Integrator-1",
    "page": "Control and signal blocks",
    "title": "Integrator",
    "category": "section",
    "text": "Integrator"
},

{
    "location": "lib\\blocks.html#Sims.Lib.Derivative",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.Derivative",
    "category": "Function",
    "text": "Approximated derivative block\n\nThis blocks defines the transfer function between the input u and the output y element-wise as the approximated derivative:\n\n             k[i] * s\n     y[i] = ------------ * u[i]\n            T[i] * s + 1\n\nIf you would like to be able to change easily between different transfer functions (FirstOrder, SecondOrder, ... ) by changing parameters, use the general block TransferFunction instead and model a derivative block with parameters as:\n\n    b = [k,0]; a = [T, 1]\n\nDerivative(u::Signal, y::Signal, T = 1.0, k = 1.0, x_start = 0.0, y_start = 0.0)\nDerivative(u::Signal, y::Signal; T = 1.0, k = 1.0, x_start = 0.0, y_start = 0.0)\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nk : gains\nT : Time constants [sec]\n\n\n\n"
},

{
    "location": "lib\\blocks.html#Derivative-1",
    "page": "Control and signal blocks",
    "title": "Derivative",
    "category": "section",
    "text": "Derivative"
},

{
    "location": "lib\\blocks.html#Sims.Lib.FirstOrder",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.FirstOrder",
    "category": "Function",
    "text": "First order transfer function block (= 1 pole)\n\nThis blocks defines the transfer function between the input u=inPort.signal and the output y=outPort.signal element-wise as first order system:\n\n               k[i]\n     y[i] = ------------ * u[i]\n            T[i] * s + 1\n\nIf you would like to be able to change easily between different transfer functions (FirstOrder, SecondOrder, ... ) by changing parameters, use the general block TransferFunction instead and model a derivative block with parameters as:\n\n    b = [k,0]; a = [T, 1]\n\nFirstOrder(u::Signal, y::Signal, T = 1.0, k = 1.0, y_start = 0.0)\nFirstOrder(u::Signal, y::Signal; T = 1.0, k = 1.0, y_start = 0.0)\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nk : gains\nT : Time constants [sec]\n\n\n\n"
},

{
    "location": "lib\\blocks.html#FirstOrder-1",
    "page": "Control and signal blocks",
    "title": "FirstOrder",
    "category": "section",
    "text": "FirstOrder"
},

{
    "location": "lib\\blocks.html#Sims.Lib.LimPID",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.LimPID",
    "category": "Function",
    "text": "PID controller with limited output, anti-windup compensation and setpoint weighting\n\n(Image: diagram)\n\nLimPID(u_s::Signal, u_m::Signal, y::Signal, \n       controllerType = \"PID\",\n       k = 1.0,      \n       Ti = 1.0,    \n       Td = 1.0,   \n       yMax = 1.0,   \n       yMin = -yMax, \n       wp = 1.0,     \n       wd = 0.0,     \n       Ni = 0.9,    \n       Nd = 10.0,    \n       xi_start = 0.0, \n       xd_start = 0.0,\n       y_start = 0.0)\nLimPID(u_s::Signal, u_m::Signal, y::Signal; \n       controllerType = \"PID\",\n       k = 1.0,      \n       Ti = 1.0,    \n       Td = 1.0,   \n       yMax = 1.0,   \n       yMin = -yMax, \n       wp = 1.0,     \n       wd = 0.0,     \n       Ni = 0.9,    \n       Nd = 10.0,    \n       xi_start = 0.0, \n       xd_start = 0.0,\n       y_start = 0.0)\n\nArguments\n\nu_s::Signal : input setpoint\nu_m::Signal : input measurement\ny_s::Signal : output\n\nKeyword/Optional Arguments\n\nk    : Gain of PID block                                  \nTi   : Time constant of Integrator block [s]\nTd   : Time constant of Derivative block [s]\nyMax : Upper limit of output\nyMin : Lower limit of output\nwp   : Set-point weight for Proportional block (0..1)\nwd   : Set-point weight for Derivative block (0..1)\nNi   : Ni*Ti is time constant of anti-windup compensation\nNd   : The higher Nd, the more ideal the derivative block\n\nDetails\n\nThis is a PID controller incorporating several practical aspects. It is designed according to chapter 3 of the book:\n\nK. Astroem, T. Haegglund: PID Controllers: Theory, Design, and Tuning. 2nd edition, 1995.\n\nBesides the additive proportional, integral and derivative part of this controller, the following practical aspects are included:\n\nThe output of this controller is limited. If the controller is in its limits, anti-windup compensation is activated to drive the integrator state to zero.\nThe high-frequency gain of the derivative part is limited to avoid excessive amplification of measurement noise.\nSetpoint weighting is present, which allows to weight the setpoint in the proportional and the derivative part independantly from the measurement. The controller will respond to load disturbances and measurement noise independantly of this setting (parameters wp, wd). However, setpoint changes will depend on this setting. For example, it is useful to set the setpoint weight wd for the derivative part to zero, if steps may occur in the setpoint signal.\n\n\n\n"
},

{
    "location": "lib\\blocks.html#LimPID-1",
    "page": "Control and signal blocks",
    "title": "LimPID",
    "category": "section",
    "text": "LimPID"
},

{
    "location": "lib\\blocks.html#Sims.Lib.StateSpace",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.StateSpace",
    "category": "Function",
    "text": "Linear state space system\n\nModelica.Blocks.Continuous.StateSpace Information\n\nThe State Space block defines the relation between the input u=inPort.signal and the output y=outPort.signal in state space form:\n\nder(x) = A * x + B * u\n    y  = C * x + D * u\n\nThe input is a vector of length nu, the output is a vector of length ny and nx is the number of states. Accordingly\n\n    A has the dimension: A(nx,nx), \n    B has the dimension: B(nx,nu), \n    C has the dimension: C(ny,nx), \n    D has the dimension: D(ny,nu)\n\nExample:\n\n     StateSpace(u, y; A = [0.12, 2; 3, 1.5], \n                      B = [2,    7; 3, 1],\n                      C = [0.1, 2],\n                      D = zeros(length(y),length(u)))\n\nresults in the following equations:\n\n  [der(x[1])]   [0.12  2.00] [x[1]]   [2.0  7.0] [u[1]]\n  [         ] = [          ]*[    ] + [        ]*[    ]\n  [der(x[2])]   [3.00  1.50] [x[2]]   [0.1  2.0] [u[2]]\n\n                             [x[1]]            [u[1]]\n       y[1]   = [0.1  2.0] * [    ] + [0  0] * [    ]\n                             [x[2]]            [u[2]]\n\nStateSpace(u::Signal, y::Signal, A = [1.0], B = [1.0], C = [1.0], D = [0.0])\nStateSpace(u::Signal, y::Signal; A = [1.0], B = [1.0], C = [1.0], D = [0.0])\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nA : Matrix A of state space model\nB : Vector B of state space model\nC : Vector C of state space model\nD : Matrix D of state space model\n\nDetails\n\nExample\n\n\n\nNOTE: untested / probably broken\n\n\n\n"
},

{
    "location": "lib\\blocks.html#StateSpace-1",
    "page": "Control and signal blocks",
    "title": "StateSpace",
    "category": "section",
    "text": "StateSpace"
},

{
    "location": "lib\\blocks.html#Sims.Lib.TransferFunction",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.TransferFunction",
    "category": "Function",
    "text": "Linear transfer function\n\nThis block defines the transfer function between the input u=inPort.signal[1] and the output y=outPort.signal[1] as (nb = dimension of b, na = dimension of a):\n\n           b[1]*s^[nb-1] + b[2]*s^[nb-2] + ... + b[nb]\n   y(s) = --------------------------------------------- * u(s)\n           a[1]*s^[na-1] + a[2]*s^[na-2] + ... + a[na]\n\nState variables x are defined according to controller canonical form. Initial values of the states can be set as start values of x.\n\nExample:\n\n     TransferFunction(u, y, b = [2,4], a = [1,3])\n\nresults in the following transfer function:\n\n        2*s + 4\n   y = --------- * u\n         s + 3\n\nTransferFunction(u::Signal, y::Signal, b = [1], a = [1])\nTransferFunction(u::Signal, y::Signal; b = [1], a = [1])\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nb : Numerator coefficients of transfer function\na : Denominator coefficients of transfer function\n\n\n\n"
},

{
    "location": "lib\\blocks.html#TransferFunction-1",
    "page": "Control and signal blocks",
    "title": "TransferFunction",
    "category": "section",
    "text": "TransferFunction"
},

{
    "location": "lib\\blocks.html#Nonlinear-1",
    "page": "Control and signal blocks",
    "title": "Nonlinear",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\blocks.html#Sims.Lib.Limiter",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.Limiter",
    "category": "Function",
    "text": "Limit the range of a signal\n\nThe Limiter block passes its input signal as output signal as long as the input is within the specified upper and lower limits. If this is not the case, the corresponding limits are passed as output.\n\nLimiter(u::Signal, y::Signal, uMax = 1.0, uMin = -uMax)\nLimiter(u::Signal, y::Signal; uMax = 1.0, uMin = -uMax)\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nuMax : upper limits of signals\nuMin : lower limits of signals\n\n\n\n"
},

{
    "location": "lib\\blocks.html#Limiter-1",
    "page": "Control and signal blocks",
    "title": "Limiter",
    "category": "section",
    "text": "Limiter"
},

{
    "location": "lib\\blocks.html#Sims.Lib.Step",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.Step",
    "category": "Function",
    "text": "Generate step signals of type Real\n\nStep(y::Signal, height = 1.0, offset = 0.0, startTime = 0.0)\nStep(y::Signal; height = 1.0, offset = 0.0, startTime = 0.0)\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nheight : heights of steps\noffset : offsets of output signals\nstartTime : output = offset for time < startTime [s]\n\n\n\n"
},

{
    "location": "lib\\blocks.html#Step-1",
    "page": "Control and signal blocks",
    "title": "Step",
    "category": "section",
    "text": "Step"
},

{
    "location": "lib\\blocks.html#Sims.Lib.DeadZone",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.DeadZone",
    "category": "Function",
    "text": "Provide a region of zero output\n\nThe DeadZone block defines a region of zero output.\n\nIf the input is within uMin ... uMax, the output is zero. Outside of this zone, the output is a linear function of the input with a slope of 1.\n\nDeadZone(u::Signal, y::Signal, uMax = 1.0, uMin = -uMax)\nDeadZone(u::Signal, y::Signal; uMax = 1.0, uMin = -uMax)\n\nArguments\n\nu::Signal : input\ny::Signal : output\n\nKeyword/Optional Arguments\n\nuMax : upper limits of signals\nuMin : lower limits of signals\n\n\n\n"
},

{
    "location": "lib\\blocks.html#DeadZone-1",
    "page": "Control and signal blocks",
    "title": "DeadZone",
    "category": "section",
    "text": "DeadZone"
},

{
    "location": "lib\\blocks.html#Sims.Lib.BooleanPulse",
    "page": "Control and signal blocks",
    "title": "Sims.Lib.BooleanPulse",
    "category": "Function",
    "text": "Generate a Discrete boolean pulse signal\n\nBooleanPulse(y, width = 50.0, period = 1.0, startTime = 0.0)\nBooleanPulse(y; width = 50.0, period = 1.0, startTime = 0.0)\n\nArguments\n\ny::Signal : output signal\n\nKeyword/Optional Arguments\n\nwidth : width of pulse in the percent of period [0 - 100]\nperiod : time for one period [sec]\nstartTime : time instant of the first pulse [sec]\n\n\n\n"
},

{
    "location": "lib\\blocks.html#BooleanPulse-1",
    "page": "Control and signal blocks",
    "title": "BooleanPulse",
    "category": "section",
    "text": "BooleanPulse"
},

{
    "location": "lib\\electrical.html#",
    "page": "Analog electrical models",
    "title": "Analog electrical models",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"electrical.md\"]\nDepth = 5"
},

{
    "location": "lib\\electrical.html#Analog-electrical-models-1",
    "page": "Analog electrical models",
    "title": "Analog electrical models",
    "category": "section",
    "text": "This library of components is modeled after the Modelica.Electrical.Analog library.Voltage nodes with type Voltage are the main Unknown type used in electrical circuits. voltage nodes can be single floating point unknowns representing a single voltage node. A Voltage can also be an array representing multiphase circuits or multiple node positions. Lastly, Voltage unknowns can also be complex for use with quasiphasor-type solutions.The type ElectricalNode is a Union type that can be an Array, a number, an expression, or an Unknown. This is used in model functions to allow passing a Voltage node or a real value (like 0.0 for ground).Examplefunction ex_ChuaCircuit()\n    n1 = Voltage(\"n1\")\n    n2 = Voltage(\"n2\")\n    n3 = Voltage(4.0, \"n3\")\n    g = 0.0\n    function NonlinearResistor(n1::ElectricalNode, n2::ElectricalNode, Ga, Gb, Ve)\n        i = Current(compatible_values(n1, n2))\n        v = Voltage(compatible_values(n1, n2))\n        @equations begin\n            Branch(n1, n2, v, i)\n            i = ifelse(v < -Ve, Gb .* (v + Ve) - Ga .* Ve,\n                       ifelse(v > Ve, Gb .* (v - Ve) + Ga*Ve, Ga*v))\n        end\n    end\n    @equations begin\n        Resistor(n1, g, 12.5e-3) \n        Inductor(n1, n2, 18.0)\n        Resistor(n2, n3, 1 / 0.565) \n        Capacitor(n2, g, 100.0)\n        Capacitor(n3, g, 10.0)\n        NonlinearResistor(n3, g, -0.757576, -0.409091, 1.0)\n    end\nend\n\ny = sim(ex_ChuaCircuit(), 200.0)\nwplot(y)"
},

{
    "location": "lib\\electrical.html#Basics-1",
    "page": "Analog electrical models",
    "title": "Basics",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\electrical.html#Sims.Lib.Resistor",
    "page": "Analog electrical models",
    "title": "Sims.Lib.Resistor",
    "category": "Function",
    "text": "The linear resistor connects the branch voltage v with the branch current i by i*R = v. The Resistance R is allowed to be positive, zero, or negative. \n\nResistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal)\nResistor(n1::ElectricalNode, n2::ElectricalNode, \n         R = 1.0, T = 293.15, T_ref = 300.15, alpha = 0.0)\nResistor(n1::ElectricalNode, n2::ElectricalNode;             # keyword-arg version\n         R = 1.0, T = 293.15, T_ref = 300.15, alpha = 0.0)\nResistor(n1::ElectricalNode, n2::ElectricalNode,\n         R::Signal, hp::Temperature, T_ref::Signal, alpha::Signal) \n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nR::Signal : Resistance at temperature T_ref [ohms], default = 1.0 ohms\nhp::HeatPort : Heat port [K], optional                \nT::HeatPort : Fixed device temperature or HeatPort [K], default = T_ref\nT_ref::Signal : Reference temperature [K], default = 300.15K\nalpha::Signal : Temperature coefficient of resistance (R_actual = R*(1 + alpha*(T_heatPort - T_ref))) [1/K], default = 0.0\n\nDetails\n\nThe resistance R is optionally temperature dependent according to the following equation:\n\nR = R_ref*(1 + alpha*(heatPort.T - T_ref))\n\nWith the optional hp HeatPort argument, the power will be dissipated into this HeatPort.\n\nThe resistance R can be a constant numeric value or an Unknown, meaning it can vary with time. Note: it is recommended that the R signal should not cross the zero value. Otherwise, depending on the surrounding circuit, the probability of singularities is high.\n\nThis device is vectorizable using array inputs for one or both of n1 and n2.\n\nExample\n\nfunction model()\n    n1 = Voltage(\"n1\")\n    g = 0.0\n    Equation[\n        SineVoltage(n1, g, 100.0)\n        Resistor(n1, g, R = 3.0, T = 330.0, alpha = 1.0)\n    ]\nend\ny = sim(model())\n\n\n\n"
},

{
    "location": "lib\\electrical.html#Resistor-1",
    "page": "Analog electrical models",
    "title": "Resistor",
    "category": "section",
    "text": "Resistor"
},

{
    "location": "lib\\electrical.html#Sims.Lib.Capacitor",
    "page": "Analog electrical models",
    "title": "Sims.Lib.Capacitor",
    "category": "Function",
    "text": "The linear capacitor connects the branch voltage v with the branch current i by i = C * dv/dt. \n\nCapacitor(n1::ElectricalNode, n2::ElectricalNode, C::Signal = 1.0) \nCapacitor(n1::ElectricalNode, n2::ElectricalNode; C::Signal = 1.0) \n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nC::Signal : Capacitance [F], default = 1.0 F\n\nDetails\n\nC can be a constant numeric value or an Unknown, meaning it can vary with time. If C is a constant, it may be positive, zero, or negative. If C is a signal, it should be greater than zero.\n\nThis device is vectorizable using array inputs for one or both of n1 and n2.\n\nExample\n\nfunction model()\n    n1 = Voltage(\"n1\")\n    g = 0.0\n    Equation[\n        SineVoltage(n1, g, 100.0)\n        Resistor(n1, g, 3.0)\n        Capacitor(n1, g, 1.0)\n    ]\nend\n\n\n\n"
},

{
    "location": "lib\\electrical.html#Capacitor-1",
    "page": "Analog electrical models",
    "title": "Capacitor",
    "category": "section",
    "text": "Capacitor"
},

{
    "location": "lib\\electrical.html#Sims.Lib.Inductor",
    "page": "Analog electrical models",
    "title": "Sims.Lib.Inductor",
    "category": "Function",
    "text": "The linear inductor connects the branch voltage v with the branch current i by v = L * di/dt. \n\nInductor(n1::ElectricalNode, n2::ElectricalNode, L::Signal = 1.0) \nInductor(n1::ElectricalNode, n2::ElectricalNode; L::Signal = 1.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nL::Signal : Inductance [H], default = 1.0 H\n\nDetails\n\nL can be a constant numeric value or an Unknown, meaning it can vary with time. If L is a constant, it may be positive, zero, or negative. If L is a signal, it should be greater than zero.\n\nThis device is vectorizable using array inputs for one or both of n1 and n2\n\nExample\n\nfunction model()\n    n1 = Voltage(\"n1\")\n    g = 0.0\n    Equation[\n        SineVoltage(n1, g, 100.0)\n        Resistor(n1, g, 3.0)\n        Inductor(n1, g, 6.0)\n    ]\nend\n\n\n\n"
},

{
    "location": "lib\\electrical.html#Inductor-1",
    "page": "Analog electrical models",
    "title": "Inductor",
    "category": "section",
    "text": "Inductor"
},

{
    "location": "lib\\electrical.html#Sims.Lib.SaturatingInductor",
    "page": "Analog electrical models",
    "title": "Sims.Lib.SaturatingInductor",
    "category": "Function",
    "text": "To be done...\n\nSaturatingInductor as implemented in the Modelica Standard Library depends on a Discrete value that is not fixed. This is not currently supported. Only Unknowns can currently be solved during initial conditions.\n\n\n\n"
},

{
    "location": "lib\\electrical.html#SaturatingInductor-1",
    "page": "Analog electrical models",
    "title": "SaturatingInductor",
    "category": "section",
    "text": "SaturatingInductor"
},

{
    "location": "lib\\electrical.html#Sims.Lib.Transformer",
    "page": "Analog electrical models",
    "title": "Sims.Lib.Transformer",
    "category": "Function",
    "text": "The transformer is a two port. The left port voltage v1, left port current i1, right port voltage v2 and right port current i2 are connected by the following relation:\n\n| v1 |         | L1   M  |  | i1' |\n|    |    =    |         |  |     |\n| v2 |         | M    L2 |  | i2' |\n\nL1, L2, and M are the primary, secondary, and coupling inductances respectively.\n\nTransformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode, \n            L1 = 1.0, L2 = 1.0, M = 1.0)\nTransformer(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode; \n            L1 = 1.0, L2 = 1.0, M = 1.0)\n\nArguments\n\np1::ElectricalNode : Positive electrical node of the left port (potential p1 > n1 for positive voltage drop v1) [V]\nn1::ElectricalNode : Negative electrical node of the left port [V]\np2::ElectricalNode : Positive electrical node of the right port (potential p2 > n2 for positive voltage drop v2) [V]\nn2::ElectricalNode : Negative electrical node of the right port [V]\n\nKeyword/Optional Arguments\n\nL1::Signal : Primary inductance [H], default = 1.0 H\nL2::Signal : Secondary inductance [H], default = 1.0 H\nM::Signal  : Coupling inductance [H], default = 1.0 H\n\n\n\n"
},

{
    "location": "lib\\electrical.html#Transformer-1",
    "page": "Analog electrical models",
    "title": "Transformer",
    "category": "section",
    "text": "Transformer"
},

{
    "location": "lib\\electrical.html#Sims.Lib.EMF",
    "page": "Analog electrical models",
    "title": "Sims.Lib.EMF",
    "category": "Function",
    "text": "EMF transforms electrical energy into rotational mechanical energy. It is used as basic building block of an electrical motor. The mechanical connector flange can be connected to elements of the rotational library. \n\nEMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange,\n    support_flange = 0.0, k = 1.0)\nEMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange;\n    support_flange = 0.0, k = 1.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nflange::Flange : Rotational shaft\n\nKeyword/Optional Arguments\n\nsupport_flange : Support/housing of the EMF shaft \nk : Transformation coefficient [N.m/A] \n\n\n\n"
},

{
    "location": "lib\\electrical.html#EMF-1",
    "page": "Analog electrical models",
    "title": "EMF",
    "category": "section",
    "text": "EMF"
},

{
    "location": "lib\\electrical.html#Ideal-1",
    "page": "Analog electrical models",
    "title": "Ideal",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\electrical.html#Sims.Lib.IdealDiode",
    "page": "Analog electrical models",
    "title": "Sims.Lib.IdealDiode",
    "category": "Function",
    "text": "This is an ideal switch which is open (off), if it is reversed biased (voltage drop less than 0) closed (on), if it is conducting (current > 0). This is the behaviour if all parameters are exactly zero. Note, there are circuits, where this ideal description with zero resistance and zero cinductance is not possible. In order to prevent singularities during switching, the opened diode has a small conductance Gon and the closed diode has a low resistance Roff which is default.\n\nThe parameter Vknee which is the forward threshold voltage, allows to displace the knee point along the Gon-characteristic until v = Vknee. \n\nIdealDiode(n1::ElectricalNode, n2::ElectricalNode, \n           Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)\nIdealDiode(n1::ElectricalNode, n2::ElectricalNode; \n           Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nVknee : Forward threshold voltage [V], default = 0.0\nRon : Closed diode resistance [Ohm], default = 1.E-5\nGoff : Opened diode conductance [S], default = 1.E-5\n\n\n\n"
},

{
    "location": "lib\\electrical.html#IdealDiode-1",
    "page": "Analog electrical models",
    "title": "IdealDiode",
    "category": "section",
    "text": "IdealDiode"
},

{
    "location": "lib\\electrical.html#Sims.Lib.IdealThyristor",
    "page": "Analog electrical models",
    "title": "Sims.Lib.IdealThyristor",
    "category": "Function",
    "text": "This is an ideal thyristor model which is open (off), if the voltage drop is less than 0 or fire is false closed (on), if the voltage drop is greater or equal 0 and fire is true.\n\nThis is the behaviour if all parameters are exactly zero. Note, there are circuits, where this ideal description with zero resistance and zero cinductance is not possible. In order to prevent singularities during switching, the opened thyristor has a small conductance Goff and the closed thyristor has a low resistance Ron which is default.\n\nThe parameter Vknee which is the forward threshold voltage, allows to displace the knee point along the Goff-characteristic until v = Vknee. \n\nIdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, \n               Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)\nIdealThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete; \n               Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nfire::Discrete : Discrete bool variable indicating firing of the thyristor\n\nKeyword/Optional Arguments\n\nVknee : Forward threshold voltage [V], default = 0.0\nRon : Closed thyristor resistance [Ohm], default = 1.E-5\nGoff : Opened thyristor conductance [S], default = 1.E-5\n\n\n\n"
},

{
    "location": "lib\\electrical.html#IdealThyristor-1",
    "page": "Analog electrical models",
    "title": "IdealThyristor",
    "category": "section",
    "text": "IdealThyristor"
},

{
    "location": "lib\\electrical.html#Sims.Lib.IdealGTOThyristor",
    "page": "Analog electrical models",
    "title": "Sims.Lib.IdealGTOThyristor",
    "category": "Function",
    "text": "This is an ideal GTO thyristor model which is open (off), if the voltage drop is less than 0 or fire is false closed (on), if the voltage drop is greater or equal 0 and fire is true.\n\nThis is the behaviour if all parameters are exactly zero.  Note, there are circuits, where this ideal description with zero resistance and zero cinductance is not possible. In order to prevent singularities during switching, the opened thyristor has a small conductance Goff and the closed thyristor has a low resistance Ron which is default.\n\nThe parameter Vknee which is the forward threshold voltage, allows to displace the knee point along the Goff-characteristic until v = Vknee.\n\nIdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete, \n                  Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)\nIdealGTOThyristor(n1::ElectricalNode, n2::ElectricalNode, fire::Discrete; \n                  Vknee = 0.0, Ron = 1e-5, Goff = 1e-5)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nfire::Discrete : Discrete bool variable indicating firing of the thyristor\n\nKeyword/Optional Arguments\n\nVknee : Forward threshold voltage [V], default = 0.0\nRon : Closed thyristor resistance [Ohm], default = 1.E-5\nGoff : Opened thyristor conductance [S], default = 1.E-5\n\n\n\n"
},

{
    "location": "lib\\electrical.html#IdealGTOThyristor-1",
    "page": "Analog electrical models",
    "title": "IdealGTOThyristor",
    "category": "section",
    "text": "IdealGTOThyristor"
},

{
    "location": "lib\\electrical.html#Sims.Lib.IdealOpAmp",
    "page": "Analog electrical models",
    "title": "Sims.Lib.IdealOpAmp",
    "category": "Function",
    "text": "The ideal OpAmp is a two-port device. The left port is fixed to v1=0 and i1=0 (nullator). At the right port, both any voltage v2 and any current i2 are possible (norator).\n\nThe ideal OpAmp with three pins is of exactly the same behaviour as the ideal OpAmp with four pins. Only the negative output pin is left out. Both the input voltage and current are fixed to zero (nullator). At the output pin both any voltage v2 and any current i2 are possible.\n\nIdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode, n2::ElectricalNode)\nIdealOpAmp(p1::ElectricalNode, n1::ElectricalNode, p2::ElectricalNode)\n\nArguments\n\np1::ElectricalNode : Positive electrical node of the left port (potential p1 > n1 for positive voltage drop v1) [V]\nn1::ElectricalNode : Negative electrical node of the left port [V]\np2::ElectricalNode : Positive electrical node of the right port (potential p2 > n2 for positive voltage drop v2) [V]\nn2::ElectricalNode : Negative electrical node of the right port [V], defaults to 0.0 V\n\n\n\n"
},

{
    "location": "lib\\electrical.html#IdealOpAmp-1",
    "page": "Analog electrical models",
    "title": "IdealOpAmp",
    "category": "section",
    "text": "IdealOpAmp"
},

{
    "location": "lib\\electrical.html#Sims.Lib.IdealOpeningSwitch",
    "page": "Analog electrical models",
    "title": "Sims.Lib.IdealOpeningSwitch",
    "category": "Function",
    "text": "The ideal opening switch has a positive pin p and a negative pin n. The switching behaviour is controlled by the input signal control. If control is true, pin p is not connected with negative pin n. Otherwise, pin p is connected with negative pin n.\n\nIn order to prevent singularities during switching, the opened switch has a (very low) conductance Goff and the closed switch has a (very low) resistance Ron. The limiting case is also allowed, i.e., the resistance Ron of the closed switch could be exactly zero and the conductance Goff of the open switch could be also exactly zero. Note, there are circuits, where a description with zero Ron or zero Goff is not possible.\n\nIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete,\n                   Ron = 1e-5, Goff = 1e-5)\nIdealOpeningSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete;\n                   Ron = 1e-5, Goff = 1e-5)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\ncontrol::Discrete : true => switch open, false => n1-n2 connected\n\nKeyword/Optional Arguments\n\nRon : Closed switch resistance [Ohm], default = 1.E-5\nGoff : Opened switch conductance [S], default = 1.E-5\n\n\n\n"
},

{
    "location": "lib\\electrical.html#IdealOpeningSwitch-1",
    "page": "Analog electrical models",
    "title": "IdealOpeningSwitch",
    "category": "section",
    "text": "IdealOpeningSwitch"
},

{
    "location": "lib\\electrical.html#Sims.Lib.IdealClosingSwitch",
    "page": "Analog electrical models",
    "title": "Sims.Lib.IdealClosingSwitch",
    "category": "Function",
    "text": "The ideal closing switch has a positive pin p and a negative pin n. The switching behaviour is controlled by input signal control. If control is true, pin p is connected with negative pin n. Otherwise, pin p is not connected with negative pin n.\n\nIn order to prevent singularities during switching, the opened switch has a (very low) conductance Goff and the closed switch has a (very low) resistance Ron. The limiting case is also allowed, i.e., the resistance Ron of the closed switch could be exactly zero and the conductance Goff of the open switch could be also exactly zero. Note, there are circuits, where a description with zero Ron or zero Goff is not possible.\n\nIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete,\n                   Ron = 1e-5, Goff = 1e-5)\nIdealClosingSwitch(n1::ElectricalNode, n2::ElectricalNode, control::Discrete;\n                   Ron = 1e-5, Goff = 1e-5)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\ncontrol::Discrete : true => n1-n2 connected, false => switch open\n\nKeyword/Optional Arguments\n\nRon : Closed switch resistance [Ohm], default = 1.E-5\nGoff : Opened switch conductance [S], default = 1.E-5\n\n\n\n"
},

{
    "location": "lib\\electrical.html#IdealClosingSwitch-1",
    "page": "Analog electrical models",
    "title": "IdealClosingSwitch",
    "category": "section",
    "text": "IdealClosingSwitch"
},

{
    "location": "lib\\electrical.html#Sims.Lib.ControlledIdealOpeningSwitch",
    "page": "Analog electrical models",
    "title": "Sims.Lib.ControlledIdealOpeningSwitch",
    "category": "Function",
    "text": "TBD\n\n\n\n"
},

{
    "location": "lib\\electrical.html#ControlledIdealOpeningSwitch-1",
    "page": "Analog electrical models",
    "title": "ControlledIdealOpeningSwitch",
    "category": "section",
    "text": "ControlledIdealOpeningSwitch"
},

{
    "location": "lib\\electrical.html#Sims.Lib.ControlledIdealClosingSwitch",
    "page": "Analog electrical models",
    "title": "Sims.Lib.ControlledIdealClosingSwitch",
    "category": "Function",
    "text": "TBD\n\n\n\n"
},

{
    "location": "lib\\electrical.html#ControlledIdealClosingSwitch-1",
    "page": "Analog electrical models",
    "title": "ControlledIdealClosingSwitch",
    "category": "section",
    "text": "ControlledIdealClosingSwitch"
},

{
    "location": "lib\\electrical.html#Sims.Lib.ControlledOpenerWithArc",
    "page": "Analog electrical models",
    "title": "Sims.Lib.ControlledOpenerWithArc",
    "category": "Function",
    "text": "This model is an extension to the IdealOpeningSwitch.\n\nThe basic model interupts the current through the switch in an infinitesimal time span. If an inductive circuit is connected, the voltage across the switch is limited only by numerics. In order to give a better idea for the voltage across the switch, a simple arc model is added:\n\nWhen the Boolean input control signals to open the switch, a voltage across the opened switch is impressed. This voltage starts with V0 (simulating the voltage drop of the arc roots), then rising with slope dVdt (simulating the rising voltage of an extending arc) until a maximum voltage Vmax is reached.\n\n     | voltage\nVmax |      +-----\n     |     /\n     |    /\nV0   |   +\n     |   |\n     +---+-------- time\n\nThis arc voltage tends to lower the current following through the switch; it depends on the connected circuit, when the arc is quenched. Once the arc is quenched, i.e., the current flowing through the switch gets zero, the equation for the off-state is activated i=Goff*v.\n\nWhen the Boolean input control signals to close the switch again, the switch is closed immediately, i.e., the equation for the on-state is activated v=Ron*i.\n\nPlease note: In an AC circuit, at least the arc quenches when the next natural zero-crossing of the current occurs. In a DC circuit, the arc will not quench if the arc voltage is not sufficient that a zero-crossing of the current occurs.\n\nThis model is the same as ControlledOpenerWithArc, but the switch is closed when control > level. \n\nControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control,\n                        level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)\nControlledOpenerWithArc(n1::ElectricalNode, n2::ElectricalNode, control;\n                        level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\ncontrol::Signal : control > level the switch is opened, otherwise closed\n\nKeyword/Optional Arguments\n\nlevel : Switch level [V], default = 0.5\nRon : Closed switch resistance [Ohm], default = 1.E-5\nGoff : Opened switch conductance [S], default = 1.E-5\nV0 : Initial arc voltage [V], default = 30.0\ndVdt : Arc voltage slope [V/s], default = 10e3\nVmax : Max. arc voltage [V], default = 60.0\n\n\n\n"
},

{
    "location": "lib\\electrical.html#ControlledOpenerWithArc-1",
    "page": "Analog electrical models",
    "title": "ControlledOpenerWithArc",
    "category": "section",
    "text": "ControlledOpenerWithArc"
},

{
    "location": "lib\\electrical.html#Sims.Lib.ControlledCloserWithArc",
    "page": "Analog electrical models",
    "title": "Sims.Lib.ControlledCloserWithArc",
    "category": "Function",
    "text": "This model is the same as ControlledOpenerWithArc, but the switch is closed when control > level. \n\nControlledCloserWithArc(n1::ElectricalNode, n2::ElectricalNode, control,\n                        level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)\nControlledCloserWithArc(n1::ElectricalNode, n2::ElectricalNode, control;\n                        level = 0.5,  Ron = 1e-5,  Goff = 1e-5,  V0 = 30.0,  dVdt = 10e3,  Vmax = 60.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\ncontrol::Signal : control > level the switch is closed, otherwise open\n\nKeyword/Optional Arguments\n\nlevel : Switch level [V], default = 0.5\nRon : Closed switch resistance [Ohm], default = 1.E-5\nGoff : Opened switch conductance [S], default = 1.E-5\nV0 : Initial arc voltage [V], default = 30.0\ndVdt : Arc voltage slope [V/s], default = 10e3\nVmax : Max. arc voltage [V], default = 60.0\n\n\n\n"
},

{
    "location": "lib\\electrical.html#ControlledCloserWithArc-1",
    "page": "Analog electrical models",
    "title": "ControlledCloserWithArc",
    "category": "section",
    "text": "ControlledCloserWithArc"
},

{
    "location": "lib\\electrical.html#Semiconductors-1",
    "page": "Analog electrical models",
    "title": "Semiconductors",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\electrical.html#Sims.Lib.Diode",
    "page": "Analog electrical models",
    "title": "Sims.Lib.Diode",
    "category": "Function",
    "text": "The simple diode is a one port. It consists of the diode itself and an parallel ohmic resistance R. The diode formula is:\n\ni  =  ids * ( e^(v/vt) - 1 )\n\nIf the exponent v/vt reaches the limit maxex, the diode characterisic is linearly continued to avoid overflow.\n\nDiode(n1::ElectricalNode, n2::ElectricalNode, \n      Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)\nDiode(n1::ElectricalNode, n2::ElectricalNode; \n      Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)\nDiode(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,\n      Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)\nDiode(n1::ElectricalNode, n2::ElectricalNode; hp::HeatPort;\n      Ids = 1e-6,  Vt = 0.04,  Maxexp = 15,  R = 1e8)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nhp::HeatPort : Heat port [K]                \n\nKeyword/Optional Arguments\n\nIds : Saturation current [A], default = 1.e-6\nVt : Voltage equivalent of temperature (kT/qn) [V], default = 0.04\nMaxexp : Max. exponent for linear continuation, default = 15.0\nR : Parallel ohmic resistance [Ohm], default = 1.e8\n\n\n\n"
},

{
    "location": "lib\\electrical.html#Diode-1",
    "page": "Analog electrical models",
    "title": "Diode",
    "category": "section",
    "text": "Diode"
},

{
    "location": "lib\\electrical.html#Sims.Lib.ZDiode",
    "page": "Analog electrical models",
    "title": "Sims.Lib.ZDiode",
    "category": "Function",
    "text": "TBD\n\n\n\n"
},

{
    "location": "lib\\electrical.html#ZDiode-1",
    "page": "Analog electrical models",
    "title": "ZDiode",
    "category": "section",
    "text": "ZDiode"
},

{
    "location": "lib\\electrical.html#Sims.Lib.HeatingDiode",
    "page": "Analog electrical models",
    "title": "Sims.Lib.HeatingDiode",
    "category": "Function",
    "text": "The simple diode is an electrical one port, where a heat port is added, which is defined in the Thermal library. It consists of the diode itself and an parallel ohmic resistance R. The diode formula is:\n\ni  =  ids * ( e^(v/vt_t) - 1 )\n\nwhere vt_t depends on the temperature of the heat port:\n\nvt_t = k*temp/q\n\nIf the exponent v/vt_t reaches the limit maxex, the diode characterisic is linearly continued to avoid overflow. The thermal power is calculated by i*v.\n\nHeatingDiode(n1::ElectricalNode, n2::ElectricalNode, \n             T = 293.15,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)\nHeatingDiode(n1::ElectricalNode, n2::ElectricalNode; \n             T = 293.15,  Ids = 1e-6,  Maxexp = 15,  R = 1e8,  EG = 1.11,  N = 1.0,  TNOM = 300.15,  XTI = 3.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nT : Heat port [K], default = 293.15\nIds : Saturation current [A], default = 1.e-6\nMaxexp : Max. exponent for linear continuation, default = 15.0\nR : Parallel ohmic resistance [Ohm], default = 1.e8\nEG : Activation energy, default = 1.11\nN : Emmission coefficient, default = 1.0\nTNOM : Parameter measurement temperature [K], default = 300.15\nXTI : Temperature exponent of saturation current, default = 3.0\n\n\n\n"
},

{
    "location": "lib\\electrical.html#HeatingDiode-1",
    "page": "Analog electrical models",
    "title": "HeatingDiode",
    "category": "section",
    "text": "HeatingDiode"
},

{
    "location": "lib\\electrical.html#Sources-1",
    "page": "Analog electrical models",
    "title": "Sources",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\electrical.html#Sims.Lib.SignalVoltage",
    "page": "Analog electrical models",
    "title": "Sims.Lib.SignalVoltage",
    "category": "Function",
    "text": "The signal voltage source is a parameterless converter of real valued signals into a source voltage.\n\nThis voltage source may be vectorized.\n\nSignalVoltage(n1::ElectricalNode, n2::ElectricalNode, V::Signal)  \n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nV::Signal : Voltage between n1 and n2 (= n1 - n2) as an input signal\n\n\n\n"
},

{
    "location": "lib\\electrical.html#SignalVoltage-1",
    "page": "Analog electrical models",
    "title": "SignalVoltage",
    "category": "section",
    "text": "SignalVoltage"
},

{
    "location": "lib\\electrical.html#Sims.Lib.SineVoltage",
    "page": "Analog electrical models",
    "title": "Sims.Lib.SineVoltage",
    "category": "Function",
    "text": "A sinusoidal voltage source. An offset parameter is introduced, which is added to the value calculated by the blocks source. The startTime parameter allows to shift the blocks source behavior on the time axis.\n\nThis voltage source may be vectorized.\n\nSineVoltage(n1::ElectricalNode, n2::ElectricalNode, \n            V = 1.0,  f = 1.0,  ang = 0.0,  offset = 0.0)\nSineVoltage(n1::ElectricalNode, n2::ElectricalNode; \n            V = 1.0,  f = 1.0,  ang = 0.0,  offset = 0.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nV : Amplitude of sine wave [V], default = 1.0\nphase : Phase of sine wave [rad], default = 0.0\nfreqHz : Frequency of sine wave [Hz], default = 1.0\noffset : Voltage offset [V], default = 0.0\nstartTime : Time offset [s], default = 0.0\n\n\n\n"
},

{
    "location": "lib\\electrical.html#SineVoltage-1",
    "page": "Analog electrical models",
    "title": "SineVoltage",
    "category": "section",
    "text": "SineVoltage"
},

{
    "location": "lib\\electrical.html#Sims.Lib.StepVoltage",
    "page": "Analog electrical models",
    "title": "Sims.Lib.StepVoltage",
    "category": "Function",
    "text": "A step voltage source. An event is introduced at the transition. Probably cannot be vectorized.\n\nStepVoltage(n1::ElectricalNode, n2::ElectricalNode, \n            V = 1.0,  start = 0.0,  offset = 0.0)\nStepVoltage(n1::ElectricalNode, n2::ElectricalNode; \n            V = 1.0,  start = 0.0,  offset = 0.0)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\n\nKeyword/Optional Arguments\n\nV : Height of step [V], default = 1.0\noffset : Voltage offset [V], default = 0.0\nstartTime : Time offset [s], default = 0.0\n\n\n\n"
},

{
    "location": "lib\\electrical.html#StepVoltage-1",
    "page": "Analog electrical models",
    "title": "StepVoltage",
    "category": "section",
    "text": "StepVoltage"
},

{
    "location": "lib\\electrical.html#Sims.Lib.SignalCurrent",
    "page": "Analog electrical models",
    "title": "Sims.Lib.SignalCurrent",
    "category": "Function",
    "text": "The signal current source is a parameterless converter of real valued signals into a current voltage.\n\nThis current source may be vectorized.\n\nSignalCurrent(n1::ElectricalNode, n2::ElectricalNode, I::Signal)  \n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nI::Signal : Current flowing from n1 to n2 as an input signal\n\n\n\n"
},

{
    "location": "lib\\electrical.html#SignalCurrent-1",
    "page": "Analog electrical models",
    "title": "SignalCurrent",
    "category": "section",
    "text": "SignalCurrent"
},

{
    "location": "lib\\electrical.html#Probes-1",
    "page": "Analog electrical models",
    "title": "Probes",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\electrical.html#Sims.Lib.SeriesProbe",
    "page": "Analog electrical models",
    "title": "Sims.Lib.SeriesProbe",
    "category": "Function",
    "text": "Connect a series current probe between two nodes. This is vectorizable.\n\nSeriesProbe(n1, n2, name::AbstractString)\n\nArguments\n\nn1 : Positive node\nn2 : Negative node\nname::AbstractString : The name of the probe\n\nExample\n\nfunction model()\n    n1 = Voltage(\"n1\")\n    n2 = Voltage()\n    g = 0.0\n    Equation[\n        SineVoltage(n1, g, 100.0)\n        SeriesProbe(n1, n2, \"current\")\n        Resistor(n2, g, 2.0)\n    ]\nend\ny = sim(model())\n\n\n\n"
},

{
    "location": "lib\\electrical.html#SeriesProbe-1",
    "page": "Analog electrical models",
    "title": "SeriesProbe",
    "category": "section",
    "text": "SeriesProbe"
},

{
    "location": "lib\\electrical.html#Sims.Lib.BranchHeatPort",
    "page": "Analog electrical models",
    "title": "Sims.Lib.BranchHeatPort",
    "category": "Function",
    "text": "Wrap argument model with a heat port that captures the power generated by the electrical device. This is vectorizable.\n\nBranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,\n               model::Function, args...)\n\nArguments\n\nn1::ElectricalNode : Positive electrical node [V]\nn2::ElectricalNode : Negative electrical node [V]\nhp::HeatPort : Heat port [K]                \nmodel::Function : Model to wrap\nargs... : Arguments passed to model  \n\nExamples\n\nHere's an example of a definition defining a Resistor that uses a heat port (a Temperature) in terms of another model:\n\nfunction Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal, hp::Temperature, T_ref::Signal, alpha::Signal) \n    BranchHeatPort(n1, n2, hp, Resistor, R .* (1 + alpha .* (hp - T_ref)))\nend\n\n\n\n"
},

{
    "location": "lib\\electrical.html#BranchHeatPort-1",
    "page": "Analog electrical models",
    "title": "BranchHeatPort",
    "category": "section",
    "text": "BranchHeatPort"
},

{
    "location": "lib\\heat_transfer.html#",
    "page": "Heat transfer models",
    "title": "Heat transfer models",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"heat_transfer.md\"]\nDepth = 5"
},

{
    "location": "lib\\heat_transfer.html#Heat-transfer-models-1",
    "page": "Heat transfer models",
    "title": "Heat transfer models",
    "category": "section",
    "text": "Library of 1-dimensional heat transfer with lumped elementsThese components are modeled after the Modelica.Thermal.HeatTransfer library.This package contains components to model 1-dimensional heat transfer with lumped elements. This allows especially to model heat transfer in machines provided the parameters of the lumped elements, such as the heat capacity of a part, can be determined by measurements (due to the complex geometries and many materials used in machines, calculating the lumped element parameters from some basic analytic formulas is usually not possible).Note, that all temperatures of this package, including initial conditions, are given in Kelvin."
},

{
    "location": "lib\\heat_transfer.html#Basics-1",
    "page": "Heat transfer models",
    "title": "Basics",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.HeatCapacitor",
    "page": "Heat transfer models",
    "title": "Sims.Lib.HeatCapacitor",
    "category": "Function",
    "text": "Lumped thermal element storing heat\n\nHeatCapacitor(hp::HeatPort, C::Signal)\n\nArguments\n\nhp::HeatPort : heat port [K]\nC::Signal : heat capacity of the element [J/K]\n\nDetails\n\nThis is a generic model for the heat capacity of a material. No specific geometry is assumed beyond a total volume with uniform temperature for the entire volume. Furthermore, it is assumed that the heat capacity is constant (indepedent of temperature).\n\nThis component may be used for complicated geometries where the heat capacity C is determined my measurements. If the component consists mainly of one type of material, the mass m of the component may be measured or calculated and multiplied with the specific heat capacity cp of the component material to compute C:\n\n   C = cp*m.\n   Typical values for cp at 20 degC in J/(kg.K):\n      aluminium   896\n      concrete    840\n      copper      383\n      iron        452\n      silver      235\n      steel       420 ... 500 (V2A)\n      wood       2500\n\nNOTE: The Modelica Standard Library has an argument Tstart for the starting temperature [K]. You really can't used that here as in Modelica. You need to define the starting temperature at the top level for the HeatPort you define.\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#HeatCapacitor-1",
    "page": "Heat transfer models",
    "title": "HeatCapacitor",
    "category": "section",
    "text": "HeatCapacitor"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.ThermalConductor",
    "page": "Heat transfer models",
    "title": "Sims.Lib.ThermalConductor",
    "category": "Function",
    "text": "Lumped thermal element transporting heat without storing it\n\nThermalConductor(port_a::HeatPort, port_b::HeatPort, G::Signal)\n\nArguments\n\nport_a::HeatPort : heat port [K]\nport_b::HeatPort : heat port [K]\nG::Signal : Constant thermal conductance of material [W/K]\n\nDetails\n\nThis is a model for transport of heat without storing it. It may be used for complicated geometries where the thermal conductance G (= inverse of thermal resistance) is determined by measurements and is assumed to be constant over the range of operations. If the component consists mainly of one type of material and a regular geometry, it may be calculated, e.g., with one of the following equations:\n\nConductance for a box geometry under the assumption that heat flows along the box length:\n\n        G = k*A/L\n        k: Thermal conductivity (material constant)\n        A: Area of box\n        L: Length of box\n\nConductance for a cylindrical geometry under the assumption that heat flows from the inside to the outside radius of the cylinder:\n\n    G = 2*pi*k*L/log(r_out/r_in)\n    pi   : Modelica.Constants.pi\n    k    : Thermal conductivity (material constant)\n    L    : Length of cylinder\n    log  : Modelica.Math.log;\n    r_out: Outer radius of cylinder\n    r_in : Inner radius of cylinder\n\nTypical values for k at 20 degC in W/(m.K):\n\n      aluminium   220\n      concrete      1\n      copper      384\n      iron         74\n      silver      407\n      steel        45 .. 15 (V2A)\n      wood         0.1 ... 0.2\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#ThermalConductor-1",
    "page": "Heat transfer models",
    "title": "ThermalConductor",
    "category": "section",
    "text": "ThermalConductor"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.Convection",
    "page": "Heat transfer models",
    "title": "Sims.Lib.Convection",
    "category": "Function",
    "text": "Lumped thermal element for heat convection\n\nConvection(port_a::HeatPort, port_b::HeatPort, Gc::Signal)\n\nArguments\n\nport_a::HeatPort : heat port [K]\nport_b::HeatPort : heat port [K]\nGc::Signal : convective thermal conductance [W/K]\n\nDetails\n\nThis is a model of linear heat convection, e.g., the heat transfer between a plate and the surrounding air. It may be used for complicated solid geometries and fluid flow over the solid by determining the convective thermal conductance Gc by measurements. The basic constitutive equation for convection is\n\n   Q_flow = Gc*(solidT - fluidT)\n   Q_flow: Heat flow rate from connector 'solid' (e.g. a plate)\n      to connector 'fluid' (e.g. the surrounding air)\n\nGc is an input signal to the component, since Gc is nearly never constant in practice. For example, Gc may be a function of the speed of a cooling fan. For simple situations, Gc may be calculated according to\n\n   Gc = A*h\n   A: Convection area (e.g. perimeter*length of a box)\n   h: Heat transfer coefficient\n\nwhere the heat transfer coefficient h is calculated from properties of the fluid flowing over the solid. Examples:\n\nMachines cooled by air (empirical, very rough approximation according to R. Fischer: Elektrische Maschinen, 10th edition, Hanser-Verlag 1999, p. 378):\n\n    h = 7.8*v^0.78 [W/(m2.K)] (forced convection)\n      = 12         [W/(m2.K)] (free convection)\n    where\n      v: Air velocity in [m/s]\n\nLaminar flow with constant velocity of a fluid along a flat plate where the heat flow rate from the plate to the fluid (= solid.Q_flow) is kept constant (according to J.P.Holman: Heat Transfer, 8th edition, McGraw-Hill, 1997, p.270):\n\n   h  = Nu*k/x;\n   Nu = 0.453*Re^(1/2)*Pr^(1/3);\n   where\n      h  : Heat transfer coefficient\n      Nu : = h*x/k       (Nusselt number)\n      Re : = v*x*rho/mue (Reynolds number)\n      Pr : = cp*mue/k    (Prandtl number)\n      v  : Absolute velocity of fluid\n      x  : distance from leading edge of flat plate\n      rho: density of fluid (material constant\n      mue: dynamic viscosity of fluid (material constant)\n      cp : specific heat capacity of fluid (material constant)\n      k  : thermal conductivity of fluid (material constant)\n   and the equation for h holds, provided\n      Re < 5e5 and 0.6 < Pr < 50\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#Convection-1",
    "page": "Heat transfer models",
    "title": "Convection",
    "category": "section",
    "text": "Convection"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.BodyRadiation",
    "page": "Heat transfer models",
    "title": "Sims.Lib.BodyRadiation",
    "category": "Function",
    "text": "BodyRadiation(port_a::HeatPort, port_b::HeatPort, Gr::Signal)\n\nArguments\n\nport_a::HeatPort : heat port [K]\nport_b::HeatPort : heat port [K]\nGr::Signal : net radiation conductance between two surfaces [m2]\n\nDetails\n\nThis is a model describing the thermal radiation, i.e., electromagnetic radiation emitted between two bodies as a result of their temperatures. The following constitutive equation is used:\n\n    Q_flow = Gr*sigma*(port_a^4 - port_b.4)\n\nwhere Gr is the radiation conductance and sigma is the Stefan-Boltzmann constant. Gr may be determined by measurements and is assumed to be constant over the range of operations.\n\nFor simple cases, Gr may be analytically computed. The analytical equations use epsilon, the emission value of a body which is in the range 0..1. Epsilon=1, if the body absorbs all radiation (= black body). Epsilon=0, if the body reflects all radiation and does not absorb any.\n\n   Typical values for epsilon:\n   aluminium, polished    0.04\n   copper, polished       0.04\n   gold, polished         0.02\n   paper                  0.09\n   rubber                 0.95\n   silver, polished       0.02\n   wood                   0.85..0.9\n\nAnalytical Equations for Gr\n\nSmall convex object in large enclosure (e.g., a hot machine in a room):\n\n    Gr = e*A\n    where\n       e: Emission value of object (0..1)\n       A: Surface area of object where radiation\n          heat transfer takes place\n\nTwo parallel plates:\n\n    Gr = A/(1/e1 + 1/e2 - 1)\n    where\n       e1: Emission value of plate1 (0..1)\n       e2: Emission value of plate2 (0..1)\n       A : Area of plate1 (= area of plate2)\n\nTwo long cylinders in each other, where radiation takes place from the inner to the outer cylinder):\n\n    Gr = 2*pi*r1*L/(1/e1 + (1/e2 - 1)*(r1/r2))\n    where\n       pi: = Modelica.Constants.pi\n       r1: Radius of inner cylinder\n       r2: Radius of outer cylinder\n       L : Length of the two cylinders\n       e1: Emission value of inner cylinder (0..1)\n       e2: Emission value of outer cylinder (0..1)\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#BodyRadiation-1",
    "page": "Heat transfer models",
    "title": "BodyRadiation",
    "category": "section",
    "text": "BodyRadiation"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.ThermalCollector",
    "page": "Heat transfer models",
    "title": "Sims.Lib.ThermalCollector",
    "category": "Function",
    "text": "This is a model to collect the heat flows from m heatports to one single heatport.\n\nThermalCollector(port_a::HeatPort, port_b::HeatPort)\n\nArguments\n\nport_a::HeatPort : heat port [K]\nport_b::HeatPort : heat port [K]\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#ThermalCollector-1",
    "page": "Heat transfer models",
    "title": "ThermalCollector",
    "category": "section",
    "text": "ThermalCollector"
},

{
    "location": "lib\\heat_transfer.html#Sources-1",
    "page": "Heat transfer models",
    "title": "Sources",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.FixedTemperature",
    "page": "Heat transfer models",
    "title": "Sims.Lib.FixedTemperature",
    "category": "Function",
    "text": "Fixed temperature boundary condition in Kelvin\n\nThis model defines a fixed temperature T at its port in Kelvin, i.e., it defines a fixed temperature as a boundary condition.\n\n(Note that despite the name, the temperature can be fixed or variable. FixedTemperature and PrescribedTemperature are identical; naming is for Modelica compatibility.)\n\nFixedTemperature(port::HeatPort, T::Signal)\n\nArguments\n\nport::HeatPort : heat port [K]\nT::Signal : temperature at port [K]\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#FixedTemperature-1",
    "page": "Heat transfer models",
    "title": "FixedTemperature",
    "category": "section",
    "text": "FixedTemperature"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.PrescribedTemperature",
    "page": "Heat transfer models",
    "title": "Sims.Lib.PrescribedTemperature",
    "category": "Function",
    "text": "Variable temperature boundary condition in Kelvin\n\nThis model represents a variable temperature boundary condition. The temperature in [K] is given as input signal T to the model. The effect is that an instance of this model acts as an infinite reservoir able to absorb or generate as much energy as required to keep the temperature at the specified value.\n\n(Note that despite the name, the temperature can be fixed or variable. FixedTemperature and PrescribedTemperature are identical; naming is for Modelica compatibility.)\n\nPrescribedTemperature(port::HeatPort, T::Signal)\n\nArguments\n\nport::HeatPort : heat port [K]\nT::Signal : temperature at port [K]\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#PrescribedTemperature-1",
    "page": "Heat transfer models",
    "title": "PrescribedTemperature",
    "category": "section",
    "text": "PrescribedTemperature"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.FixedHeatFlow",
    "page": "Heat transfer models",
    "title": "Sims.Lib.FixedHeatFlow",
    "category": "Function",
    "text": "Fixed heat flow boundary condition\n\nThis model allows a specified amount of heat flow rate to be \"injected\" into a thermal system at a given port. The constant amount of heat flow rate Q_flow is given as a parameter. The heat flows into the component to which the component FixedHeatFlow is connected, if parameter Q_flow is positive.\n\nIf parameter alpha is > 0, the heat flow is mulitplied by (1 + alpha*(port - T_ref)) in order to simulate temperature dependent losses (which are given an reference temperature T_ref).\n\n(Note that despite the name, the heat flow can be fixed or variable.)\n\nFixedHeatFlow(port::HeatPort, Q_flow::Signal, T_ref::Signal = 293.15, alpha::Signal = 0.0)\nFixedHeatFlow(port::HeatPort, Q_flow::Signal; T_ref::Signal = 293.15, alpha::Signal = 0.0)\n\nArguments\n\nport::HeatPort : heat port [K]\nQ_flow::Signal : heat flow [W]\n\nKeyword/Optional Arguments\n\nT_ref::Signal : reference temperature [K]\nalpha::Signal : temperature coefficient of heat flow rate [1/K]\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#FixedHeatFlow-1",
    "page": "Heat transfer models",
    "title": "FixedHeatFlow",
    "category": "section",
    "text": "FixedHeatFlow"
},

{
    "location": "lib\\heat_transfer.html#Sims.Lib.PrescribedHeatFlow",
    "page": "Heat transfer models",
    "title": "Sims.Lib.PrescribedHeatFlow",
    "category": "Function",
    "text": "Prescribed heat flow boundary condition\n\nThis model allows a specified amount of heat flow rate to be \"injected\" into a thermal system at a given port. The constant amount of heat flow rate Q_flow is given as a parameter. The heat flows into the component to which the component PrescribedHeatFlow is connected, if parameter Q_flow is positive.\n\nIf parameter alpha is > 0, the heat flow is mulitplied by (1 + alpha*(port - T_ref)) in order to simulate temperature dependent losses (which are given an reference temperature T_ref).\n\n(Note that despite the name, the heat flow can be fixed or variable.)\n\nPrescribedHeatFlow(port::HeatPort, Q_flow::Signal, T_ref::Signal = 293.15, alpha::Signal = 0.0)\nPrescribedHeatFlow(port::HeatPort, Q_flow::Signal; T_ref::Signal = 293.15, alpha::Signal = 0.0)\n\nArguments\n\nport::HeatPort : heat port [K]\nQ_flow::Signal : heat flow [W]\n\nKeyword/Optional Arguments\n\nT_ref::Signal : reference temperature [K]\nalpha::Signal : temperature coefficient of heat flow rate [1/K]\n\n\n\n"
},

{
    "location": "lib\\heat_transfer.html#PrescribedHeatFlow-1",
    "page": "Heat transfer models",
    "title": "PrescribedHeatFlow",
    "category": "section",
    "text": "PrescribedHeatFlow"
},

{
    "location": "lib\\powersystems.html#",
    "page": "Power systems models",
    "title": "Power systems models",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"powersystems.md\"]\nDepth = 5"
},

{
    "location": "lib\\powersystems.html#Power-systems-models-1",
    "page": "Power systems models",
    "title": "Power systems models",
    "category": "section",
    "text": "This includes experimental methods for modeling power systems.Under construction"
},

{
    "location": "lib\\powersystems.html#Sims.Lib.RLLine",
    "page": "Power systems models",
    "title": "Sims.Lib.RLLine",
    "category": "Function",
    "text": "R-L line model\n\nRLLine(n1::ElectricalNode, n2::ElectricalNode, Z::SeriesImpedance, len::Real, freq::Real)\n\n\n\n"
},

{
    "location": "lib\\powersystems.html#RLLine-1",
    "page": "Power systems models",
    "title": "RLLine",
    "category": "section",
    "text": "RLLine"
},

{
    "location": "lib\\powersystems.html#Sims.Lib.PiLine",
    "page": "Power systems models",
    "title": "Sims.Lib.PiLine",
    "category": "Function",
    "text": "PI line model\n\nPiLine(n1::ElectricalNode, n2::ElectricalNode, Z::SeriesImpedance, Y::ShuntAdmittance, len::Real, freq::Real, ne::Int)\n\n\n\n"
},

{
    "location": "lib\\powersystems.html#PiLine-1",
    "page": "Power systems models",
    "title": "PiLine",
    "category": "section",
    "text": "PiLine"
},

{
    "location": "lib\\powersystems.html#Sims.Lib.ModalLine",
    "page": "Power systems models",
    "title": "Sims.Lib.ModalLine",
    "category": "Function",
    "text": "Modal line model\n\nModalLine(v1::ElectricalNode, v2::ElectricalNode, Z::SeriesImpedance, Y::ShuntAdmittance, len::Real, freq::Real)\n\n\n\n"
},

{
    "location": "lib\\powersystems.html#ModalLine-1",
    "page": "Power systems models",
    "title": "ModalLine",
    "category": "section",
    "text": "ModalLine"
},

{
    "location": "lib\\rotational.html#",
    "page": "Rotational mechanics",
    "title": "Rotational mechanics",
    "category": "page",
    "text": "CurrentModule = Sims.LibPages = [\"rotational.md\"]\nDepth = 5"
},

{
    "location": "lib\\rotational.html#Rotational-mechanics-1",
    "page": "Rotational mechanics",
    "title": "Rotational mechanics",
    "category": "section",
    "text": "Library to model 1-dimensional, rotational mechanical systemsRotational provides 1-dimensional, rotational mechanical components to model in a convenient way drive trains with frictional losses.These components are modeled after the Modelica.Mechanics.Rotational library.NOTE: these need more testing."
},

{
    "location": "lib\\rotational.html#Sims.Lib.Inertia",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.Inertia",
    "category": "Function",
    "text": "1D-rotational component with inertia\n\nRotational component with inertia at a flange (or between two rigidly connected flanges).\n\nInertia(flange_a::Flange, J::Real)\nInertia(flange_a::Flange, flange_b::Flange, J::Real)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\nJ::Real : Moment of inertia [kg.m^2]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#Inertia-1",
    "page": "Rotational mechanics",
    "title": "Inertia",
    "category": "section",
    "text": "Inertia"
},

{
    "location": "lib\\rotational.html#Sims.Lib.Disc",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.Disc",
    "category": "Function",
    "text": "1-dim. rotational rigid component without inertia, where right flange is rotated by a fixed angle with respect to left flange\n\nRotational component with two rigidly connected flanges without inertia. The right flange is rotated by the fixed angle \"deltaPhi\" with respect to the left flange.\n\nDisc(flange_a::Flange, flange_b::Flange, deltaPhi)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\ndeltaPhi::Signal : rotation of left flange with respect to right flange (= flange_b - flange_a) [rad]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#Disc-1",
    "page": "Rotational mechanics",
    "title": "Disc",
    "category": "section",
    "text": "Disc"
},

{
    "location": "lib\\rotational.html#Sims.Lib.Spring",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.Spring",
    "category": "Function",
    "text": "Linear 1D rotational spring\n\nA linear 1D rotational spring. The component can be connected either between two inertias/gears to describe the shaft elasticity, or between a inertia/gear and the housing (component Fixed), to describe a coupling of the element with the housing via a spring.\n\nSpring(flange_a::Flange, flange_b::Flange, c::Real, phi_rel0 = 0.0)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\nc: spring constant [N.m/rad]\nphi_rel0 : unstretched spring angle [rad]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#Spring-1",
    "page": "Rotational mechanics",
    "title": "Spring",
    "category": "section",
    "text": "Spring"
},

{
    "location": "lib\\rotational.html#Sims.Lib.Damper",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.Damper",
    "category": "Function",
    "text": "Linear 1D rotational damper\n\nLinear, velocity dependent damper element. It can be either connected between an inertia or gear and the housing (component Fixed), or between two inertia/gear elements.\n\nDamper(flange_a::Flange, flange_b::Flange, d::Signal)\nDamper(flange_a::Flange, flange_b::Flange, hp::HeatPort, d::Signal)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\nhp::HeatPort : heat port [K]\nd: 	damping constant [N.m.s/rad]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#Damper-1",
    "page": "Rotational mechanics",
    "title": "Damper",
    "category": "section",
    "text": "Damper"
},

{
    "location": "lib\\rotational.html#Sims.Lib.SpringDamper",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.SpringDamper",
    "category": "Function",
    "text": "Linear 1D rotational spring and damper in parallel\n\nA spring and damper element connected in parallel. The component can be connected either between two inertias/gears to describe the shaft elasticity and damping, or between an inertia/gear and the housing (component Fixed), to describe a coupling of the element with the housing via a spring/damper.\n\nSpringDamper(flange_a::Flange, flange_b::Flange, c::Signal, d::Signal)\nSpringDamper(flange_a::Flange, flange_b::Flange, hp::HeatPort, c::Signal, d::Signal)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\nhp::HeatPort : heat port [K]\nc: 	spring constant [N.m/rad]\nd: 	damping constant [N.m.s/rad]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#SpringDamper-1",
    "page": "Rotational mechanics",
    "title": "SpringDamper",
    "category": "section",
    "text": "SpringDamper"
},

{
    "location": "lib\\rotational.html#Sims.Lib.IdealGear",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.IdealGear",
    "category": "Function",
    "text": "Ideal gear without inertia\n\nThis element characterices any type of gear box which is fixed in the ground and which has one driving shaft and one driven shaft. The gear is ideal, i.e., it does not have inertia, elasticity, damping or backlash. If these effects have to be considered, the gear has to be connected to other elements in an appropriate way.\n\nIdealGear(flange_a::Flange, flange_b::Flange, ratio)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\nratio : transmission ratio (flange_a / flange_b)\n\n\n\n"
},

{
    "location": "lib\\rotational.html#IdealGear-1",
    "page": "Rotational mechanics",
    "title": "IdealGear",
    "category": "section",
    "text": "IdealGear"
},

{
    "location": "lib\\rotational.html#Miscellaneous-1",
    "page": "Rotational mechanics",
    "title": "Miscellaneous",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\rotational.html#Sims.Lib.MBranchHeatPort",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.MBranchHeatPort",
    "category": "Function",
    "text": "Wrap argument model with a heat port that captures the power generated by the device. This is vectorizable.\n\nMBranchHeatPort(flange_a::Flange, flange_b::Flange, hp::HeatPort,\n                model::Function, args...)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\nhp::HeatPort : Heat port [K]                \nmodel::Function : Model to wrap\nargs... : Arguments passed to model  \n\n\n\n"
},

{
    "location": "lib\\rotational.html#MBranchHeatPort-1",
    "page": "Rotational mechanics",
    "title": "MBranchHeatPort",
    "category": "section",
    "text": "MBranchHeatPort"
},

{
    "location": "lib\\rotational.html#Sensors-1",
    "page": "Rotational mechanics",
    "title": "Sensors",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\rotational.html#Sims.Lib.SpeedSensor",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.SpeedSensor",
    "category": "Function",
    "text": "Ideal sensor to measure the absolute flange angular velocity\n\nMeasures the absolute angular velocity w of a flange in an ideal way and provides the result as output signal w.\n\nSpeedSensor(flange::Flange, w::Signal)\n\nArguments\n\nflange::Flange : left flange of shaft [rad]\nw::Signal: 	absolute angular velocity of the flange [rad/sec]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#SpeedSensor-1",
    "page": "Rotational mechanics",
    "title": "SpeedSensor",
    "category": "section",
    "text": "SpeedSensor"
},

{
    "location": "lib\\rotational.html#Sims.Lib.AccSensor",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.AccSensor",
    "category": "Function",
    "text": "Ideal sensor to measure the absolute flange angular acceleration\n\nMeasures the absolute angular velocity a of a flange in an ideal way and provides the result as output signal a.\n\nSpeedSensor(flange::Flange, a::Signal)\n\nArguments\n\nflange::Flange : left flange of shaft [rad]\na::Signal: 	absolute angular acceleration of the flange [rad/sec^2]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#AccSensor-1",
    "page": "Rotational mechanics",
    "title": "AccSensor",
    "category": "section",
    "text": "AccSensor"
},

{
    "location": "lib\\rotational.html#Sources-1",
    "page": "Rotational mechanics",
    "title": "Sources",
    "category": "section",
    "text": ""
},

{
    "location": "lib\\rotational.html#Sims.Lib.SignalTorque",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.SignalTorque",
    "category": "Function",
    "text": "Input signal acting as external torque on a flange\n\nThe input signal tau defines an external torque in [Nm] which acts (with negative sign) at a flange connector, i.e., the component connected to this flange is driven by torque tau.\n\nSignalTorque(flange_a::Flange, flange_b::Flange, tau)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\ntau : Accelerating torque acting at flange_a relative to flange_b (normally a support); a positive value accelerates flange_a\n\n\n\n"
},

{
    "location": "lib\\rotational.html#SignalTorque-1",
    "page": "Rotational mechanics",
    "title": "SignalTorque",
    "category": "section",
    "text": "SignalTorque"
},

{
    "location": "lib\\rotational.html#Sims.Lib.QuadraticSpeedDependentTorque",
    "page": "Rotational mechanics",
    "title": "Sims.Lib.QuadraticSpeedDependentTorque",
    "category": "Function",
    "text": "Quadratic dependency of torque versus speed\n\nModel of torque, quadratic dependent on angular velocity of flange. Parameter TorqueDirection chooses whether direction of torque is the same in both directions of rotation or not.\n\nQuadraticSpeedDependentTorque(flange_a::Flange, flange_b::Flange,\n                              tau_nominal::Signal, TorqueDirection::Bool, w_nominal::Signal)\n\nArguments\n\nflange_a::Flange : left flange of shaft [rad]\nflange_b::Flange : right flange of shaft [rad]\ntau_nominal::Signal : nominal torque (if negative, torque is acting as a load) [N.m]\nTorqueDirection::Bool : same direction of torque in both directions of rotation\nAngularVelocity::Signal : nominal speed [rad/sec]\n\n\n\n"
},

{
    "location": "lib\\rotational.html#QuadraticSpeedDependentTorque-1",
    "page": "Rotational mechanics",
    "title": "QuadraticSpeedDependentTorque",
    "category": "section",
    "text": "QuadraticSpeedDependentTorque"
},

{
    "location": "examples\\basics.html#",
    "page": "Examples using basic models",
    "title": "Examples using basic models",
    "category": "page",
    "text": "CurrentModule = Sims.Examples.BasicsPages = [\"basics.md\"]\nDepth = 5"
},

{
    "location": "examples\\basics.html#Examples-using-basic-models-1",
    "page": "Examples using basic models",
    "title": "Examples using basic models",
    "category": "section",
    "text": "These are available in Sims.Examples.Basics.Here is an example of use:using Sims\nm = Sims.Examples.Basics.Vanderpol()\nv = sim(m, 50.0)\n\nusing Winston\nwplot(v)"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.BreakingPendulum",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.BreakingPendulum",
    "category": "Function",
    "text": "Models a pendulum that breaks at 5 secs. This model uses a StructuralEvent to switch between Pendulum mode and FreeFall mode.\n\nBased on an example by George Giorgidze's thesis](http://eprints.nottingham.ac.uk/12554/1/main.pdf) that's in Hydra.\n\n\n\n"
},

{
    "location": "examples\\basics.html#BreakingPendulum-1",
    "page": "Examples using basic models",
    "title": "BreakingPendulum",
    "category": "section",
    "text": "BreakingPendulum"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.BreakingPendulumInBox",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.BreakingPendulumInBox",
    "category": "Function",
    "text": "An extension of Sims.Examples.Basics.BreakingPendulum.\n\nFloors and a wall are added. These are handled by Events in the FreeFall model. Velocities are reversed to bounce the ball.\n\n\n\n"
},

{
    "location": "examples\\basics.html#BreakingPendulumInBox-1",
    "page": "Examples using basic models",
    "title": "BreakingPendulumInBox",
    "category": "section",
    "text": "BreakingPendulumInBox"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.DcMotorWithShaft",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.DcMotorWithShaft",
    "category": "Function",
    "text": "A DC motor with a flexible shaft. The shaft is made of multiple elements. These are collected together algorithmically.\n\nThis is a smaller version of an example on p. 117 of David Broman's thesis.\n\nI don't know if the results are reasonable or not.\n\n\n\n"
},

{
    "location": "examples\\basics.html#DcMotorWithShaft-1",
    "page": "Examples using basic models",
    "title": "DcMotorWithShaft",
    "category": "section",
    "text": "DcMotorWithShaft"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.HalfWaveRectifier",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.HalfWaveRectifier",
    "category": "Function",
    "text": "A half-wave rectifier. The diode uses Events to toggle switching.\n\nSee F. E. Cellier and E. Kofman, Continuous System Simulation, Springer, 2006, fig 9.27.\n\n\n\n"
},

{
    "location": "examples\\basics.html#HalfWaveRectifier-1",
    "page": "Examples using basic models",
    "title": "HalfWaveRectifier",
    "category": "section",
    "text": "HalfWaveRectifier"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.StructuralHalfWaveRectifier",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.StructuralHalfWaveRectifier",
    "category": "Function",
    "text": "This is the same circuit used in Sims.Examples.Basics.HalfWaveRectifier, but a structurally variable diode is used instead of a diode that uses Events.\n\n\n\n"
},

{
    "location": "examples\\basics.html#StructuralHalfWaveRectifier-1",
    "page": "Examples using basic models",
    "title": "StructuralHalfWaveRectifier",
    "category": "section",
    "text": "StructuralHalfWaveRectifier"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.InitialCondition",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.InitialCondition",
    "category": "Function",
    "text": "A basic test of solving for initial conditions for two simultaineous equations.\n\n\n\n"
},

{
    "location": "examples\\basics.html#InitialCondition-1",
    "page": "Examples using basic models",
    "title": "InitialCondition",
    "category": "section",
    "text": "InitialCondition"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.MkinInitialCondition",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.MkinInitialCondition",
    "category": "Function",
    "text": "A basic test of solving for initial conditions for two simultaineous equations.\n\n\n\n"
},

{
    "location": "examples\\basics.html#MkinInitialCondition-1",
    "page": "Examples using basic models",
    "title": "MkinInitialCondition",
    "category": "section",
    "text": "MkinInitialCondition"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.Vanderpol",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.Vanderpol",
    "category": "Function",
    "text": "The Van Der Pol oscillator is a simple problem with two equations and two unknowns.\n\n\n\n"
},

{
    "location": "examples\\basics.html#Vanderpol-1",
    "page": "Examples using basic models",
    "title": "Vanderpol",
    "category": "section",
    "text": "Vanderpol"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.VanderpolWithEvents",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.VanderpolWithEvents",
    "category": "Function",
    "text": "An extension of Sims.Examples.Basics.Vanderpol. Events are triggered every 2 sec that change the quantity mu.\n\n\n\n"
},

{
    "location": "examples\\basics.html#VanderpolWithEvents-1",
    "page": "Examples using basic models",
    "title": "VanderpolWithEvents",
    "category": "section",
    "text": "VanderpolWithEvents"
},

{
    "location": "examples\\basics.html#Sims.Examples.Basics.VanderpolWithParameter",
    "page": "Examples using basic models",
    "title": "Sims.Examples.Basics.VanderpolWithParameter",
    "category": "Function",
    "text": "The Van Der Pol oscillator is a simple problem with two equations and two unknowns.\n\n\n\n"
},

{
    "location": "examples\\basics.html#VanderpolWithParameter-1",
    "page": "Examples using basic models",
    "title": "VanderpolWithParameter",
    "category": "section",
    "text": "VanderpolWithParameter"
},

{
    "location": "examples\\lib.html#",
    "page": "Sims.Lib",
    "title": "Sims.Lib",
    "category": "page",
    "text": "CurrentModule = Sims.Examples.LibPages = [\"lib.md\"]\nDepth = 5"
},

{
    "location": "examples\\lib.html#Sims.Lib-1",
    "page": "Sims.Lib",
    "title": "Sims.Lib",
    "category": "section",
    "text": "Examples using models from the Sims standard library (Sims.Lib).Many of these are patterned after the examples in the Modelica Standard Library.These are available in Sims.Examples.Lib. Here is an example of use:using Sims\nm = Sims.Examples.Lib.ChuaCircuit()\nz = sim(m, 5000.0)\n\nusing Winston\nwplot(z)"
},

{
    "location": "examples\\lib.html#Blocks-1",
    "page": "Sims.Lib",
    "title": "Blocks",
    "category": "section",
    "text": ""
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.PID_Controller",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.PID_Controller",
    "category": "Function",
    "text": "Demonstrates the usage of a Continuous.LimPID controller\n\nThis is a simple drive train controlled by a PID controller:\n\nThe two blocks \"kinematic_PTP\" and \"integrator\" are used to generate the reference speed (= constant acceleration phase, constant speed phase, constant deceleration phase until inertia is at rest). To check whether the system starts in steady state, the reference speed is zero until time = 0.5 s and then follows the sketched trajectory. Note: the \"kinematic_PTP\" isn't used; that comment is based on the Modelica model.\nThe block \"PI\" is an instance of \"LimPID\" which is a PID controller where several practical important aspects, such as anti-windup-compensation has been added. In this case, the control block is used as PI controller.\nThe output of the controller is a torque that drives a motor inertia \"inertia1\". Via a compliant spring/damper component, the load inertia \"inertia2\" is attached. A constant external torque of 10 Nm is acting on the load inertia.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#PID_Controller-1",
    "page": "Sims.Lib",
    "title": "PID_Controller",
    "category": "section",
    "text": "PID_Controller"
},

{
    "location": "examples\\lib.html#Electrical-1",
    "page": "Sims.Lib",
    "title": "Electrical",
    "category": "section",
    "text": ""
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.CauerLowPassAnalog",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.CauerLowPassAnalog",
    "category": "Function",
    "text": "Cauer low-pass filter with analog components\n\nThe example Cauer Filter is a low-pass-filter of the fifth order. It is realized using an analog network. The voltage source on n1 is the input voltage (step), and n4 is the filter output voltage. The pulse response is calculated.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#CauerLowPassAnalog-1",
    "page": "Sims.Lib",
    "title": "CauerLowPassAnalog",
    "category": "section",
    "text": "CauerLowPassAnalog"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.CauerLowPassOPV",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.CauerLowPassOPV",
    "category": "Function",
    "text": "Cauer low-pass filter with operational amplifiers\n\nThe example Cauer Filter is a low-pass-filter of the fifth order. It is realized using an analog network with op amps. The voltage source on n[1] is the input voltage (step), and n[10] is the filter output voltage. The pulse response is calculated.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#CauerLowPassOPV-1",
    "page": "Sims.Lib",
    "title": "CauerLowPassOPV",
    "category": "section",
    "text": "CauerLowPassOPV"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.CauerLowPassOPV2",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.CauerLowPassOPV2",
    "category": "Function",
    "text": "Cauer low-pass filter with operational amplifiers (alternate implementation)\n\nThe example Cauer Filter is a low-pass-filter of the fifth order. It is realized using an analog network with op amps. The voltage source on n1 is the input voltage (step), and n10 is the filter output voltage. The pulse response is calculated.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#CauerLowPassOPV2-1",
    "page": "Sims.Lib",
    "title": "CauerLowPassOPV2",
    "category": "section",
    "text": "CauerLowPassOPV2"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.CharacteristicIdealDiodes",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.CharacteristicIdealDiodes",
    "category": "Function",
    "text": "Characteristic of ideal diodes\n\nThree examples of ideal diodes are shown:\n\nThe totally ideal diode (Ideal) with all parameters to be zero\nThe nearly ideal diode with Ron=0.1 and Goff=0.1\nThe nearly ideal but displaced diode with Vknee=5 and Ron=0.1 and Goff=0.1.\n\nThe resistance and conductance are chosen untypically high since the slopes should be seen in the graphics. The voltage across the first diode is (s1 - n1). The current through the first diode is proportional to n1.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#CharacteristicIdealDiodes-1",
    "page": "Sims.Lib",
    "title": "CharacteristicIdealDiodes",
    "category": "section",
    "text": "CharacteristicIdealDiodes"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.ChuaCircuit",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.ChuaCircuit",
    "category": "Function",
    "text": "Chua's circuit\n\nChua's circuit is a simple nonlinear circuit which shows chaotic behaviour. The circuit consists of linear basic elements (capacitors, resistor, conductor, inductor), and one nonlinear element, which is called Chua's diode. \n\nTo see the chaotic behaviour, plot n2 versus n3 (the two capacitor voltages).\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#ChuaCircuit-1",
    "page": "Sims.Lib",
    "title": "ChuaCircuit",
    "category": "section",
    "text": "ChuaCircuit"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.HeatingResistor",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.HeatingResistor",
    "category": "Function",
    "text": "Heating resistor\n\nThis is a very simple circuit consisting of a voltage source and a resistor. The loss power in the resistor is transported to the environment via its heatPort.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#HeatingResistor-1",
    "page": "Sims.Lib",
    "title": "HeatingResistor",
    "category": "section",
    "text": "HeatingResistor"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.HeatingRectifier",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.HeatingRectifier",
    "category": "Function",
    "text": "Heating rectifier\n\nThe heating rectifier shows a heat flow always if the electrical capacitor is loaded. \n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#HeatingRectifier-1",
    "page": "Sims.Lib",
    "title": "HeatingRectifier",
    "category": "section",
    "text": "HeatingRectifier"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.Rectifier",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.Rectifier",
    "category": "Function",
    "text": "B6 diode bridge\n\nThe rectifier example shows a B6 diode bridge fed by a three phase sinusoidal voltage, loaded by a DC current. DC capacitors start at ideal no-load voltage, thus making easier initial transient.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#Rectifier-1",
    "page": "Sims.Lib",
    "title": "Rectifier",
    "category": "section",
    "text": "Rectifier"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.ShowSaturatingInductor",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.ShowSaturatingInductor",
    "category": "Function",
    "text": "Simple demo to show behaviour of SaturatingInductor component\n\nThis simple circuit uses the saturating inductor which has a changing inductivity.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\nNOTE: CURRENTLY BROKEN\n\n\n\n"
},

{
    "location": "examples\\lib.html#ShowSaturatingInductor-1",
    "page": "Sims.Lib",
    "title": "ShowSaturatingInductor",
    "category": "section",
    "text": "ShowSaturatingInductor"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.ShowVariableResistor",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.ShowVariableResistor",
    "category": "Function",
    "text": "Simple demo of a VariableResistor model\n\nIt is a simple test circuit for the VariableResistor. The VariableResistor sould be compared with R2. isig1 and isig2 are current monitors\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#ShowVariableResistor-1",
    "page": "Sims.Lib",
    "title": "ShowVariableResistor",
    "category": "section",
    "text": "ShowVariableResistor"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.ControlledSwitchWithArc",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.ControlledSwitchWithArc",
    "category": "Function",
    "text": "Comparison of controlled switch models both with and without arc\n\nThis example is to compare the behaviour of switch models with and without an electric arc taking into consideration.\n\na3 and b3 are proportional to the switch currents. The difference in the closing area shows that the simple arc model avoids the suddenly switching.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#ControlledSwitchWithArc-1",
    "page": "Sims.Lib",
    "title": "ControlledSwitchWithArc",
    "category": "section",
    "text": "ControlledSwitchWithArc"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.CharacteristicThyristors",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.CharacteristicThyristors",
    "category": "Function",
    "text": "Characteristic of ideal thyristors\n\nTwo examples of thyristors are shown: the ideal thyristor and the ideal GTO thyristor with Vknee=5.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#CharacteristicThyristors-1",
    "page": "Sims.Lib",
    "title": "CharacteristicThyristors",
    "category": "section",
    "text": "CharacteristicThyristors"
},

{
    "location": "examples\\lib.html#Heat-transfer-1",
    "page": "Sims.Lib",
    "title": "Heat transfer",
    "category": "section",
    "text": ""
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.TwoMasses",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.TwoMasses",
    "category": "Function",
    "text": "Simple conduction demo\n\nThis example demonstrates the thermal response of two masses connected by a conducting element. The two masses have the same heat capacity but different initial temperatures (T1=100 [degC], T2= 0 [degC]). The mass with the higher temperature will cool off while the mass with the lower temperature heats up. They will each asymptotically approach the calculated temperature T_final_K (T_final_degC) that results from dividing the total initial energy in the system by the sum of the heat capacities of each element.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#TwoMasses-1",
    "page": "Sims.Lib",
    "title": "TwoMasses",
    "category": "section",
    "text": "TwoMasses"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.Motor",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.Motor",
    "category": "Function",
    "text": "Second order thermal model of a motor\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#Motor-1",
    "page": "Sims.Lib",
    "title": "Motor",
    "category": "section",
    "text": "Motor"
},

{
    "location": "examples\\lib.html#Power-systems-1",
    "page": "Sims.Lib",
    "title": "Power systems",
    "category": "section",
    "text": ""
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.RLModel",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.RLModel",
    "category": "Function",
    "text": "Three-phase RL line model\n\nSee also sister models: PiModel and ModalModal.\n\nWARNING: immature / possibly broken!\n\n\n\n"
},

{
    "location": "examples\\lib.html#RLModel-1",
    "page": "Sims.Lib",
    "title": "RLModel",
    "category": "section",
    "text": "RLModel"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.PiModel",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.PiModel",
    "category": "Function",
    "text": "Three-phase Pi line model\n\nSee also sister models: RLModel and ModalModal.\n\nWARNING: immature / possibly broken!\n\n\n\n"
},

{
    "location": "examples\\lib.html#PiModel-1",
    "page": "Sims.Lib",
    "title": "PiModel",
    "category": "section",
    "text": "PiModel"
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.ModalModel",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.ModalModel",
    "category": "Function",
    "text": "Three-phase modal line model\n\nSee also sister models: PiModel and RLModal.\n\nWARNING: immature / possibly broken!\n\n\n\n"
},

{
    "location": "examples\\lib.html#ModalModel-1",
    "page": "Sims.Lib",
    "title": "ModalModel",
    "category": "section",
    "text": "ModalModel"
},

{
    "location": "examples\\lib.html#Rotational-1",
    "page": "Sims.Lib",
    "title": "Rotational",
    "category": "section",
    "text": ""
},

{
    "location": "examples\\lib.html#Sims.Examples.Lib.First",
    "page": "Sims.Lib",
    "title": "Sims.Examples.Lib.First",
    "category": "Function",
    "text": "First example: simple drive train\n\nThe drive train consists of a motor inertia which is driven by a sine-wave motor torque. Via a gearbox the rotational energy is transmitted to a load inertia. Elasticity in the gearbox is modeled by a spring element. A linear damper is used to model the damping in the gearbox bearing.\n\nNote, that a force component (like the damper of this example) which is acting between a shaft and the housing has to be fixed in the housing on one side via component Fixed.\n\n(Image: diagram)\n\nLBL doc link  | MapleSoft doc link\n\n\n\n"
},

{
    "location": "examples\\lib.html#First-1",
    "page": "Sims.Lib",
    "title": "First",
    "category": "section",
    "text": "First"
},

{
    "location": "examples\\tiller.html#",
    "page": "Tiller examples",
    "title": "Tiller examples",
    "category": "page",
    "text": "CurrentModule = Sims.Examples.TillerPages = [\"tiller.md\"]\nDepth = 5"
},

{
    "location": "examples\\tiller.html#Tiller-examples-1",
    "page": "Tiller examples",
    "title": "Tiller examples",
    "category": "section",
    "text": "From Modelica by ExampleThese examples are from the online book Modelica by Example by Michael M. Tiller. Michael explains modeling and simulations very well, and it's easy to compare Sims.jl results to those online.These are available in Sims.Examples.Tiller. Here is an example of use:using Sims\nm = Sims.Examples.Tiller.SecondOrderSystem()\ny = dasslsim(m, tstop = 5.0)\n\nusing Winston\nwplot(y)"
},

{
    "location": "examples\\tiller.html#Architectures-1",
    "page": "Tiller examples",
    "title": "Architectures",
    "category": "section",
    "text": "These examples from the following sections from the Architectures chapter:Sensor Comparison\nArchitecture Driven ApproachIn Modelica by Example, Tiller shows how components can be connected together in a reusable fashion. This is also possible in Sims.jl. Because Sims.jl is functional, the approach is different than Modelica's object-oriented approach. The functional approach is generally cleaner."
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.FlatSystem",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.FlatSystem",
    "category": "Function",
    "text": "Sensor comparison for a rotational example\n\nhttp://book.xogeny.com/components/architectures/sensor_comparison/\n\n(Image: diagram)\n\n\n\n"
},

{
    "location": "examples\\tiller.html#FlatSystem-1",
    "page": "Tiller examples",
    "title": "FlatSystem",
    "category": "section",
    "text": "FlatSystem"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.BasicPlant",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.BasicPlant",
    "category": "Function",
    "text": "Basic plant for the example\n\n\n\n"
},

{
    "location": "examples\\tiller.html#BasicPlant-1",
    "page": "Tiller examples",
    "title": "BasicPlant",
    "category": "section",
    "text": "BasicPlant"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.IdealSensor",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.IdealSensor",
    "category": "Function",
    "text": "Ideal sensor for angular velocity\n\n\n\n"
},

{
    "location": "examples\\tiller.html#IdealSensor-1",
    "page": "Tiller examples",
    "title": "IdealSensor",
    "category": "section",
    "text": "IdealSensor"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.SampleHoldSensor",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.SampleHoldSensor",
    "category": "Function",
    "text": "Sample-and-hold velocity sensor\n\n\n\n"
},

{
    "location": "examples\\tiller.html#SampleHoldSensor-1",
    "page": "Tiller examples",
    "title": "SampleHoldSensor",
    "category": "section",
    "text": "SampleHoldSensor"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.IdealActuator",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.IdealActuator",
    "category": "Function",
    "text": "Ideal actuator\n\n\n\n"
},

{
    "location": "examples\\tiller.html#IdealActuator-1",
    "page": "Tiller examples",
    "title": "IdealActuator",
    "category": "section",
    "text": "IdealActuator"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.LimitedActuator",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.LimitedActuator",
    "category": "Function",
    "text": "Actuator with lag and saturation\n\n\n\n"
},

{
    "location": "examples\\tiller.html#LimitedActuator-1",
    "page": "Tiller examples",
    "title": "LimitedActuator",
    "category": "section",
    "text": "LimitedActuator"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.ProportionalController",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.ProportionalController",
    "category": "Function",
    "text": "Proportional controller\n\n\n\n"
},

{
    "location": "examples\\tiller.html#ProportionalController-1",
    "page": "Tiller examples",
    "title": "ProportionalController",
    "category": "section",
    "text": "ProportionalController"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.PIDController",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.PIDController",
    "category": "Function",
    "text": "PID controller\n\n\n\n"
},

{
    "location": "examples\\tiller.html#PIDController-1",
    "page": "Tiller examples",
    "title": "PIDController",
    "category": "section",
    "text": "PIDController"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.BaseSystem",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.BaseSystem",
    "category": "Function",
    "text": "Base system with replaceable components\n\nThis is the same example as FlatSystem, but Plant, Sensor, Actuator, and Controller can all be changed by passing in optional keyword arguments.\n\nHere is an example where several components are modified. The replacement components like SampleHoldSensor are based on closures (functions that return functions).\n\nVariant2  = BaseSystem(Sensor = SampleHoldSensor(sampletime = 0.01),\n                       Controller = PIDController(yMax=15, Td=0.1, k=20, Ti=0.1),\n                       Actuator = LimitedActuator(delayTime=0.005, uMax=10));\n\n\n\n"
},

{
    "location": "examples\\tiller.html#BaseSystem-1",
    "page": "Tiller examples",
    "title": "BaseSystem",
    "category": "section",
    "text": "BaseSystem"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.Variant1",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.Variant1",
    "category": "Function",
    "text": "BaseSystem variant with sample-hold sensing\n\n\n\n"
},

{
    "location": "examples\\tiller.html#Variant1-1",
    "page": "Tiller examples",
    "title": "Variant1",
    "category": "section",
    "text": "Variant1"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.Variant2",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.Variant2",
    "category": "Function",
    "text": "BaseSystem variant with PID control along with a realistic actuator\n\n\n\n"
},

{
    "location": "examples\\tiller.html#Variant2-1",
    "page": "Tiller examples",
    "title": "Variant2",
    "category": "section",
    "text": "Variant2"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.Variant2a",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.Variant2a",
    "category": "Function",
    "text": "BaseSystem variant with a tuned PID control along with a realistic actuator\n\n\n\n"
},

{
    "location": "examples\\tiller.html#Variant2a-1",
    "page": "Tiller examples",
    "title": "Variant2a",
    "category": "section",
    "text": "Variant2a"
},

{
    "location": "examples\\tiller.html#Examples-of-speed-measurement-1",
    "page": "Tiller examples",
    "title": "Examples of speed measurement",
    "category": "section",
    "text": "These examples show several ways of measuring speed on a rotational system. They are based on Michael's section on Speed Measurement. These examples include use of Discrete variables and Events.The system is based on the following plant:(Image: diagram)"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.SecondOrderSystem",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.SecondOrderSystem",
    "category": "Function",
    "text": "Rotational example\n\nhttp://book.xogeny.com/behavior/equations/mechanical/\n\n\n\n"
},

{
    "location": "examples\\tiller.html#SecondOrderSystem-1",
    "page": "Tiller examples",
    "title": "SecondOrderSystem",
    "category": "section",
    "text": "SecondOrderSystem"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.SecondOrderSystemUsingSimsLib",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.SecondOrderSystemUsingSimsLib",
    "category": "Function",
    "text": "Rotational example based on components in Sims.Lib\n\nhttp://book.xogeny.com/behavior/equations/mechanical/\n\n(Image: diagram)\n\n\n\n"
},

{
    "location": "examples\\tiller.html#SecondOrderSystemUsingSimsLib-1",
    "page": "Tiller examples",
    "title": "SecondOrderSystemUsingSimsLib",
    "category": "section",
    "text": "SecondOrderSystemUsingSimsLib"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.SampleAndHold",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.SampleAndHold",
    "category": "Function",
    "text": "Rotational example with sample-and-hold measurement\n\nhttp://book.xogeny.com/behavior/discrete/measuring/#sample-and-hold\n\n\n\n"
},

{
    "location": "examples\\tiller.html#SampleAndHold-1",
    "page": "Tiller examples",
    "title": "SampleAndHold",
    "category": "section",
    "text": "SampleAndHold"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.IntervalMeasure",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.IntervalMeasure",
    "category": "Function",
    "text": "Rotational example with interval measurements\n\nhttp://book.xogeny.com/behavior/discrete/measuring/#interval-measurement\n\n\n\n"
},

{
    "location": "examples\\tiller.html#IntervalMeasure-1",
    "page": "Tiller examples",
    "title": "IntervalMeasure",
    "category": "section",
    "text": "IntervalMeasure"
},

{
    "location": "examples\\tiller.html#Sims.Examples.Tiller.PulseCounting",
    "page": "Tiller examples",
    "title": "Sims.Examples.Tiller.PulseCounting",
    "category": "Function",
    "text": "Rotational example with pulse counting\n\nhttp://book.xogeny.com/behavior/discrete/measuring/#pulse-counting\n\n\n\n"
},

{
    "location": "examples\\tiller.html#PulseCounting-1",
    "page": "Tiller examples",
    "title": "PulseCounting",
    "category": "section",
    "text": "PulseCounting"
},

{
    "location": "design.html#",
    "page": "Design",
    "title": "Design",
    "category": "page",
    "text": ""
},

{
    "location": "design.html#Design-Documentation-1",
    "page": "Design",
    "title": "Design Documentation",
    "category": "section",
    "text": "This documentation is an overview of the design of Sims, particularly the input specification. Some of the internals are also discussed."
},

{
    "location": "design.html#Overview-1",
    "page": "Design",
    "title": "Overview",
    "category": "section",
    "text": "This implementation follows the work of David Broman and his MKL and Modelyze simulators and the work of George Giorgidze and Henrik Nilsson and their functional hybrid modeling.A nodal formulation is used based on David's work. His thesis documents this nicely:David Broman. Meta-Languages and Semantics for Equation-Based Modeling and Simulation. PhD thesis, Thesis No 1333. Department of Computer and Information Science, Linköping University, Sweden, 2010. http://www.bromans.com/david/publ/thesis-2010-david-broman.pdfHere is David's code and home page:http://web.ict.kth.se/~dbro/\nhttp://www.eecs.berkeley.edu/Pubs/TechRpts/2012/EECS-2012-173.pdf\nhttp://www.bromans.com/software/mkl/mkl-source-1.0.0.zip\nhttps://github.com/david-broman/modelyzeSims implements something like David's approach in MKL and Modelyze. Modelyze models in particular look quite similar to Sims models. A model constructor returns a list of equations. Models are made of models, so this builds up a hierarchical structure of equations that then needs to be flattened. Like David's approach, Sims is nodal; nodes are passed in as parameters to models to perform connections between devices. Modeling of dynamically varying systems is handled similarly to functional hybrid modelling (FHM), specifically the Hydra implementation by George. See here for links:https://github.com/giorgidze/Hydra\nhttp://www.cs.nott.ac.uk/~nhn/FHM is also a functional approach. Hydra is implemented as a domain specific language embedded in Haskell. Their implementation handles dynamically changing systems with JIT-compiled code from an amazingly small amount of code."
},

{
    "location": "design.html#Unknowns-and-MExpr's-1",
    "page": "Design",
    "title": "Unknowns and MExpr's",
    "category": "section",
    "text": "An Unknown is a symbolic type. When used in Julia expressions, Unknowns combine into MExprs which are symbolic representations of equations.Expressions (of type MExpr) are built up based on Unknown's. Unknown is a symbol with a uniquely generated symbol name. If you have  a = 1\n  b = Unknown()\n  a * b + b^2evaluation produces the following:  MExpr(+(*(1,##1029),*(##1029,##1029)))This is an expression tree where ##1029 is the symbol name for b.The idea is that you can set up a set of hierarchical equations that will be later flattened.Other types or method definitions can be used to assign behavior during flattening (like the Branch type) or during instantiation (like the der method).Unknowns can contain Float64, Complex, and Array{Float64} values. Additionally, Unknowns can contain values for any types with from_real and to_real defined. These methods define conversions from and to Float64 arrays. This allows Unknowns to be extended to cover additional types.In addition to a value, Unknowns can carry additional metadata, including an identification symbol and a label. In the future, unit information may be added.Unknowns can also have type parameters. For example, Voltage is defined as Unknown{UVoltage}. The UVoltage type parameter is a marker to distinguish those Unknown from others. Users can add their own Unknown types. Different Unknown types makes it easier to dispatch on model arguments.In addition to standard Unknowns, additional variations are Unknowns are provided:DerUnknown – Derivative of an Unknown (not normally used by a user).\nDiscrete – Discrete is a type for discrete variables. These are only changed during events. They are not used by the integrator.\nParameter – Fixed model parameters.\nRefUnknown and RefDiscrete – Used for supporting arrays.\nPassedUnknown – Identity unknown: don't replace with a ref to the y array. I don't remember what this is for:)"
},

{
    "location": "design.html#Models-1",
    "page": "Design",
    "title": "Models",
    "category": "section",
    "text": "A model is a function definition that returns an Equation or array of Equations. Models can contain Models. Here is an example of two models:function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, k::Real)\n    tau = Angle()\n    i = Current()\n    v = Voltage()\n    w = AngularVelocity()\n    Equation[\n        Branch(n1, n2, i, v)\n        RefBranch(flange, tau)\n        w - der(flange)\n        v - k * w\n        tau - k * i\n    ]\nend\n\nfunction DCMotor(flange::Flange)\n    n1 = Voltage()\n    n2 = Voltage()\n    n3 = Voltage()\n    g = 0.0\n    Equation[\n        SignalVoltage(n1, g, 60.0)\n        Resistor(n1, n2, 100.0)\n        Inductor(n2, n3, 0.2)\n        EMF(n3, g, flange, 1.0)\n    ]\nendThe normal rules for function returns and array creation apply.An @equations macro can also be used to specify the model equations. The main difference is that = can be used in models. Like Equation[], the result is of type Array{Equation}. Here is an example of one of the models above:function EMF(n1::ElectricalNode, n2::ElectricalNode, flange::Flange, k::Real)\n    tau = Angle()\n    i = Current()\n    v = Voltage()\n    w = AngularVelocity()\n    @equations begin\n        Branch(n1, n2, i, v)\n        RefBranch(flange, tau)\n        w = der(flange)\n        v = k * w\n        tau = k * i\n    end\nendEquation definitions normally consist of other Models, MExpr's, or special types for other features like InitialEquation(equations). Right now, Equation == Any, but that could change in the future.Any valid Julia is allowed in models and Equation definitions. Some limitations include:if-then-else constructs evaluate immediately, so you cannot use them for dynamic decision actions in a model. Use the ifelse function instead. You can use if-then-else to pick between Equations to include based on static inputs.\nSome functions may not automatically combine to MExpr's. Most user-defined functions will work if functions are defined in terms of the basic functions supported in Sims. For functions that are not automatically converted, there are ways to extend Sims to support them. TODO: document this / make it a little easier.Julia's multiple dispatch works well with a functional model specification. Variations of models or entirely different models can be defined with the same model name with different inputs. For example a Capacitor(n1::Voltage, n2::Voltage, C::Signal = 1.0) can specify an electrical model, and Capacitor(hp::Temperature, C::Signal) can specify a thermal capacitor.Models can have positional function arguments and/or keyword function arguments. Arguments may also have defaults. By convention in the standard library, all models are defined with positional function arguments. Often, especially for long argument lists, versions with keyword arguments are also provided. As with any Julia functions, use methods(Resistor) to see all of the method definitions for Resistor. Variable-length arguments (args...) can also be used in models.  Model arguments can be typed or untyped. In the examples above, model arguments are typed.  The electrical nodes have type ElectricalNode from the standard library defined astypealias NumberOrUnknown{T} Union(AbstractArray, Number, MExpr,\n                                   RefUnknown{T}, Unknown{T})\ntypealias ElectricalNode NumberOrUnknown{UVoltage}This allows the user to pass in a fixed value or an Unknown. A fixed value can be used to fix voltage (zero for a ground reference). Arrays can also be passed.As with most functional approaches, arguments to models can be model types. This \"functional composition\" allows for easier replacement of internal model subcomponents. For example, the BranchHeatPort in the standard electrical library has the following signature:function BranchHeatPort(n1::ElectricalNode, n2::ElectricalNode, hp::HeatPort,\n                        model::Function, args...)This can be used to add heat ports to any electrical branch passed in with model. Here's an example of a definition defining a Resistor that uses a heat port (a Temperature) in terms of another model:function Resistor(n1::ElectricalNode, n2::ElectricalNode, R::Signal, hp::Temperature, T_ref::Signal, alpha::Signal) \n    BranchHeatPort(n1, n2, hp, Resistor, R .* (1 + alpha .* (hp - T_ref)))\nendBy convention in the standard library, the first model arguments are generally nodes.Right now, there are no substantial model checks."
},

{
    "location": "design.html#Special-Model-Features-1",
    "page": "Design",
    "title": "Special Model Features",
    "category": "section",
    "text": "The following are special model types, functions, or models that are handled specially when flattening or during instantiation:der(x) – The time derivative of x.\nMTime – The model time, secs.\nRefBranch(node, flowvariable) – The type RefBranch is used to indicate the potential node and the flow (flowvariable) into the node from a branch connected to it.\nInitialEquation(equations) – Specifies an array of initial equations.\ndelay(x, val) – x delayed by val.\npre(x) – The value of a Discrete variable x prior to an event.\nifelse(condition, trueresult, falseresult) – Like an if-then-else block, but for ModelTypes.\nEvent(condition, pos_response, neg_response) – The main type for hybrid modeling; specifies a condition for root finding and model expressions to process after positive and negative root crossings are detected.\nStructuralEvent(condition, default_model, new_relation) – A type for elements that change the structure of the model. An event is created (condition is the zero crossing). When the event is triggered, the model is re-flattened after replacing default with new_relation in the model."
},

{
    "location": "design.html#Connections-/-Nodal-Models-1",
    "page": "Design",
    "title": "Connections / Nodal Models",
    "category": "section",
    "text": ""
},

{
    "location": "design.html#Model-Flattening-1",
    "page": "Design",
    "title": "Model Flattening",
    "category": "section",
    "text": "elaborate is the main flattening function. There is no real symbolic processing (sorting, index reduction, or any of the other stuff a fancy modeling tool would do). This returns an EquationSet object containing the hierarchical equations, flattened equations, flattened initial equations, events, event response functions, and a map of Unknown nodes.type EquationSet\n    model             # The active model, a hierachichal set of equations.\n    equations         # A flat list of equations.\n    initialequations  # A flat list of initial equations.\n    events\n    pos_responses\n    neg_responses\n    nodeMap::Dict\nendHere is an example of a flattened version of the example breaking_pendulum_in_box.jl. This model contains standard Events and a StructuralEvent.julia> dump(p_f, 10)\nEquationSet \n  model: Array(Any,(1,))\n    ...\n  equations: Array(Any,(6,))\n    1: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: DerUnknown \n          sym: Symbol ##8244\n          value: Float64 0.0\n          fixed: Bool false\n          parent: Unknown{DefaultUnknown} \n            sym: Symbol ##8244\n            value: Float64 0.7853981633974483\n            label: String \"\"\n            fixed: Bool false\n            save_history: Bool false\n        3: Unknown{DefaultUnknown} \n          sym: Symbol ##8245\n          value: Float64 0.0\n          label: String \"\"\n          fixed: Bool false\n          save_history: Bool false\n      typ: Any\n    2: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: DerUnknown \n          sym: Symbol ##8240\n          value: Float64 0.0\n          fixed: Bool false\n          parent: Unknown{DefaultUnknown} \n            sym: Symbol ##8240\n            value: Float64 0.7071067811865476\n            label: String \"x\"\n            fixed: Bool false\n            save_history: Bool true\n        3: Unknown{DefaultUnknown} \n          sym: Symbol ##8242\n          value: Float64 0.0\n          label: String \"\"\n          fixed: Bool false\n          save_history: Bool false\n      typ: Any\n      ...\n    6: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: DerUnknown \n          sym: Symbol ##8245\n          value: Float64 0.0\n          fixed: Bool false\n          parent: Unknown{DefaultUnknown} \n            sym: Symbol ##8245\n            value: Float64 0.0\n            label: String \"\"\n            fixed: Bool false\n            save_history: Bool false\n        3: Expr \n          head: Symbol call\n          args: Array(Any,(3,))\n            1: *\n            2: Float64 -9.81\n            3: Expr \n              head: Symbol call\n              args: Array(Any,(2,))\n                1: sin\n                2: Unknown{DefaultUnknown} \n                  sym: Symbol ##8244\n                  value: Float64 0.7853981633974483\n                  label: String \"\"\n                  fixed: Bool false\n                  save_history: Bool false\n              typ: Any\n          typ: Any\n      typ: Any\n  initialequations: Array(Any,(6,))\n    1: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: DerUnknown \n          sym: Symbol ##8244\n          value: Float64 0.0\n          fixed: Bool false\n          parent: Unknown{DefaultUnknown} \n            sym: Symbol ##8244\n            value: Float64 0.7853981633974483\n            label: String \"\"\n            fixed: Bool false\n            save_history: Bool false\n        3: Unknown{DefaultUnknown} \n          sym: Symbol ##8245\n          value: Float64 0.0\n          label: String \"\"\n          fixed: Bool false\n          save_history: Bool false\n      typ: Any\n    2: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: DerUnknown \n          sym: Symbol ##8240\n          value: Float64 0.0\n          fixed: Bool false\n          parent: Unknown{DefaultUnknown} \n            sym: Symbol ##8240\n            value: Float64 0.7071067811865476\n            label: String \"x\"\n            fixed: Bool false\n            save_history: Bool true\n        3: Unknown{DefaultUnknown} \n          sym: Symbol ##8242\n          value: Float64 0.0\n          label: String \"\"\n          fixed: Bool false\n          save_history: Bool false\n      typ: Any\n      ...\n    6: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: DerUnknown \n          sym: Symbol ##8245\n          value: Float64 0.0\n          fixed: Bool false\n          parent: Unknown{DefaultUnknown} \n            sym: Symbol ##8245\n            value: Float64 0.0\n            label: String \"\"\n            fixed: Bool false\n            save_history: Bool false\n        3: Expr \n          head: Symbol call\n          args: Array(Any,(3,))\n            1: *\n            2: Float64 -9.81\n            3: Expr \n              head: Symbol call\n              args: Array(Any,(2,))\n                1: sin\n                2: Unknown{DefaultUnknown} \n                  sym: Symbol ##8244\n                  value: Float64 0.7853981633974483\n                  label: String \"\"\n                  fixed: Bool false\n                  save_history: Bool false\n              typ: Any\n          typ: Any\n      typ: Any\n  events: Array(Any,(1,))\n    1: Expr \n      head: Symbol call\n      args: Array(Any,(3,))\n        1: -\n        2: Unknown{DefaultUnknown} \n          sym: Symbol time\n          value: Float64 0.0\n          label: String \"\"\n          fixed: Bool false\n          save_history: Bool false\n        3: Float64 1.8\n      typ: Any\n  pos_responses: Array(Any,(1,))\n    1: (anonymous function)\n  neg_responses: Array(Any,(1,))\n    1: (anonymous function)\n  nodeMap: Dict{Any,Any} len 0The main steps in flattening are:Replace fixed initial values.\nFlatten models and populate eq.equations.\nPull out InitialEquations and populate eq.initialequations.\nPull out Events and populate eq.events.\nHandle StructuralEvents.\nCollect nodes and populate eq.nodeMap.\nStrip out MExpr's from expressions.\nRemove empty equations.In EquationSet, model contains equations and StructuralEvents. When a StructuralEvent triggers, the entire model is elaborated again. The first step is to replace StructuralEvents that have activated with their new_relation in model. Then, the rest of the EquationSet is reflattened using model as the starting point."
},

{
    "location": "design.html#Model-Instantiation-1",
    "page": "Design",
    "title": "Model Instantiation",
    "category": "section",
    "text": "From the flattened equations, `create_sim` generates a set of functions\nfor use by the simulation. The residual function has arguments\n(t,y,yp) that returns the residual of type Float64 of length N, the\nnumber of equations in the system. The vectors y and yp are also of\nlength N and type Float64. As part of finding the residual function,\nwe use several Dicts to map unknown variables to indexes into y and\nyp.\n\nSimFunctions is the set of functions used during simulation. All\nfunctions take (t,y,yp) as arguments."
},

{
    "location": "design.html#Initial-Equations-1",
    "page": "Design",
    "title": "Initial Equations",
    "category": "section",
    "text": ""
},

{
    "location": "design.html#Hybrid-Modeling-1",
    "page": "Design",
    "title": "Hybrid Modeling",
    "category": "section",
    "text": ""
},

{
    "location": "design.html#Structural-Events-1",
    "page": "Design",
    "title": "Structural Events",
    "category": "section",
    "text": ""
},

{
    "location": "NEWS.html#",
    "page": "Release notes",
    "title": "Release notes",
    "category": "page",
    "text": "../NEWS.md"
},

{
    "location": "LICENSE.html#",
    "page": "License",
    "title": "License",
    "category": "page",
    "text": "../LICENSE.md"
},

]}
