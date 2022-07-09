# Basic Examples
Simple examples for setting the data visualization and changing the color or size of components.


## Initialize
```@example power_data
using PowerPlots, PowerModels
data = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
```

## Default Plot
```@example power_data
powerplot(data)
```

## Change Plot Size
```@example power_data
powerplot(data; width=300, height=300)
```

## Modify Colors
The colors of the components can be set, using simple keywords. Any valid [CSS color](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value) can be used. If a single color is used, the component will not change color based on system data.  See [Color Ranges](@ref) for how to use multiple colors.

```@example power_data
powerplot(data; bus_color="orange",
                gen_color=:purple,
                branch_color="#AFAFAF",
                width=300, height=300)
```

The aliases `node_color` and `edge_color` can overwrite all nodes and edges respectively.

```@example power_data
powerplot(data; node_color="red", edge_color="purple", width=300, height=300)
```

## Modify Component Size
The size of components can be set similarly.  A good size for node devices is typically around 100x larger than edge devices.
```@example power_data
powerplot(data, bus_size=1000, gen_size=100, branch_size=2, connector_size=10)
```

Aliases to overide all node and edge sizes.
```@example power_data
powerplot(data, node_size=1000, edge_size=10, width=300, height=300)
```

## Visualizing System Data
Component data values from the PowerModels dictionary can be plotted by specfying the dictionary key. The key can be either a string or a symbol.  The data type can be `:ordinal`, `:nominal`, or `:quantitative`.

```@example power_data
p = powerplot(data, bus_data="bus_type",
                    bus_data_type="nominal",
                    branch_data="index",
                    branch_data_type="ordinal",
                    gen_data="pmax",
                    gen_data_type="quantitative",
                    width=300, height=300
)
```

### Power Flow
If the variables `pf` (power from) and `pt` (power to) exist in the data, power flow directions can be visualized using the `show_flow` boolean toggle (true by default).
```@example power_data
# Solve AC power flow and add values to data dictionary
using Ipopt, PowerModels
result = solve_ac_opf(data, Ipopt.Optimizer)
update_data!(data, result["solution"])

p = powerplot(data, show_flow=true)
```

### Color Ranges
Color ranges are automatically interpolated from a range that is provided.  If only a single color is given, the component will not change color based on the data.

```@example power_data
p = powerplot(data,
                    gen_data="pmax",
                    gen_data_type="quantitative",
                    gen_color=["#232323","#AAFAFA"],
                    width=300, height=300
)
```

### Color Schemes
Color schemes from the package `ColorSchemes.jl` can also be used to specify a color range.

```@example power_data
using ColorSchemes
powerplot(data;
            gen_data=:pmax,
            gen_color=colorscheme2array(ColorSchemes.colorschemes[:summer]),
            gen_data_type=:quantitative,
            width=300, height=300
)
```
## Distribution Grids
Open a three-phase distribution system case using [PowerModelsDistribution.jl](https://github.com/lanl-ansi/PowerModelsDistribution.jl) and run the command `powerplot` on the data.

```
using PowerModelsDistribution
using PowerPlots
eng = PowerModelsDistribution.parse_file("$(joinpath(dirname(pathof(PowerModelsDistribution)), ".."))/test/data/opendss/case3_unbalanced.dss")
math = transform_data_model(eng)
powerplot(math)
# example works, but fails to run in documentation
```

## Multinetworks
`powerplot` detects if a network is a multinetwork and will create a slider to select which network to view.
```@example power_data
data_mn = PowerModels.replicate(data, 5)

# create random data for each time period
for (nwid,nw) in data_mn["nw"]
    for (branchid,branch) in nw["branch"]
        branch["value"] = rand()
    end
end

powerplot(data_mn, branch_data=:value, branch_data_type=:quantitative)
