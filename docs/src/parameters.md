# Parameter Arguments
The following parameters can be used to as keyword arguments to modify a plot
## Plot parameters
These paramters modify the entire plot.

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `width`     | width of the plot in pixels | 500 |
| `height`    | height of the plot in pixels | 500 |



## Component Parameters
These parameters modify a specific component.
### Toggles
There are several component 'toggle' parameters that control whether certain display properties of components are on or off. These accept boolean values.
| Keyword | Description | Default |
| ------- | ----------- | ------- |
| `show_flow` | whether flow arrows are displayed | `true` |
| `show_flow_legend` | whether the legend for the flow arrows is shown | `false` |
### Color
The color arguments can accept several inputs.  A single color can be specified using a color name as a symbol or a string.  [CSS color](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value) names are supported.  In addition, hex color values in a string are supported.

```julia
powerplot(case; branch_color=:yellow)
powerplot(case; branch_color="yellow")
powerplot(case; branch_color="#FFA71A")
```

A color range can be created by using several colors in an array. The range is used when component data is specified.

```julia
powerplot(case; branch_color=[:red, "yellow", "#0000FF"])
```

A color scheme from `ColorSchemes.jl` can be used, but the ColorScheme must be converted to an array of colors that can be interpreted by VegaLite.

```julia
using ColorSchemes
powerplot(case; branch_color=colorscheme2array(ColorSchemes.colorschemes[:tableau_10]))
```

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `branch_color`     | set the color of a branch | `["#3182BD", "#5798CA", "#7CAED6", "#A0C5E2", "#C6DBEF"]` |
| `dcline_color`    | set the color of a DC line | `["#756BB1", "#8F87C0", "#A8A3CE", "#C0BEDC", "#DADAEB"]` |
| `connector_color`    | set the color of a connector | `[:gray]` |
| `gen_color`    |  set the color of a generator | `["#E6550D", "#EB7433", "#F19358", "#F8B17C", "#FDD0A2"]` |
| `bus_color`    |  set the color of a bus | `["#31A354", "#57B46F", "#7CC68A", "#A1D8A5", "#C7E9C0"]` |
| `node_color`    |  set the color of all buses and generators | N/A |
| `edge_color`    |  set the color of all branches, DC lines, and connectors | N/A|
| `flow_color`  | set the color of flow arrows | `:black`


### Size
The size argument sets the size of a component.  The size does not vary with data in the base plot.

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `branch_size`     | set the size of a branch | `5` |
| `dcline_size`    | set the size of a DC line | `5` |
| `connector_size`    | set the size of a connector | `3` |
| `gen_size`    |  set the size of a generator | `500` |
| `bus_size`    |  set the size of a bus | `500` |
| `node_size`    |  set the size of all buses and generators | N/A |
| `edge_size`    |  set the size of all branches, DC lines, and connectors | N/A |

### Data
The data argument selects the data from the component dictionary to use in the visualization.  The data argument can be a string or a symbol.  The data value modifes the color of a component based on the color range.

```julia
powerplot(case; gen_data=:pmax)
powerplot(case; gen_data=:pmin)
```

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `branch_data`     | set the data of a branch | `"ComponentType"` |
| `dcline_data`    | set the data of a DC line | `"ComponentType"` |
| `connector_data`    | set the data of a connector | `"ComponentType"` |
| `gen_data`    |  set the data of a generator | `"ComponentType"` |
| `bus_data`    |  set the data of a bus | `"ComponentType"` |


### Data Type
The Data Type in [VegaLite](https://vega.github.io/vega-lite/docs/type.html) can be `:nominal`, `:ordinal`, or `:quantintative`.  `:nominal` and `:ordinal` are both discrete values, and `:quantitative` is continuous.  In the context of the simple `powerplot`, there is no distinction  between `:nominal` and `:ordinal`.

```julia
powerplot(case; gen_data=:pg, gen_data_type=:quantitative) # the pg is continous, so use a continous scale
powerplot(case; gen_data=:index, gen_data_type=:nominal) # the index is a discrete value, so use a discrete scale
```

| Keyword     | Description | Default |
| ----------- | ----------- | ------- |
| `branch_data_type`     | set the data type of a branch | `:nominal` |
| `dcline_data_type`    | set the data type of a DC line | `:nominal` |
| `connector_data_type`    | set the data type of a connector | `:nominal` |
| `gen_data_type`    |  set the data type of a generator | `:nominal` |
| `bus_data_type`    |  set the data type of a bus | `:nominal` |
