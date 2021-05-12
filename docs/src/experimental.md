# Experimental

The following are experimental features in PowerPlots.  They may change or dissapear. To use the experimental features, the experimental module must be imported.

```julia
julia> using PowerPlots
julia> using PowerPlots.Experimental
```

## Apply geographic coordinates

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
