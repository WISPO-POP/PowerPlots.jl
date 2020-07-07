# PowerPlots

[![Build Status](https://travis-ci.com/noahrhodes/PowerPlots.jl.svg?branch=master)](https://travis-ci.com/noahrhodes/PowerPlots.jl)
[![Codecov](https://codecov.io/gh/noahrhodes/PowerPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/noahrhodes/PowerPlots.jl)

Tools for the analysis and visualization of PowerModels data and results.

BETA / IN ACTIVE DEVELOPMENT: Features will change quickly and without warning


## Using PowerPlots

The basic plot function for `PowerPlots` is `plot_network()` which plots a  PowerModels network case.

```julia
using PowerPlots
plot_network(network_case)
```

The function `plot_network!()` will plot the network on the active plot.

## Specialized Plotting Functions

There are additional plotting functions to format the network plots. These function are equivalent to calling `plot_network` with the approriate arguments, e.g.
```
plot_network(network; set_network_properties=set_properties_power_flow!)
```

### System Status
`plot_system_status()`
Sets the color of network devices based on the status code of device.

#### IEEE 14 bus network:
![plot_system_status](https://github.com/noahrhodes/PowerPlots.jl/blob/Documentation/example_plots/network_status.png)


### Power Flow
`plot_power_flow()`
Plot the power flow along branches in a network, coloring branches acorrding to the % load. Requires a solved power flow.
```
Using PowerModels, PowerPlots, Ipopt

case = PowerModels.parse_file("matpower/case5.m")
result = run_opf(case, DCPPowerModel, Ipopt.Optimizer)
PowerModels.update_data!(case, result["solution"])

plot_power_flow(case)
```

#### IEEE 5 bus network:
![plot_power_flow](https://github.com/noahrhodes/PowerPlots.jl/blob/Documentation/example_plots/power_flow.png)

### System Voltage Levels
`plot_system_voltage`
Plot the network with each voltage level in a unique color.

#### IEEE 118 bus network:
![plot_system_voltage](https://github.com/noahrhodes/PowerPlots.jl/blob/Documentation/example_plots/system_voltage.png)
