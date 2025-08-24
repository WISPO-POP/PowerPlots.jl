# Parameter Arguments
The following parameters can be used to as keyword arguments to modify a plot
## Plot parameters
These parameters modify the entire plot.

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `width`     | width of the plot in pixels | `500` |
| `height`    | height of the plot in pixels | `500` |
| `layout_algorithm` | algorithm for generating network layout (see [Layouts](@ref)) | `kamada_kawai` |
| `fixed` | use fixed coordinates from network model | `false` |
| `parallel_edge_offset` | offset distance between parallel edges | `0.05` |
| `node_components` | string or symbol array of node components to plot | `default_node_types`|
| `edge_components` | string or symbol array of edge components to plot | `default_edge_types`|
| `connected_components` | string or symbol array of connected components to plot | `default_connected_types`|

The current set of default component types includes:
```@example
using PowerPlots #hide
default_node_types
```
```@example
using PowerPlots #hide
default_edge_types
```
```@example
using PowerPlots #hide
default_connected_types
```

## Component Parameters
These parameters modify a specific component.

### Color
The `:color` argument can accept several inputs.  A single color can be specified using a color name as a symbol or a string.  [CSS color](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value) names are supported.  In addition, hex color values in a string are supported.

```julia
powerplot(case; branch=(:color=:yellow))
powerplot(case; branch=(:color="yellow"))
powerplot(case; branch=(:color="#FFA71A"))
```

A color range can be created by using several colors in an array. The range is used when component data is specified.

```julia
powerplot(case; branch=(:color=>[:red, "yellow", "#0000FF"]))
```

A color scheme from `ColorSchemes.jl` can be used, but the ColorScheme must be converted to an array of colors that can be interpreted by VegaLite.

```julia
using ColorSchemes
powerplot(case; branch=(:color=>colorscheme2array(ColorSchemes.colorschemes[:tableau_10])))
```

Default colors are determined by the order the components are plotted, shown in the legend.  The default color profiles are:

```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[1]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[2]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[3]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[4]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[5]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[6]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[7]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[8]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[9]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[10]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[11]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[12]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[13]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[14]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[15]]) # hide
```
```@example
using PowerPlots, Colors # hide
parse.(Colorant, color_schemes[component_color_order[16]]) # hide
```

### Flow
Power flow can be shown on edges of the network.  For each edge component, the following parameters are available:

| Keyword | Description | Default |
| ------- | ----------- | ------- |
| `show_flow` | whether flow arrows representing 'pt' are displayed on edges | `false` |
| `show_flow_legend` | whether the legend for the flow arrows is shown | `false` |

```@example power_data
powerplot(case; branch=(:show_flow=>true, :show_flow_legend=>true))
```


### Size
The `:size` argument sets the size of a component.  The size does not vary with data in the base plot.

| Component     | Description | Default |
| ----------- | ----------- | ------- |
| `edge`     | default size of all edges except connector | `5` |
| `connector`    | default size of connector | `3` |
| `node`    |  set the size of all nodes | `500` |

```julia
powerplot(case; branch=(:size=>10), gen=(:size=>250))
```


The size of the flow arrows is a keyword that is a subset of the edge it models. However, the only first plotted component in the legend will use the `flow_arrow_size_range` keyword.  All subsequent components will use the same range as the first.
```julia
powerplot(case;
    branch=(:show_flow=>true, :show_flow_legend=>true,
     :flow_arrow_size_range=>[100,500]),
    switch=(:show_flow=>true, :show_flow_legend=>true,
     :flow_arrow_size_range=>[500,3000])
)
```


### Data
The `:data` argument selects the data from the component dictionary to use in the visualization.  The data argument can be a string or a symbol.  The data value modifies the color of a component based on the color range.

```julia
powerplot(case; gen(:data=:pmax))
powerplot(case; gen(:data=:pmin))
```


### Datatype
The datatypes in [VegaLite](https://vega.github.io/vega-lite/docs/type.html) can be `:nominal`, `:ordinal`, or `:quantintative`.  `:nominal` and `:ordinal` are both discrete values, and `:quantitative` is continuous.  In the context of the simple `powerplot`, there is no distinction between `:nominal` and `:ordinal`.  The default data type is `nominal`.

```julia
powerplot(case; gen(:data=:pg, :data_type=:quantitative)) # the pg is continous, so use a continous scale
powerplot(case; gen(:data=:index, :data_type=:nominal)) # the index is a discrete value, so use a discrete scale
```

### Other Parameters
The length of the dashes on the connector lines can be controlled with the `:dash` keyword.
The value is a two element array, with the first term representing the length of the gap and the second term representing the length of the dash.

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `:dash`     | set dash size for connectors | `[4,4]` |

```julia
powerplot(case, connector = (:dash=>[2,2]))
powerplot(case, connector = (:dash=>[2,8]))
```