## Initialize
```@example power_data
using PowerPlots, PowerModels
data = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
```

## Default Plot
Create a powerplot with default settings.
```@example power_data
plot_vega(data)
```

## Colors
The colors of the components can be set, using simple keywords. Any valid [CSS color](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value) can be used.
```@example power_data
plot_vega(data, bus_color=["orange"], gen_color=[:purple], branch_color=["#AFAFAF"])
```

The aliases `node_color` and `edge_color` can overwrite all nodes and edges respectively. (does this apply in the order the keywords are placed?)

```@example power_data
plot_vega(data; node_color=["red"], edge_color=["purple")
```

## Size
The size of components can be set similarly.  A good size for node devices is typically \approx 100x larger than edge devices.
```@example power_data
plot_vega(data, bus_size=1000, gen_size=100, branch_size=2, connector_size=10)
```

Aliases exist override all node and edge sizes.
```@example power_data
plot_vega(data, node_size=1000, edge_size=10)
```

## Color Schemes and System Data
The color can be set to a range, and a data value can be associated with each element.  Here, the color range for buses is from gray to red, and the data shown is the votlage angle.

```@example power_data
p = plot_vega(data, bus_data="va", bus_data_type="quantitative", bus_color=["gray","red"])
```

```@example power_data
p = plot_vega(data, branch_data="index",
                    branch_data_type="nominal",
                    branch_color=["green","yellow"],
                    gen_data="pmax",
                    gen_data_type="quantitative",
                    gen_color=["#232323","#AAFAFA"]
)
```

## Plot System Data
