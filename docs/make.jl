using Documenter, Sims

function sorteddocs(mod)
    path = String[]
    line = Int[]
    text = String[]  # for comments, it's the docstring; for others, it's the name
    iscomment = Bool[]
    for (k,v) in Docs.meta(mod)
        if contains(string(k.var), "##comment")
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

mkpath("docs/src/lib")
mkpath("docs/src/examples")

createmd("docs/src/sims.md", Sims, "Sims.jl")

createmd("docs/src/lib/types.md",         Sims.Lib, "types.jl")
createmd("docs/src/lib/blocks.md",        Sims.Lib, "blocks.jl")
createmd("docs/src/lib/electrical.md",    Sims.Lib, "electrical.jl")
createmd("docs/src/lib/heat_transfer.md", Sims.Lib, "heat_transfer.jl")
createmd("docs/src/lib/rotational.md",    Sims.Lib, "rotational.jl")

include("../examples/Examples.jl")
createmd("docs/src/examples/basics.md", Examples.Basics)
createmd("docs/src/examples/lib.md",    Examples.Lib)
createmd("docs/src/examples/tiller.md", Examples.Tiller)

cp("NEWS.md", "docs/src/NEWS.md", force=true)
cp("LICENSE.md", "docs/src/LICENSE.md", force=true)

makedocs(
    modules = [Sims, Examples],
    clean = false,
    format = Documenter.HTML(),
    sitename = "Sims.jl",
    authors = "Tom Short and contributors.",
    # linkcheck = !("skiplinks" in ARGS),
    pages = Any[ 
        "Home" => "index.md",
        "Basics" => "basics.md",
        "API" => "sims.md",
        "Library" => Any[
            "lib/types.md",
            "lib/blocks.md",
            "lib/electrical.md",
            "lib/heat_transfer.md",
            "lib/rotational.md",
        ],
        "Examples" => Any[
            "examples/basics.md",
            "examples/lib.md",
            "examples/tiller.md",
        ],
        # "Design" => "design.md",
        "Release notes" => "NEWS.md",
        "License" => "LICENSE.md",
    ]
)


deploydocs(
    repo = "github.com/tshort/Sims.jl.git",
    # target = "build",
    # deps = nothing,
    # make = nothing,   
    push_preview = true
)

