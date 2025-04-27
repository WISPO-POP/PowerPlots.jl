# Experimental

The following are experimental features in PowerPlots.  They may change or disappear. To use the experimental features, the experimental module must be imported.

```julia
julia> using PowerPlots
julia> using PowerPlots.Experimental
```

## Apply geographic coordinates
Change the coordinates from Cartesian to a geographic projection. This is experimental because it is not well tested.
VegaLite does not support geographic projections and zooming/panning yet, so combining with `add_zoom!` will not work.

```@example geo_plot
using PowerPlots
using PowerPlots.Experimental
using PowerModels
using Setfield

 # A case file with geographic coordinates for each bus, load, and generator
case = parse_file("WI_grid.m")

# powermodels does not extend the load dictionary, so we need to add coordinates manually
for (loadid,load_d) in case["load_data"] # append load coordinates
    case["load"][loadid]["xcoord_1"] = load_d["xcoord_1"]
    case["load"][loadid]["ycoord_1"] = load_d["ycoord_1"]
end

x_min = minimum([case["bus"][i]["xcoord_1"] for i in keys(case["bus"])])
x_max = maximum([case["bus"][i]["xcoord_1"] for i in keys(case["bus"])])
y_min = minimum([case["bus"][i]["ycoord_1"] for i in keys(case["bus"])])
y_max = maximum([case["bus"][i]["ycoord_1"] for i in keys(case["bus"])])

p1 = powerplot(case; width=300, height=300, fixed=true, parallel_edge_offset=0.03,
            connected_components=[:gen, :load],
            branch=(:size=>3, :show_flow=>false),
            gen=(:size=>100),
            load=(:size=>100)
)

# center plot on the geographic coordinates, rather than the default (0,0)
p1.layer[1]["layer"][1]["encoding"]["x"]["scale"]  = Dict("domain" => [x_min, x_max])
p1.layer[1]["layer"][1]["encoding"]["x2"]["scale"] = Dict("domain" => [x_min, x_max])
p1.layer[1]["layer"][1]["encoding"]["y"]["scale"]  = Dict("domain" => [y_min, y_max])
p1.layer[1]["layer"][1]["encoding"]["y2"]["scale"] = Dict("domain" => [y_min, y_max])

p2 = deepcopy(p1)
PowerPlots.Experimental.cartesian2geo!(p2)

@set! p1.title = "Cartesian"
@set! p2.title = "Geo Projection"

p = [p1 p2]
```

This can be used to layer a powerplot over a geographic map plotted in vegalite.

```@example geo_plot
using VegaLite, VegaDatasets
us10m = dataset("us-10m")

p3 = @vlplot(
    :geoshape,
    width=300, height=300,
    data={
        values=us10m,
        format={
            type=:topojson,
            feature=:states
        }
    },
    transform=[
        {filter={field=:id,equal=55}}, # 55 = Wisconsin
    ],
    projection={
        type=:albersUsa
    },
    color={value="#555555"}
)
@vlplot()+p3 + p2
```


## Add Zoom
To enable zoom and pan on a plot use `add_zoom!(plot)`.  This is experimental because hover will only work on the first layer (branches) when zoom is enabled.

```@example
using PowerPlots
using PowerModels
case = parse_file("case14.m")
plot1 = powerplot(case)
PowerPlots.Experimental.add_zoom!(plot1)

plot1
```
