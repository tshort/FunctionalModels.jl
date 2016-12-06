
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
function createmd(mdfile, mod, files = r".*")
    path, line, text, iscomment = sorteddocs(mod)
    open(mdfile, "w") do fout
        for f in collect(files)
            idx = filter(i -> contains(path[i], f), 1:length(path)) # find the files
            for i in idx
                if iscomment[i]
                    println(fout, text[i])
                else
                    println(fout, "```docs\n    $(text[i])\n```")
                end
            end
        end
    end
end
t(Sims.Examples.Tiller)
