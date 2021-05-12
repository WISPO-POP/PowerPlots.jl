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

case = parse_file("case14.m")
plot1 = powerplot(case; width=300, height=300)
plot2 = deepcopy(plot1)
PowerPlots.Experimental.cartesian2geo!(plot2)

p = [plot1 plot2]
p
```
