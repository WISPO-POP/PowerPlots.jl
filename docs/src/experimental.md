# Experimental

The following are experimental features in PowerPlots.  They may change or disappear. To use the experimental features, the experimental module must be imported.

```julia
julia> using PowerPlots
julia> using PowerPlots.Experimental
```

## Apply geographic coordinates
Change the coordinates from Cartesian to a geographic projection. This is experimental because it is not well tested.
VegaLite does not support geographic projections and zooming/panning yet, so combining with `add_zoom!` will not work.

```@example
using PowerPlots
using PowerPlots.Experimental
using PowerModels
using Setfield

case = parse_file("WI_grid.m")
for (loadid,load_d) in case["load_data"] # append load coordinates
    for (k,v) in load_d
        case["load"][loadid][k]=v
    end
end
p1 = powerplot(case; width=300, height=300, fixed=true, flow=false, node_size=100, edge_size=3, parallel_edge_offset=.03)

p2 = deepcopy(p1)
PowerPlots.Experimental.cartesian2geo!(p2)

@set! p1.title = "Cartesian"
@set! p2.title = "Geo Projection"

p = [p1 p2]

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
