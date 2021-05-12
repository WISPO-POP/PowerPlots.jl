# Experimental

The following are experimental features in PowerPlots.  They may change or dissapear. To use the experimental features, the experimental module must be imported.

```julia
julia> using PowerPlots
julia> using PowerPlots.Experimental
```

## Apply geographic coordinates
Change the coordinates from cartesian to a geographic projection. This is experimental because it is not well tested.
VegaLite does not support geographic projections and zooming/panning yet, so combining with `add_zoom!` will not work.

```@example
using PowerPlots
using PowerPlots.Experimental
using PowerModels
using Setfield

#TODO use a case with actual geo coordinates to show the difference.
case = parse_file("case14.m")
p1 = powerplot(case; width=300, height=300)
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
