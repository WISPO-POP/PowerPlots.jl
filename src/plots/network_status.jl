#
#
# function network_status_membership!(graph::PowerModelsGraph{T}, case) where T <: LightGraphs.AbstractGraph
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
#     apply_network_status_properties!(graph; kwargs...)
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
# function apply_network_status_properties!(graph::PowerModelsGraph{T};
#                                           membership_properties::Dict{String,Any}=Dict{String,Any}(),
#                                          ) where T <: LightGraphs.AbstractGraph
#
#     membership_properties = merge(default_properties, membership_properties)
#
#     for edge in edges(graph)
#         for (property, value) in membership_properties[get_property(graph, edge, :edge_membership, "no_membership")]
#             get_property(graph, edge, :edge_membership, "no_membership")
#             (edge, property, value)
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

const default_status_properties = Dict("active_line" => Dict(:color => :black, :size => 2),
                                "inactive_line" => Dict(:color => :red, :size => 2),
                                "active_bus" => Dict(:color => :green, :size => 5),
                                "inactive_bus" => Dict(:color => :red, :size => 5),
                                "active_gen" => Dict(:color => :green, :size => 2),
                                "inactive_gen" => Dict(:color => :red, :size => 2),
                                "active_storage" => Dict(:color => :blue, :size => 2),
                                "inactive_storage" => Dict(:color => :yellow, :size => 2),
                                "no_membership" => Dict(:color => :gray, :size => 10),
                                "connector" => Dict(:color => colorant"lightgrey", :size => 1, :style => :dash)
                                )


# set_properties_network_status!
function set_properties_network_status!(graph::PowerModelsGraph{T};
                   membership_properties::Dict{String,Any}=Dict{String,Any}(),
                    ) where T <: LightGraphs.AbstractGraph

    membership_properties = merge(default_status_properties, membership_properties)

    for edge in edges(graph)  # set enabled/disabled lines
        edge_type = graph.metadata[edge][:edge_type]
        id = graph.metadata[edge][:id]

        if edge_type == "connector"
            set_property!(graph, edge, :edge_membership, "connector")
        else
            component = get_data(graph, edge)
            status = component[PowerModels.pm_component_status[edge_type]]
            if status == PowerModels.pm_component_status_inactive[edge_type]
                set_property!(graph, edge, :edge_membership, "inactive_line")
            elseif status != PowerModels.pm_component_status_inactive[edge_type]
                set_property!(graph, edge, :edge_membership, "active_line")
            else
                set_property!(graph, edge, :edge_membership, "no_membership")
            end
        end

        for (property, value) in membership_properties[get_property(graph, edge, :edge_membership, "no_membership")]
            set_property!(graph, edge, property, value)
        end

    end

    for node in vertices(graph) # set enabled/disables buses and gens
        node_type = graph.metadata[node][:node_type]
        id = graph.metadata[node][:id]

        component = get_data(graph, node)
        status = component[PowerModels.pm_component_status[node_type]]

        if status == PowerModels.pm_component_status_inactive[node_type]
            if node_type == "bus"
                set_property!(graph, node, :edge_membership, "inactive_bus")
            elseif node_type == "gen"
                set_property!(graph, node, :edge_membership, "inactive_gen")
            elseif node_type == "storage"
                set_property!(graph, node, :edge_membership, "inactive_storage")
            else
                set_property!(graph, node, :edge_membership, "inactive_node")
            end
        elseif status != PowerModels.pm_component_status_inactive[node_type]
            if node_type == "bus"
                set_property!(graph, node, :edge_membership, "active_bus")
            elseif node_type == "gen"
                set_property!(graph, node, :edge_membership, "active_gen")
            elseif node_type == "storage"
                set_property!(graph, node, :edge_membership, "active_storage")
            else
                set_property!(graph, node, :edge_membership, "active_node")
            end
        else
            set_property!(graph, node, :edge_membership, "no_membership")
        end

        for (property, value) in membership_properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
        end
    end
end
