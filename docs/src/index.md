# PowerPlots.jl Documentation

```@meta
CurrentModule = PowerPlots
```
PowerPlots.jl is a package for visualizing power grids, using the data spec from PowerModels.jl. This package uses VegaLite.jl as the plotting backend.

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

The function creates a layout for the graph and plots the system.  The plot is interactive, and hovering over a component allows you to see the component data. By default, plots are displayed in a browser window but using `ElectronDisplay.jl` will display plots in its own window.  Using the VSCode extension will display plots in the plot pane.

**NOTE:** Interactive plots are not currently supported by some [notebooks](https://www.queryverse.org/VegaLite.jl/stable/gettingstarted/installation/#Notebook-frontends-1), like Jupyter Notebook. If using Jupyter Notebook, you can using `ElectronDisplay.jl` to display interactive plots.


## Creating Visualizations
The primary use for PowerPlots is to visualize data in the PowerModels dictionary.  Each component can specify a data value to visualize, such as the `pmax` for the generators or the `rate_a` of the branches.

```@example overview
powerplot(case;
    gen_data=:pmax,
    branch_data=:rate_a,
    branch_color=[:white,:blue],
    branch_data_type=:quantitative
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
    gen_data=:gen_type,
    gen_color = colorscheme2array(ColorSchemes.colorschemes[:seaborn_deep]),
    bus_color=:black
)
```

