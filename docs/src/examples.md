## Initialize
```julia
using PowerPlots, PowerModels
case = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
```

## Default Plot
Create a powerplot with default settings.
```julia
powerplot(case)
```

## Colors
Any valid [CSS color](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value) can be used.
```julia
powerplot(case; bus_color="cyan", gen_color=:orange, branch_color="slategrey", dcline_color="#ffa500", connector_color="brown")
```

The aliases `node_color` and `edge_color` can overwrite all nodes and edges respectively. (does this apply in the order the keywords are placed?)

```julia
powerplot(case; node_color="red", edge_color="purple")
```

## Size

## Color Schemes

## Plot System Data
