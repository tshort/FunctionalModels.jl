module PlotTests

using Sims
z = sim(Sims.Examples.Lib.CauerLowPassOPV2(), 60.0)

using PyPlot
plot(z)
plot(z, [1:length(z.colnames)])
plot(z, r".*", title = "CauerLowPassOPV")
plot(z, subplots = true, title = "subplots = true")
plot(z, 9:11, subplots = false, title = "subplots = false")
plot(z, r"n", title = "r\"n\"")
plot(z, r"n1", title = "r\"n1\"")
plot(z, 5:8, legend = false)
figure()
plot(z, 5:8, legend = false, newfigure = false)
plot(z, ["n8", "n9"], title = string(["n8", "n9"]))
plot(z, [("n8", "n9"), ("n10", "n11")], title = string([("n8", "n9"), ("n10", "n11")]))
plot(z, [r"n1", ("n9", "n10")], title = string([r"n1", ("n9", "n10")]))

end # module
