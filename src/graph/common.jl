# """
#     build_graph_network(case; kwargs...)

# Builds a PowerModelsGraph of a PowerModels/PowerModelsDistribution network `case`.

# # Parameters

# * `case::Dict{String,Any}`

#     Network case data structure

# * `edge_types::Array`

#     Default: `["branch", "dcline", "transformer"]`. List of component types that are graph edges.

# * `source_types::Dict{String,Dict{String,String}}`

#     Default:
#     ```
#     Dict("gen"=>Dict("active"=>"pg", "reactive"=>"qg", "status"=>"gen_status", "active_max"=>"pmax", "active_min"=>"pmin"),
#         "storage"=>Dict("active"=>"ps", "reactive"=>"qs", "status"=>"status"))
#     ```

#     Dictionary containing information about different generator types, including basic `gen` and `storage`.

# * `exclude_sources::Union{Nothing,Array}`

#     Default: `nothing`. A list of patterns of generator names to not include in the graph.

# * `aggregate_sources::Bool`

#     Default: `false`. If `true`, generators will be aggregated by type for each bus.

# * `switch::String`

#     Default: `"breaker"`. The keyword that indicates branches are switches.

# # Returns

# * `graph::PowerModelsGraph{LightGraphs.SimpleDiGraph}`

#     Simple Directional Graph including metadata
# """
# function build_graph_network(case::Dict{String,Any};
#                              edge_types=["branch", "dcline", "transformer"],
#                              source_types=["gen", "storage"],
#                              exclude_sources::Bool=false,
#                              aggregate_sources::Bool=false)::PowerModelsGraph

#      if exclude_sources == true
#          source_types=String[]
#      end

#     connected_buses = Set(edge[k] for k in ["f_bus", "t_bus"] for edge_type in edge_types for edge in values(get(case, edge_type, Dict())))

#     sources = [(source_type, source) for source_type in source_types for source in values(get(case, source_type, Dict()))]
#     n_buses = length(connected_buses)
#     n_sources = length(sources)

#     graph = PowerModelsGraph(n_buses + n_sources)
#     bus_graph_map = Dict(bus["bus_i"] => i for (i, bus) in enumerate(values(get(case, "bus", Dict()))))
#     source_graph_map = Dict("$(source_type)_$(gen["index"])" => i for (i, (source_type, gen)) in zip(n_buses+1:n_buses+n_sources, sources))

#     graph_bus_map = Dict(v => k for (k, v) in bus_graph_map)
#     graph_source_map = Dict(v => k for (k, v) in source_graph_map)
#     graph_map = merge(graph_bus_map, graph_source_map)

#     for edge_type in edge_types
#         for edge in values(get(case, edge_type, Dict()))
#             add_edge!(graph, bus_graph_map[edge["f_bus"]], bus_graph_map[edge["t_bus"]])

#             props = Dict{Symbol,Any}(:id => edge["index"],
#                                      :label => string(edge_type,"_",edge["index"]),
#                                      :edge_type => edge_type,
#                                      :data => edge
#                                      )
#             set_properties!(graph, LightGraphs.Edge(bus_graph_map[edge["f_bus"]], bus_graph_map[edge["t_bus"]]), props)
#         end
#     end

#     # Add Generator Nodes
#     for source_type in source_types
#         for source in values(get(case, source_type, Dict()))
#             add_edge!(graph, source_graph_map["$(source_type)_$(source["index"])"], bus_graph_map[source["$(source_type)_bus"]])

#             node_props = Dict(:id => source["index"],
#                               :node_type => source_type,
#                               :parent_node =>bus_graph_map[source[string(source_type,"_bus")]],
#                               :label => string(source_type,"_",source["index"]),
#                               :data => source
#                               )
#             set_properties!(graph, source_graph_map["$(source_type)_$(source["index"])"], node_props)

#             edge_props = Dict(:id => source["index"],
#                               :edge_type => "connector",
#                               )
#             set_properties!(graph, LightGraphs.Edge(source_graph_map["$(source_type)_$(source["index"])"], bus_graph_map[source["$(source_type)_bus"]]), edge_props)
#         end
#     end

#     # Add bus data
#     for bus in values(get(case, "bus", Dict()))
#         if haskey(bus, "buscoord")
#             set_property!(graph, bus_graph_map[bus["bus_i"]], :buscoord, bus["buscoord"])
#         end

#         node_props = Dict(:id => bus["index"],
#                           :node_type => "bus",
#                           :label => string("bus_", bus["index"]),
#                           :data => bus
#                           )
#         set_properties!(graph, bus_graph_map[bus["bus_i"]], node_props)
#     end

#     # add load data to buses
#     bus_load_map = Dict()
#     for (id, load) in get(case, "load", Dict())
#         load_bus = load["load_bus"]
#         if haskey(bus_load_map, load_bus)
#             push!(bus_load_map[load_bus], id)
#         else
#             bus_load_map[load_bus] = [id]
#         end
#     end

#     for (bus,loads) in bus_load_map
#         load_data = Dict()
#         for id in loads
#             load_data[id]=case["load"][id]
#         end
#         set_properties!(graph, bus_graph_map[bus], Dict(:load=>load_data))
#     end

#     return graph
# end
