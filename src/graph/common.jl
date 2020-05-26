"""
    build_graph_network(case; kwargs...)

Builds a PowerModelsGraph of a PowerModels/PowerModelsDistribution network `case`.

# Parameters

* `case::Dict{String,Any}`

    Network case data structure

* `edge_types::Array`

    Default: `["branch", "dcline", "transformer"]`. List of component types that are graph edges.

* `source_types::Dict{String,Dict{String,String}}`

    Default:
    ```
    Dict("gen"=>Dict("active"=>"pg", "reactive"=>"qg", "status"=>"gen_status", "active_max"=>"pmax", "active_min"=>"pmin"),
        "storage"=>Dict("active"=>"ps", "reactive"=>"qs", "status"=>"status"))
    ```

    Dictionary containing information about different generator types, including basic `gen` and `storage`.

* `exclude_sources::Union{Nothing,Array}`

    Default: `nothing`. A list of patterns of generator names to not include in the graph.

* `aggregate_sources::Bool`

    Default: `false`. If `true`, generators will be aggregated by type for each bus.

* `switch::String`

    Default: `"breaker"`. The keyword that indicates branches are switches.

# Returns

* `graph::PowerModelsGraph{LightGraphs.SimpleDiGraph}`

    Simple Directional Graph including metadata
"""
function build_graph_network(case::Dict{String,Any};
                             edge_types=["branch", "dcline", "transformer"],
                             source_types=["gen", "storage"],
                             exclude_sources::Union{Nothing,Array}=nothing,
                             aggregate_sources::Bool=false)::PowerModelsGraph

    connected_buses = Set(edge[k] for k in ["f_bus", "t_bus"] for edge_type in edge_types for edge in values(get(case, edge_type, Dict())))

    sources = [(source_type, source) for source_type in source_types for source in values(get(case, source_type, Dict()))]
    n_buses = length(connected_buses)
    n_sources = length(sources)

    graph = PowerModelsGraph(n_buses + n_sources)
    bus_graph_map = Dict(bus["bus_i"] => i for (i, bus) in enumerate(values(get(case, "bus", Dict()))))
    source_graph_map = Dict("$(source_type)_$(gen["index"])" => i for (i, (source_type, gen)) in zip(n_buses+1:n_buses+n_sources, sources))

    graph_bus_map = Dict(v => k for (k, v) in bus_graph_map)
    graph_source_map = Dict(v => k for (k, v) in source_graph_map)
    graph_map = merge(graph_bus_map, graph_source_map)

    for edge_type in edge_types
        for edge in values(get(case, edge_type, Dict()))
            add_edge!(graph, bus_graph_map[edge["f_bus"]], bus_graph_map[edge["t_bus"]])

            props = Dict{Symbol,Any}(:id => edge["index"],
                                     :label => string(edge_type,"_",edge["index"]),
                                     :edge_type => edge_type,
                                     )
            set_properties!(graph, LightGraphs.Edge(bus_graph_map[edge["f_bus"]], bus_graph_map[edge["t_bus"]]), props)
        end
    end

    # Add Generator Nodes
    for source_type in source_types
        for source in values(get(case, source_type, Dict()))
            add_edge!(graph, source_graph_map["$(source_type)_$(source["index"])"], bus_graph_map[source["$(source_type)_bus"]])

            node_props = Dict(:id => source["index"],
                              :node_type => source_type,
                              :parent_node =>bus_graph_map[source[string(source_type,"_bus")]],
                              :label => string(source_type,"_",source["index"]),
                              )
            set_properties!(graph, source_graph_map["$(source_type)_$(source["index"])"], node_props)

            edge_props = Dict(:id => source["index"],
                              :edge_type => "connector",
                              )
            set_properties!(graph, LightGraphs.Edge(source_graph_map["$(source_type)_$(source["index"])"], bus_graph_map[source["$(source_type)_bus"]]), edge_props)
        end
    end

    # Set color of buses based on mean served load
    for bus in values(get(case, "bus", Dict()))
        if haskey(bus, "buscoord")
            set_property!(graph, bus_graph_map[bus["bus_i"]], :buscoord, bus["buscoord"])
        end

        node_props = Dict(:id => bus["index"],
                          :node_type => "bus",
                          :label => string("bus_", bus["index"]),
                          )
        set_properties!(graph, bus_graph_map[bus["bus_i"]], node_props)
    end

    return graph
