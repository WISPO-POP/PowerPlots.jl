using PowerPlots
using PowerModels

data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
@time plot_vega(data, gen_size=100, buscolor=:red)
