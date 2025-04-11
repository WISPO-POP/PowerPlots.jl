# PowerPlots.jl Documentation

```@meta
CurrentModule = PowerPlots
```
[PowerPlots.jl](https://github.com/WISPO-POP/PowerPlots.jl) is a package for visualizing power grids, using the data spec from [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) and [PowerModelsDistribution.jl](https://github.com/lanl-ansi/PowerModelsDistribution.jl). This package uses [VegaLite.jl](https://github.com/queryverse/VegaLite.jl) as the plotting backend.

## Installation
```julia
pkg> add PowerPlots
```

## Basic Overview
Open a power systems case using [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) and run the command `powerplot` on the data.

```@example overview
using PowerModels
using PowerPlots
case = parse_file("case14.m")
powerplot(case)
```

The function creates a layout for the graph and plots the system.  The plot is interactive, and hovering over a component allows you to see the component data. By default, plots are displayed in a browser window but using [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl) will display plots in its own window.  Using the VSCode extension will display plots in the plot pane.

**NOTE:** Interactive VegaLite plots are not currently supported by some [notebooks](https://www.queryverse.org/VegaLite.jl/stable/gettingstarted/installation/#Notebook-frontends-1), like Jupyter Notebook. If you use Jupyter Notebook, you can using [ElectronDisplay.jl](https://github.com/queryverse/ElectronDisplay.jl) to display interactive plots.


## Creating Visualizations
The primary use for PowerPlots is to visualize data in the PowerModels dictionary.  Each component can specify a data value to visualize, such as the `pmax` for the generators or the `rate_a` of the branches.

```@example overview
powerplot(case;
    :gen=>(:data=>:pmax),
    :branch=>(:data=>:rate_a, :color=>[:white, :blue], :data_type=>:quantitative),
)
```

### Altering Data
New data can be added to the dictionary and visualized as well.
```@example overview
case["gen"]["1"]["gen_type"] = "PV"
case["gen"]["2"]["gen_type"] = "Coal"
case["gen"]["3"]["gen_type"] = "Hydro"
case["gen"]["4"]["gen_type"] = "CCGT"
case["gen"]["5"]["gen_type"] = "Wind"

using ColorSchemes
powerplot(case;
    connected_components=[:gen], edge_components=[:branch],
    :gen=>(:data=>:gen_type, :color=>colorscheme2array(ColorSchemes.:colorschemes[:seaborn_deep])),
    :bus=>(:color=>:black),
)
```

