using Documenter, Sims

function sorteddocs(mod)
    path = String[]
    line = Int[]
    text = String[]  # for comments, it's the docstring; for others, it's the name
    iscomment = Bool[]
    for (k,v) in Docs.meta(mod)
        if contains(string(k.var), "###comment")
            docstr = first(v.docs)[2]
            push!(path, docstr.data[:path])
            push!(line, docstr.data[:linenumber])
            push!(text, string(docstr.text...))
            push!(iscomment, true)
        else
            for docstr in values(v.docs)
                push!(path, docstr.data[:path])
                push!(line, docstr.data[:linenumber])
                push!(text, string(docstr.data[:binding].var))
                push!(iscomment, false)
            end
        end
    end
    idx = sortperm([zip(path, line)...])
    (path[idx], line[idx], text[idx], iscomment[idx])
end
"""
    createmd(mdfile, module, files = "")
   
Create the Markdown file `mdfile` using docstrings from `module`, 
optionally filtering to those in `files`. `files` can be a single
value or array with strings. 
"""
function createmd(mdfile, mod, files = "")
    path, line, text, iscomment = sorteddocs(mod)
    open(mdfile, "w") do fout
        println(fout, """
        ```@meta
        CurrentModule = $mod
        ```
        ```@contents
        Pages = ["$(basename(mdfile))"]
        Depth = 5
        ```
        """)
        for f in [files;]
            idx = filter(i -> contains(path[i], f), 1:length(path)) # find the files
            for i in idx
                if iscomment[i]
                    println(fout, text[i])
                else
                    println(fout, "### $(text[i])\n```@docs\n$(text[i])\n```")
                end
            end
        end
    end
end

mkpath("src/api")
mkpath("src/lib")
mkpath("src/examples")

createmd("src/lib/types.md",         Sims.Lib, "types.jl")
createmd("src/lib/blocks.md",        Sims.Lib, "blocks.jl")
createmd("src/lib/electrical.md",    Sims.Lib, "electrical.jl")
createmd("src/lib/kinetics.md",      Sims.Lib, "kinetic.jl")
createmd("src/lib/heat_transfer.md", Sims.Lib, "heat_transfer.jl")
createmd("src/lib/powersystems.md",  Sims.Lib, "powersystems.jl")
createmd("src/lib/rotational.md",    Sims.Lib, "rotational.jl")

createmd("src/examples/basics.md", Sims.Examples.Basics)
createmd("src/examples/lib.md",    Sims.Examples.Lib)
# createmd("src/examples/neural.md", Sims.Examples.Neural)
createmd("src/examples/tiller.md", Sims.Examples.Tiller)

createmd("src/api/utils.md", Sims, "utils.jl")
createmd("src/api/main.md",  Sims, "main.jl")
createmd("src/api/sim.md",   Sims, ["dassl.jl","sundials.jl","sim.jl", "elaboration.jl", "simcreation.jl"])

cp("../NEWS.md", "src/NEWS.md")
cp("../LICENSE.md", "src/LICENSE.md")

makedocs(
    modules = [Sims],
    clean = false,
    format = :html,
    sitename = "Sims.jl",
    authors = "Tom Short and contributors.",
    # linkcheck = !("skiplinks" in ARGS),
    pages = Any[ # Compat: `Any` for 0.4 compat
        "Home" => "index.md",
        "Basics" => "basics.md",
        "API" => Any[
            "api/sim.md",
            "api/main.md",
            "api/utils.md",
        ],
        "Library" => Any[
            "lib/types.md",
            "lib/kinetics.md",
            "lib/blocks.md",
            "lib/electrical.md",
            "lib/heat_transfer.md",
            # "lib/kinetic.md",
            "lib/powersystems.md",
            "lib/rotational.md",
        ],
        "Examples" => Any[
            "examples/basics.md",
            "examples/lib.md",
            # "examples/neural.md",
            "examples/tiller.md",
        ],
        "Design" => "design.md",
        "Release notes" => "NEWS.md",
        "License" => "LICENSE.md",
    ]
)


deploydocs(
    repo = "github.com/tshort/Sims.jl.git",
    target = "build",
    julia = "0.5",
    deps = nothing,
    make = nothing,
)

