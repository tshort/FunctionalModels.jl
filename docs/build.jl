
using Docile, Docile.Interface, Sims


function Base.filter(m::Module; args...)
    filter(documentation(m); args...)
end

function Base.filter(docs::Metadata; files = String[])
    entries = copy(docs.entries)
    if length(files) > 0
        filter!((k,v) -> any(x -> contains(v.data[:source][2], x), files),
                entries)
    end
    Metadata(docs.modname, entries, docs.root, docs.files, docs.data, docs.loaded)
end

# Stuff from Lexicon.jl:
writeobj(any)       = string(any)
writeobj(m::Method) = first(split(string(m), " at "))
# from base/methodshow.jl
function url(m)
    line, file = m
    try
        d = dirname(file)
        u = Pkg.Git.readchomp(`config remote.origin.url`, dir=d)
        u = match(Pkg.Git.GITHUB_REGEX,u).captures[1]
        root = cd(d) do # dir=d confuses --show-toplevel, apparently
            Pkg.Git.readchomp(`rev-parse --show-toplevel`)
        end
        if beginswith(file, root)
            commit = Pkg.Git.readchomp(`rev-parse HEAD`, dir=d)
            return "https://github.com/$u/tree/$commit/"*file[length(root)+2:end]*"#L$line"
        else
            return Base.fileurl(file)
        end
    catch
        return Base.fileurl(file)
    end
end

getcat{T}(x::Entry{T}) = T

function mysave(file::String, m::Module, order = [:doctag, :category, :name, :source])
    mysave(file, documentation(m), order)
end
function mysave(file::String, docs::Metadata, order = [:doctag, :category, :name, :source])
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do io
        info("writing documentation to $(file)")
        println(io)
        doctag = [isa(k, Type) && k <: DocTag for k in keys(docs.entries)]
        name = [replace(writeobj(k), ",", ", ") for k in keys(docs.entries)]
        source = [v.data[:source] for v in values(docs.entries)]
        data = [v.docs.data for v in values(docs.entries)]
        category = [getcat(v) for v in values(docs.entries)]
        d = [:doctag => !doctag,    # various vectors for sorting
             :name => name,
             :source => [(a[2], a[1]) for a in source],
             :category => category]
        for i in sortperm(collect(zip([d[o] for o in order]...)))
            println(io)
            println(io)
            !doctag[i] && println(io, "## $(name[i])")
            println(io)
            println(io, data[i])
            s = source[i]
            path = last(split(s[2], r"v[\d\.]+(/|\\)"))
            !doctag[i] && println(io, "[$(path):$(s[1])]($(url(s)))")
            println(io)
        end
    end
end


mysave("lib/types.md",         filter(Sims.Lib, files = ["types.jl"]), [:source])
mysave("lib/blocks.md",        filter(Sims.Lib, files = ["blocks.jl"]), [:source])
mysave("lib/electrical.md",    filter(Sims.Lib, files = ["electrical.jl"]), [:source])
mysave("lib/heat_transfer.md", filter(Sims.Lib, files = ["heat_transfer.jl"]), [:source])
mysave("lib/powersystems.md",  filter(Sims.Lib, files = ["powersystems.jl"]), [:source])
mysave("lib/rotational.md",    filter(Sims.Lib, files = ["rotational.jl"]), [:source])

mysave("examples/basics.md", Sims.Examples.Basics, [:source])
mysave("examples/lib.md",    Sims.Examples.Lib, [:source])
mysave("examples/neural.md", Sims.Examples.Neural, [:source])
mysave("examples/tiller.md", Sims.Examples.Tiller, [:source])


mysave("api/main.md",       filter(Sims, files = ["main.jl"]))
smfiles = ["dassl.jl","sundials.jl","sim.jl", "elaboration.jl", "simcreation.jl"]
mysave("api/sim.md",        filter(Sims, files = smfiles))
# Need to load all optional modules to bring in all of the files.
using Gadfly, DataFrames, Winston, PyPlot    # , Gaston
mysave("api/utils.md",      filter(Sims, files = ["utils.jl"]), [:source])
