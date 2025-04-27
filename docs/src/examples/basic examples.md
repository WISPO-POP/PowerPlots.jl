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
powerplot(data; bus=(:color=>"orange"),
                gen=(:color=>:purple),
                branch=(:color=>"#AFAFAF"),
                load=(:color=>:black),
                width=300, height=300)
```

## Modify Component Size
The size of components can be set similarly.  A good size for node devices is typically around 100x larger than edge devices.
```@example power_data
powerplot(data, bus=(:size=>1000), gen=(:size=>100),
    load=(:size=>200), branch=(:size=>2), connector=(:size=>10))
```

# Visualizing System Data
Component data values from the PowerModels dictionary can be plotted by specifying the dictionary key. The key can be either a string or a symbol.  The data type can be `:ordinal`, `:nominal`, or `:quantitative`.

```@example power_data
p = powerplot(data, bus    = (:data=>"bus_type", :data_type=>"nominal"),
                    branch = (:data=>"index", :data_type=>"ordinal"),
                    gen    = (:data=>"pmax", :data_type=>"quantitative"),
                    load   = (:data=>"pd",  :data_type=>"quantitative"),
                    width = 300, height=300
)
```

## Color Ranges
Color ranges are automatically interpolated from a range that is provided.  If only a single color is given, the component will not change color based on the data.

```@example power_data
p = powerplot(data, width=300, height=300,
    gen=(:data=>"pmax", :data_type=>"quantitative", :color=>["#232323","#AAFAFA"]),
)
```

## Color Schemes
Color schemes from the package `ColorSchemes.jl` can also be used to specify a color range.

```@example power_data
using ColorSchemes
p = powerplot(data, width=300, height=300,
    gen=(
        :data=>"pmax", :data_type=>"quantitative",
        :color=>colorscheme2array(ColorSchemes.colorschemes[:summer])
    ),
)
```

# Specify components for plotting
Default supported components for plotting are specified as:
```@example power_data
supported_connected_types
```

```@example power_data
supported_node_types
```

```@example power_data
supported_edge_types
```


By default, any of these components found in the data dictionary will be plotted.  However, it is possible to plot a subset of the components using the `components` keywords.  Here we plot only the buses and branches, and we do not plot the loads or generators.

```@example power_data
powerplot(data;
    edge_components=["branch"],
    node_components=[:bus],
    connected_components=[],
    width=300, height=300)
```

Additional components that are not a part of the default supported set can also be plotted.  For edges, the component dictionary must contain the keys `f_bus` and `t_bus`, which are the from and to bus numbers.  For nodes, the component dictionary must contain the key `bus` or `compname_bus`, which is the id of the connecting bus.
```@example power_data
data["new_edge"] = Dict(
    "1"=> Dict{String,Any}("f_bus"=>4, "t_bus"=>2, "index"=>1),
)
data["new_component"] = Dict(
    "1"=> Dict{String,Any}("bus"=>4, "index"=>1, "pmax"=> 100.5),
    # "2"=> Dict{String,Any}("new_component_bus"=>3, "index"=>2),
)
powerplot(data;
    edge_components=[:new_edge, :branch],
    node_components=[:bus],
    connected_components=["new_component"],
    width=300, height=300)
```


# Power Flow
If the variables `pf` (power from) and `pt` (power to) exist in the data, power flow directions can be visualized using the `show_flow` boolean toggle (true by default).

```@example power_flow
# Solve AC power flow and add values to data dictionary
using Ipopt, PowerModels, PowerPlots, PGLib
data = pglib("case5_pjm")
result = solve_ac_opf(data, Ipopt.Optimizer)
update_data!(data, result["solution"])

p = powerplot(data, branch=(:show_flow=>true))
```

# Filter Hover Text
The hover text can be filtered to show only the data that is of interest.  Each component is filtered separately.

```@example power_data
p = powerplot(data,
            load=(:hover=>["pd"]),
            gen=(:hover=>["pg", "pmin", "pmax"]),
            bus=(:hover=>[:vmin, :vmax]),
            branch=(:hover=>[]),
        )
```

# Multinetworks
`powerplot` detects if a network is a multinetwork and will create a slider to select which network to view.

```@example power_data
data_mn = PowerModels.replicate(data, 5)

# create random data for each time period
for (nwid,nw) in data_mn["nw"]
    for (branchid,branch) in nw["branch"]
        branch["value"] = rand()
    end
end

powerplot(data_mn, branch=(:data=>:value, :data_type=>:quantitative))
```

# Distribution Grids
Open a three-phase distribution system case using [PowerModelsDistribution.jl](https://github.com/lanl-ansi/PowerModelsDistribution.jl) and run the command `powerplot` on the data.

This dataset includes switches and transformers, which are then visualized in the powerplot.

```@example distribution
using PowerModelsDistribution
using PowerPlots
eng = PowerModelsDistribution.parse_file("$(joinpath(dirname(pathof(PowerModelsDistribution)), ".."))/test/data/opendss/trans_3w_center_tap.dss")
powerplot(eng)
```

The mathematical model of the distribution system can be visualized as well.
```@example distribution
math = transform_data_model(eng)
powerplot(math)
```

# File output
Save a file to disk as a PNG, SVG, PDF, or HTML file.  The file name must end with the appropriate extension.

```julia
    save("powerplot.svg", p)
    save("powerplot.png", p)
    save("powerplot.pdf", p)
    save("powerplot.html", p)
```

