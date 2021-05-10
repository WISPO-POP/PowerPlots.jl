## Initialize
```@example power_data
using PowerPlots, PowerModels
data = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
```

## Default Plot
Create a powerplot with default settings.
```@example power_data
powerplot(data)
```

## Colors
The colors of the components can be set, using simple keywords. Any valid [CSS color](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value) can be used.
```@example power_data
powerplot(data, bus_color=["orange"], gen_color=[:purple], branch_color=["#AFAFAF"])
```

The aliases `node_color` and `edge_color` can overwrite all nodes and edges respectively. (does this apply in the order the keywords are placed?)

```@example power_data
powerplot(data; node_color=["red"], edge_color=["purple"])
```

## Size
The size of components can be set similarly.  A good size for node devices is typically \approx 100x larger than edge devices.
```@example power_data
powerplot(data, bus_size=1000, gen_size=100, branch_size=2, connector_size=10)
```

Aliases exist override all node and edge sizes.
```@example power_data
powerplot(data, node_size=1000, edge_size=10)
```

## System Data
Component data values from the PowerModels dictionary can be plotted by specfying the dictionary key.

```@example power_data
p = powerplot(data, bus_data="va", bus_data_type="quantitative")
```

```@example power_data
p = powerplot(data, branch_data="index",
                    branch_data_type="nominal",
                    gen_data="pmax",
                    gen_data_type="quantitative",
)
```

### Color Schemes
Color ranges are automatically interpolated from a range that is provided.  If only a single color is given, the component will not change color based on the data.

```@example power_data
p = powerplot(data,
                    gen_data="pmax",
                    gen_data_type="quantitative",
                    gen_color=["#232323","#AAFAFA"]
)
```

Color schemes from the package `ColorSchemes.jl` can also be used to specify a color range.

```@example power_data
using ColorSchemes
powerplot(data;
            gen_data=:pmax,
            gen_color=colorscheme2array(ColorSchemes.colorschemes[:summer]),
            gen_data_type=:quantitative
)
```

## Plot System Data
