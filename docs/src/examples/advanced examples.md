# Advanced Examples
The following information can be used as a basis for creating more complicated visualizations. Description of the internals is followed by examples of modifying the plots.


## Internal Structure
The following plot is not well-structured.  The legend is too tall, and it messes with the layout of the figure.  There is currently not a way to give arguments to `powerplot()` to modify this output, but instead you can alter the struct of the `powerplot` `p`.

```@example internal
# Read in data
using PowerPlots;
using PGLib;
case=pglib("case39_epri");

# Create PowerPlot
p = powerplot(case,
bus_data=:index, bus_data_type=:quantitative,
branch_data=:index, branch_data_type=:quantitative,
gen_data=:index, gen_data_type=:quantitative,
height=250, width=250, bus_size=100, gen_size=50, load_size=50,
)
```

PowerPlot.jl using Vegalite.jl to construct the figures. As an example of the structure of a VegaLite plot, here is julia syntax to create a plot with the [VegaLite](https://github.com/queryverse/VegaLite.jl) package:
```julia
using VegaLite, VegaDatasets

dataset("cars") |>
@vlplot(
    :point,
    x=:Horsepower,
    y=:Miles_per_Gallon,
    color=:Origin,
    width=400,
    height=400
)
```

And here is the JSON syntax from the [Vegalite](https://vega.github.io/vega-lite/examples/point_href.html) library:

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "description": "A scatterplot showing horsepower and miles per gallons that opens a Google search for the car that you click on.",
  "data": {"url": "data/cars.json"},
  "mark": "point",
  "encoding": {
    "x": {"field": "Horsepower", "type": "quantitative"},
    "y": {"field": "Miles_per_Gallon", "type": "quantitative"},
    "color": {"field": "Origin", "type": "nominal"},
  }
}
```

It is possible to inspect the internal structure of out plot `p` in json format which is as follows:

```json
p={
    "width": 250,
    "height": 250,
    "config": {"view": {"stroke": null}},
    "resolve": {"scale": {"color": "independent"}},
    "encoding": {
      "x": {
        "axis": null,
        "scale": {"domain": [-5.988417823876669, 5.662858327789515]}
      },
      "y": {
        "axis": null,
        "scale": {"domain": [-4.888872782545868, 5.89355161792763]}
      }
    },
    "layer": [
      # each layer goes here
    ]
  }
```

At the top level are fields that determine the default structure for every layer of our plot. Then, inside of layers is the structure for each component layer in PowerPlots. The order of the layers determines the order in which they are drawn, and is shown in the order of the legends.  Here is the layer for the generators, the fourth layer:

```json
"layer": [
      {
       # branch layer
      },
      {
        # connector layer
      },
      {
        # bus layer
      },
      {
        "data": { # case["gen"] data here},
        "mark": {"tooltip": {"content": "data"}, "opacity": 1, "type": "circle"},
        "encoding": {
          "x": {"type": "quantitative", "field": "xcoord_1"},
          "y": {"type": "quantitative", "field": "ycoord_1"},
          "size": {"value": 200},
          "color": {
            "field": "index",
            "type": "quantitative",
            "title": "Gen",
            "scale": {
              "range": ["#E6550D", "#EB7433", "#F19358", "#F8B17C", "#FDD0A2"]
            }
          }
        }
      },
      {
        # load layer
      }
    ]
```

You can see that `gen["encoding']["color"]["field"]` has the value `"index"`, which is what we set the value to when creating power plot.  We could change this value to `pmin` by running
```julia
p.layer[4]["encoding"]["color"]["field"]="pmin"
```
Then when displaying the plot again, the figure would show the `pmin` value (0 for all generators) instead of `index` for the generators.


```@example internal
p.layer[4]["encoding"]["color"]["field"]="pmin"
p
```

You can also modify the powerplot to include values that are not present.
The parameters you can use are listed in the documentation for VegaLite.
For example, we can modify the legend title for the generator by setting the title.

The legend parameters are available [here](https://vega.github.io/vega-lite/docs/legend.html)

```@example internal
p.layer[4]["encoding"]["color"]["legend"]=Dict("title"=>"Minimum Power")
p
```

We can also remove the legend of a component type.  The following removes the legend for `bus`.


```@example internal
p.layer[3]["encoding"]["color"]["legend"]=false
p
```

We can remove the legend for branch as well, however the structure is slightly different.  The branch layer contains 2 layers, the first is the powerlines themselves, and the second is for plotting arrows that indicate power flow when the `pf` value exists in `data["branch"]["1"]["pf"]`.  The power line legend can be removed as follows:

```@example internal
p.layer[1]["layer"][1]["encoding"]["color"]["legend"]=false
p
```

While modifying the layers of a powerplot is as simple as editing a dictionary, modifying the top level parameters of a powerplot cannot be done without the package `SetField` to modify the struct.

For example:
```julia internal
p.width = 250
# ERROR it is not possible to modify the immutable struct of a VLSpec (which are all of the top level parameters)
```

Using `Setfield` we can modify the top level parameters of the plot.

```@example internal
using Setfield
@set! p.width=500  # overide the current value in p.width
@set! p.encoding.color=Dict("legend"=>Dict("orient"=>"bottom"))
    # encoding field exists, but color field does not exist at the top level.  Add parameters for the color field as a dictionary.
    # The generator legend is not affected by the top level encoding["color"]["legend"] setting because it has its own legend field
```

Here is a summary code sample to modify a power plot.
For further information about the possible parameters you can use, look at the VegaLite [documentation](https://vega.github.io/vega-lite/docs/) and look at the nested structure for settings parameters.

```@example internal
# Create PowerPlot
p = powerplot(case,
bus_data=:index, bus_data_type=:quantitative,
branch_data=:index, branch_data_type=:quantitative,
gen_data=:index, gen_data_type=:quantitative,
load_data=:index, load_data_type=:quantitative,
height=250, width=250
)

# get maximum index value to use for maximum legend scale
max_index = maximum([maximum([v["index"] for (k,v) in case[comp_type]]) for comp_type in ["bus","gen","branch"]])
# set legend title to Index ID
p.layer[1]["layer"][1]["encoding"]["color"]["legend"]=Dict("title"=>"Index ID", "gradientLength"=>100)  # branch

# remove all but one legends but layer 1
p.layer[2]["encoding"]["color"]["legend"]=false # connector
p.layer[3]["encoding"]["color"]["legend"]=false # bus
p.layer[4]["encoding"]["color"]["legend"]=false # gen
p.layer[5]["encoding"]["color"]["legend"]=false # load

# set all components to the same color scheme
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["range"]=["purple","#FFFF00"]
p.layer[2]["encoding"]["color"]["scale"]["range"]=["purple","#FFFF00"]
p.layer[3]["encoding"]["color"]["scale"]["range"]=["purple","#FFFF00"]
p.layer[4]["encoding"]["color"]["scale"]["range"]=["purple","#FFFF00"]
p.layer[5]["encoding"]["color"]["scale"]["range"]=["purple","#FFFF00"]

# set the color scale from 0 to the maximum index of all components
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["domain"]=[0,max_index]
p.layer[2]["encoding"]["color"]["scale"]["domain"]=[0,max_index]
p.layer[3]["encoding"]["color"]["scale"]["domain"]=[0,max_index]
p.layer[4]["encoding"]["color"]["scale"]["domain"]=[0,max_index]
p.layer[5]["encoding"]["color"]["scale"]["domain"]=[0,max_index]

# set the title of the figure
@set! p.title="Plot Title"
```


## Example Modifications
The following are examples for altering various aspects of a `powerplot`.

### Basic alterations
```julia
@set! p.title="Title"
@set! p.title=Dict("text"=>["Title", "Newline"],"fontSize"=>20)
@set! p.width=100
@set! p.height=100
```

### Alter data scales
```julia
# set the domain for the color (set to min/max of data by default)
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["domainMax"]=200
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["domainMin"]=20
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["domain"]=[0, var]
p.layer[4]["encoding"]["color"]["scale"]["domain"]=[0, 1]
p.layer[5]["encoding"]["color"]["scale"]["domain"] = ["Total","Partial","No Shed"]

# set the range
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["range"]=["#0000FF" "#FFFF00"]
p.layer[1]["layer"][1]["encoding"]["size"]["scale"]["range"]=[20 100]
p.layer[1]["layer"][1]["encoding"]["size"]["scale"]["rangeMin"]=20
p.layer[1]["layer"][1]["encoding"]["size"]["scale"]["rangeMax"]=100
```

### Alter legend
```julia
# modify the legend of the color data (size, shape can be used as well)
p.layer[1]["layer"][1]["encoding"]["color"]["legend"]=Dict(
    "title"=>"Line",
    "gradientLength"=>100,
    "labelExpr"=>"datum.label=='true' ? 'Contingency Set': 'Radial Lines'",
    "labelFontSize"=>13,
    "offset"=>5,
    "orient"=>"none",
    "legendX"=>260,
    "legendY"=>100,
)
p.layer[2]["encoding"]["color"]["legend"]=Dict("labelExpr"=>"")
p.layer[3]["encoding"]["color"]["legend"]=Dict("labelExpr"=>"datum.label==1 ? 'True': 'False'")
p.layer[2]["encoding"]["color"]["legend"]=false
```

### Alter component size from data
Alter the 'size' field (all previous `color` domain/scale/legend changes can be made to `size` as well)
```julia
# default set to specific size
p.layer[4]["encoding"]["size"]["value"]=50

# override size["value"] by  creating a new 'size' dictionary
p.layer[4]["encoding"]["size"]  = Dict("field"=>"pmax", "type"=>"quantitative")
p.layer[5]["encoding"]["size"]  = Dict("field"=>"pd", "type"=>"quantitative")

# update the size dictionary with additional information
@set! p.layer[4]["encoding"]["size"]["scale"]=Dict("range"=> [20,100])

# set resolve to allow components to have independent legends for 'size'
# :shared set all components to have same legends for 'size' field
@set! p.resolve.scale.size = :independent
```

### Alter component shapes
```julia
p.layer[1]["layer"][1]["encoding"]["strokeDash"]=Dict("value"=>[4,4]) # make a line dashed
p.layer[1]["layer"][1]["encoding"]["strokeDash"]=Dict("field"=>"rate_a") # dash length from data
p.layer[3]["mark"]["type"]=:square # :circle :square :point
p.layer[3]["mark"]["opacity"]=0.7

# with a point mark, several shapes can be used
p.layer[4]["mark"]["type"]="point"
p.layer[4]["mark"]["shape"]="triangle-up"
# "circle", "square", "cross", "diamond", "triangle-up",
# "triangle-down", "triangle-right", or "triangle-left"

# shape can also be determined by data
p.layer[4]["mark"]["type"]="point"
p.layer[4]["encoding"]["shape"]=Dict("field"=>"ComponentType")
p.layer[5]["mark"]["type"]="point"
p.layer[5]["encoding"]["shape"]=Dict("field"=>"ComponentType")

# set resolve to allow components to have independent legends for 'shape'
# :shared set all components to have same legends for 'shape' field
@set! p.resolve.scale.shape = :independent
```

## Code Examples
The following are code examples that utilize some of the above modifications and more.

### Arrange powerplots in a grid
```@example internal
p4 = [] # create series of 4 plots
for i in 1:4
    p_temp = @set p.title="$i"
    push!(p4, p_temp)
end
p4=[p4... ; ] # vegalite concats these into a single plot
@set! p4.concat = p4.vconcat
@set! p4.columns = 2 # arrange in 2 columns
p4
```

### Power Flow
This example uses transforms to calculate the loading of the transmission lines and the generators.

```@example
using PowerModels
using PowerPlots
using ColorSchemes
using Setfield
using JuMP, Ipopt
case = parse_file("case14.m")
result = solve_ac_opf(case, optimizer_with_attributes(Ipopt.Optimizer, "print_level"=>0))
update_data!(case,result["solution"])

p = powerplot(case,
    gen_data=:pg,
    gen_data_type=:quantitative,
    branch_data=:pt,
    branch_data_type=:quantitative,
    branch_color=["black", "purple","red"],
    gen_color=["black", "purple","red"],
    flow_arrow_size_range=[0, 4000],
    load_color="#273D94",
    bus_color="#504F4F"
)

# set flow arrow color
p.layer[1]["layer"][2]["mark"]["color"]=:white
p.layer[1]["layer"][2]["mark"]["stroke"]=:black

# set branch color values
p.layer[1]["transform"] = Dict{String, Any}[
    Dict("calculate"=>"abs(datum.pt)/datum.rate_a*100", "as"=>"branch_Percent_Loading"),
    Dict("calculate"=>"abs(datum.pt)", "as"=>"BranchPower")
]
p.layer[1]["layer"][1]["encoding"]["color"]["field"]="branch_Percent_Loading"
p.layer[1]["layer"][1]["encoding"]["color"]["title"]="Branch Utilization %"
p.layer[1]["layer"][1]["encoding"]["color"]["scale"]["domain"]=[0,100]

# set generator color/size values
p.layer[4]["transform"] = Dict{String, Any}[
    Dict("calculate"=>"datum.pg/(datum.pmax+1e-9)*100", "as"=>"gen_Percent_Loading"), #handle 0/0 case
    Dict("calculate"=>"datum.pmax", "as"=>"GenPower")
]
p.layer[4]["encoding"]["color"]["field"]="gen_Percent_Loading"
p.layer[4]["encoding"]["color"]["scale"]["domain"]=[0,100]
p.layer[4]["encoding"]["color"]["title"]="Gen Utilization %"
p.layer[4]["encoding"]["size"]=Dict(
    "field"=>"GenPower", "title"=>"Gen Capacity [p.u.]",
    "type"=>"quantitative", "scale"=>Dict("range"=>[50,1000])
)

# set load size/shape
p.layer[5]["encoding"]["size"]=Dict(
    "field"=>"pd", "title"=>"Load Demand [p.u]",
    "type"=>"quantitative", "scale"=>Dict("range"=>[50,1000])
)
p.layer[5]["mark"]["type"]=:square

# set legend position for % utilization
p.layer[1]["layer"][1]["encoding"]["color"]["legend"]=Dict("orient"=>"bottom-right", "offset"=>-30)
p.layer[4]["encoding"]["color"]["legend"]=Dict("orient"=>"bottom-right")

@set! p.resolve.scale.size=:independent
@set! p.resolve.scale.color=:shared

p
```



