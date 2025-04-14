# PowerModelsGraph
The PowerModels data dictionary is useful for storing and accessing data about a grid, but a graph structure can be useful to analyse metrics like node degree or eigenvector centrality.  It is used in this pacakge to create [Layouts](@ref) for plotting networks.

```julia
mutable struct PowerModelsGraph
    graph::Graphs.SimpleDiGraph
    node_comp_map::Dict{Int,Tuple{String, String}}
    edge_comp_map::Dict{Tuple{Int,Int},Tuple{String, String}}
    edge_connector_map::Dict{Tuple{Int,Int},Tuple{String, String}}
```

The `PowerModelsGraph` type stores a directed graph of the network, and mapping between the nodes and edges and the components that they refer to.

The `node_comp_map` is a Dictionary where the keys are the graph nodes and the values are a tuple of the component type and id, e.g.
```julia
node_comp_map = Dict(
    1 => ("bus","2"),
    2 => ("gen","4")
)
```

The `edge_comp_map` is a similar mapping for components that form the edges of the network.  Here, the keys are the endpoints of the directed edge.
```julia
edge_comp_map = Dict(
    (1,2) => ("branch","1"),
    (2,3) => ("dcline","4")
)
```

Connectors are additional lines that connect non-bus nodes to a bus, for example generators.  The mapping is similar to the `edge_comp_map`.
 ```julia
edge_connector_map = Dict(
    (1,4) => ("gen","1"),
    (1,5) => ("gen","2")
)
```

To create a `PowerModelsGraph`, the component types for the central nodes, edges, and the connected components must be specified.
```julia
PowerModelsGraph(data::Dict{String,<:Any},
                node_types::Vector{String},
                edge_types::Vector{String},
                connected_types::Vector{String},
)
```

There is also a convenient function with default node and edge types as keyword arguments that include all the default supported components.
```julia
PowerModelsGraph(data::Dict{String,<:Any},
                node_components=supported_node_types,
                edge_components=supported_edge_types,
                connected_components=supported_connected_types
)
```

## PowerModelsGraph Example

```@example
using PowerModels
using PowerPlots
case = parse_file("case14.m")

# Specify node and edge types
case_PMG = PowerModelsGraph(case, node_components=[:bus], edge_components=["branch","dcline"], connected_components=["gen"])

# Use default node and edge types
case_PMG = PowerModelsGraph(case)
```
## Using PowerModelsGraph
```@example PMG
using PowerModels
using PowerPlots
using Graphs
case = parse_file("case14.m")

# Create a graph where buses are nodes and branches are edges
case_PMG = PowerModelsGraph(case, node_components=["bus"], edge_components=["branch"],);
```

```@example PMG
g = Graphs.SimpleGraph(case_PMG.graph) # Does the graph contain cycles?
is_cyclic(g)
```

```@example PMG
# Get the adjacency matrix
adjacency_matrix(case_PMG.graph)
```