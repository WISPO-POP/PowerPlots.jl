# PowerPlots

![CI](https://github.com/WISPO-POP/PowerPlots.jl/workflows/CI/badge.svg) [![Codecov](https://codecov.io/gh/WISPO-POP/PowerPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/WISPO-POP/PowerPlots.jl) [![Documentation](https://github.com/WISPO-POP/PowerPlots.jl/workflows/Documentation/badge.svg)](https://wispo-pop.github.io/PowerPlots.jl/dev/)


Tools for the analysis and visualization of PowerModels data and results.

BETA / IN ACTIVE DEVELOPMENT: Features will change quickly and without warning

## Adding PowerPlots
`PowerPlots` is not a registered julia package, but it can still be added by calling

```julia
Pkg> add https://github.com/WISPO-POP/PowerPlots.jl.git
```

## Using PowerPlots

The basic plot function for `PowerPlots` is `plot_network()` which plots a  PowerModels network case.

```julia
using PowerPlots
plot_network(network_case)
```

The function `plot_network!()` will plot the network on the active plot.

## Specialized Plotting Functions

There are additional plotting functions to format the network plots. These function are equivalent to calling `plot_network` with the approriate arguments, e.g.
```julia
plot_network(network; set_network_properties=set_properties_power_flow!)
```

### System Status
`plot_system_status()`
Sets the color of network devices based on the status code of device.

#### IEEE 14 bus network:
![plot_system_status](https://github.com/WISPO-POP/PowerPlots.jl/blob/master/example_plots/network_status.png)


### Power Flow
`plot_power_flow()`
Plot the power flow along branches in a network, coloring branches acorrding to the % load. Requires a solved power flow.
```julia
Using PowerModels, PowerPlots, Ipopt

case = PowerModels.parse_file("matpower/case5.m")
result = run_opf(case, DCPPowerModel, Ipopt.Optimizer)
PowerModels.update_data!(case, result["solution"])

plot_power_flow(case)
```

#### IEEE 5 bus network:
![plot_power_flow](https://github.com/WISPO-POP/PowerPlots.jl/blob/master/example_plots/power_flow.png)

### System Voltage Levels
`plot_system_voltage`
Plot the network with each voltage level in a unique color.

#### IEEE 118 bus network:
![plot_system_voltage](https://github.com/WISPO-POP/PowerPlots.jl/blob/master/example_plots/system_voltage.png)


## Internals

The internal workflow for PowerPlots takes a network case, creates a `LightsGraphs` graph of the network, applies color, size, and other properties to nodes and edges, then generates a plot.

```julia
  plot_network()
  build_graph()
  apply_membership_properties()
  plot_graph()
end
```

Additonal custom plots can be create by creating a new membership function that assigns a properties to a node. For example:

```julia
const default_bus_odd_even_properties = Dict(
  "bus_odd" => Dict(:color => :blue, :size => 10),
  "bus_even" => Dict(:color => :grey, :size => 5),
  "no_membership" = Dict(:color =>green, :size =>5)
)

function set_properties_bus_odd_even!(graph::PowerModelsGraph{T};
                   membership_properties::Dict{String,Any}=Dict{String,Any}(),
                    ) where T <: LightGraphs.AbstractGraph

    properties = deepcopy(default_bus_odd_even_properties)
    update_properties!(properties, membership_properties)

    for node in vertices(graph) # set enabled/disables buses and gens
        node_type = graph.metadata[node][:node_type]

        if node_type == "bus"
          if node%2==0
            set_property!(graph, node, :edge_membership, "bus_even")
          else
            set_property!(graph, node, :edge_membership, "bus_odd")
          end
        end

        for (property, value) in properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
        end
    end
end
```

Would set make odd numbered buses blue and twice as large as as even numbered buses.

```julia
  plot_network(network; set_network_properties=set_properties_bus_odd_even!)
```

 Complex examples of plot types can be found in /src/plots.

 The properties that are applied to a plot can be altered by passing the kwarg `membership_properties`. Each plot type has a dictionary of membership types and available properties that can be changed.  For example the network status plot has 10 membership types:

 ```julia
 const default_status_properties = Dict(
   "active_line" => Dict(:color => :black, :size => 3),
   "inactive_line" => Dict(:color => :red, :size => 3),
   "active_bus" => Dict(:color => :green, :size => 10),
   "inactive_bus" => Dict(:color => :red, :size => 10),
   "active_gen" => Dict(:color => :blue, :size => 10),
   "inactive_gen" => Dict(:color => :red, :size => 10),
   "active_storage" => Dict(:color => :blue, :size => 10),
   "inactive_storage" => Dict(:color => :yellow, :size => 10),
   "no_membership" => Dict(:color => :gray, :size => 20),
   "connector" => Dict(:color => colorant"lightgrey", :size => 2, :style => :dash)
)
```

 A user can overide these defults by creating a dictionary of values to override the default.

 ```julia
 mp = Dict{String, Any}(
    "active_line" => Dict(:color => :green, :size => 3)
    "inactive_line" => Dict(:color => :purple, :size => 6)
 )

plot_network(case;
            set_network_properties=set_properties_network_status!,
            membership_properties = mp
            )

```
