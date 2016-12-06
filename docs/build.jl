
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
        for f in [files;]
            idx = filter(i -> contains(path[i], f), 1:length(path)) # find the files
            for i in idx
                if iscomment[i]
                    println(fout, text[i])
                else
                    println(fout, "```@docs\n    $(text[i])\n```")
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
mysave("src/api/main.md",    Sims, "main.jl")
mysave("src/api/sim.md",     Sims, ["dassl.jl","sundials.jl","sim.jl", "elaboration.jl", "simcreation.jl"])