using PowerPlots
using PowerModels
using VegaLite

## Basic plot
data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
p = powerplot(data)
save("basic_plot.html", p)

## Set Color
p = powerplot(data, bus_color="orange", gen_color=:purple, branch_color="#AFAFAF")
save("color_plot.html", p)

p = powerplot(data; node_color="red", edge_color="purple")
save("color_override_plot.html", p)

## Set Size
p = powerplot(data, bus_size=1000, gen_size=100, branch_size=2, connector_size=10)
save("size_plot.html", p)

p = powerplot(data, node_size=1000, edge_size=10)
save("size_override_plot.html", p)


## Set data
p = powerplot(data, bus_data="va", bus_data_type="quantitative", bus_color=["gray","red"])
save("size_plot.html", p)
