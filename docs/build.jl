
using Docile, Docile.Interface, Lexicon, Sims


myfilter(x::Module; files = [""]) = filter(metadata(x), files = files, categories = [:comment, :module, :function, :method, :type, :typealias, :macro, :global])
myfilter(x::Metadata; files = [""]) = filter(x, files = files, categories = [:comment, :module, :function, :method, :type, :typealias, :macro, :global])

# Stuff from Lexicon.jl:
writeobj(any) = string(any)
writeobj(m::Method) = first(split(string(m), "("))
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


function mysave(file::AbstractString, m::Module, order = [:source])
    mysave(file, documentation(m), order)
end
function mysave(file::AbstractString, docs::Metadata, order = [:source])
    isfile(file) || mkpath(dirname(file))
    open(file, "w") do io
        info("writing documentation to $(file)")
        println(io)
        for (k,v) in EachEntry(docs, order = order)
            name = writeobj(k)
            source = v.data[:source]
            catgory = category(v)
            comment = catgory == :comment
            println(io)
            println(io)
            !comment && println(io, "## $name")
            println(io)
            println(io, v.docs.data)
            path = last(split(source[2], r"v[\d\.]+(/|\\)"))
            !comment && println(io, "[$(path):$(source[1])]($(url(source)))")
            println(io)
        end
    end
end


mysave("lib/types.md",         myfilter(Sims.Lib, files = ["types.jl"]))
mysave("lib/blocks.md",        myfilter(Sims.Lib, files = ["blocks.jl"]))
mysave("lib/electrical.md",    myfilter(Sims.Lib, files = ["electrical.jl"]))
mysave("lib/kinetics.md",      myfilter(Sims.Lib, files = ["kinetic.jl"]))
mysave("lib/heat_transfer.md", myfilter(Sims.Lib, files = ["heat_transfer.jl"]))
mysave("lib/powersystems.md",  myfilter(Sims.Lib, files = ["powersystems.jl"]))
mysave("lib/rotational.md",    myfilter(Sims.Lib, files = ["rotational.jl"]))

mysave("examples/basics.md", Sims.Examples.Basics)
mysave("examples/lib.md",    Sims.Examples.Lib)
mysave("examples/neural.md", Sims.Examples.Neural)
mysave("examples/tiller.md", Sims.Examples.Tiller)


mysave("api/main.md",       myfilter(Sims, files = ["main.jl"]), [:category, :name, :source])
smfiles = ["dassl.jl","sundials.jl","sim.jl", "elaboration.jl", "simcreation.jl"]
mysave("api/sim.md",        myfilter(Sims, files = smfiles), [:category, :name, :source])
# Need to load all optional modules to bring in all of the files.
using Gadfly, DataFrames, Winston, PyPlot    # , Gaston
mysave("api/utils.md",      myfilter(Sims, files = ["utils.jl"]), [:category, :name, :source])