end


# function apply_membership!(graph::PowerModelsGraph{T}, case) where T <: LightGraphs.AbstractGraph
#
#     for edge in edges(graph)  # set enabled/disabled lines
#         edge_type = graph.metadata[edge][:edge_type]
#         id = graph.metadata[edge][:id]
#
#         if edge_type == "connector"
#             set_property!(graph, edge, :edge_membership, "connector")
#         else
#             component = case[edge_type]["$(id)"]
#             status = component[PowerModels.pm_component_status[edge_type]]
#             if status == PowerModels.pm_component_status_inactive[edge_type]
#                 set_property!(graph, edge, :edge_membership, "inactive_line")
#             elseif status != PowerModels.pm_component_status_inactive[edge_type]
#                 set_property!(graph, edge, :edge_membership, "active_line")
#             else
#                 set_property!(graph, edge, :edge_membership, "no_membership")
#             end
#         end
#     end
#
#     for node in vertices(graph) # set enabled/disables buses and gens
#         node_type = graph.metadata[node][:node_type]
#         id = graph.metadata[node][:id]
#
#         component = case[node_type]["$(id)"]
#         status = component[PowerModels.pm_component_status[node_type]]
#
#         if status == PowerModels.pm_component_status_inactive[node_type]
#             if node_type == "bus"
#                 set_property!(graph, node, :edge_membership, "inactive_bus")
#             elseif node_type == "gen"
#                 set_property!(graph, node, :edge_membership, "inactive_gen")
#             elseif node_type == "storage"
#                 set_property!(graph, node, :edge_membership, "inactive_storage")
#             else
#                 set_property!(graph, node, :edge_membership, "inactive_node")
#             end
#         elseif status != PowerModels.pm_component_status_inactive[node_type]
#             if node_type == "bus"
#                 set_property!(graph, node, :edge_membership, "active_bus")
#             elseif node_type == "gen"
#                 set_property!(graph, node, :edge_membership, "active_gen")
#             elseif node_type == "storage"
#                 set_property!(graph, node, :edge_membership, "active_storage")
#             else
#                 set_property!(graph, node, :edge_membership, "active_node")
#             end
#         else
#             set_property!(graph, node, :edge_membership, "no_membership")
#         end
#     end
#
# end
#
#
#
#
# """
#     apply_plot_network_metadata!(graph; kwargs...)
#
# Builds metadata properties, i.e. color/size of nodes/edges, for plotting based on graph metadata
# # Parameters
#
# * `graph::PowerModelsGraph`
#
#     Graph of power network
#
# * `membership_properties::Dict{String,Symbol}`
#
#     Default: `Dict()`. Dictionary of properties to be changed from `default_properties`.
#
# """
# function apply_plot_network_metadata!(graph::PowerModelsGraph{T};
#                                       membership_properties::Dict{String,<:Colors.AbstractRGB}=Dict{String,Colors.AbstractRGB}(),
#                                       ) where T <: LightGraphs.AbstractGraph
#     membership_properties = merge(default_properties, membership_properties)
#
#     for edge in edges(graph)
#         for (property, value) in membership_properties[get_property(graph, edge, :edge_membership, "no_membership")]
#             set_property!(graph, edge, property, value)
#         end
#     end
#
#     for node in vertices(graph)
#         for (property, value) in membership_properties[get_property(graph, node, :edge_membership, "no_membership")]
#             set_property!(graph, node, property, value)
#         end
#     end
#
# end
