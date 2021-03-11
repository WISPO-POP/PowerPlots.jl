
const default_status_properties = Dict("active_line" => Dict(:color => :black, :size => 3),
                                "inactive_line" => Dict(:color => :red, :size => 3),
                                "active_bus" => Dict(:color => :green, :size => 10),
                                "active_bus_load_shed" => Dict(:color => :orange, :size => 10),
                                "inactive_bus" => Dict(:color => :red, :size => 10),
                                "active_gen" => Dict(:color => :blue, :size => 10),
                                "inactive_gen" => Dict(:color => :red, :size => 10),
                                "active_storage" => Dict(:color => :blue, :size => 10),
                                "inactive_storage" => Dict(:color => :yellow, :size => 10),
                                "no_membership" => Dict(:color => :gray, :size => 20),
                                "connector" => Dict(:color => colorant"lightgrey", :size => 2, :style => :dash)
                                )


# set_properties_network_status!
function set_properties_network_status!(graph::PowerModelsGraph{T};
                   membership_properties::Dict{String,Any}=Dict{String,Any}(),
                    ) where T <: LightGraphs.AbstractGraph

    properties = deepcopy(default_status_properties)
    update_properties!(properties, membership_properties) ## write a properites update

    for edge in edges(graph)  # set enabled/disabled lines
        edge_type = graph.metadata[edge][:edge_type]
        id = graph.metadata[edge][:id]

        if edge_type == "connector"
            set_property!(graph, edge, :edge_membership, "connector")
        else
            component = get_data(graph, edge)
            status = component[_PM.pm_component_status[edge_type]]
            if status == _PM.pm_component_status_inactive[edge_type]
                set_property!(graph, edge, :edge_membership, "inactive_line")
            elseif status != _PM.pm_component_status_inactive[edge_type]
                set_property!(graph, edge, :edge_membership, "active_line")
            else
                set_property!(graph, edge, :edge_membership, "no_membership")
            end
        end

        for (property, value) in properties[get_property(graph, edge, :edge_membership, "no_membership")]
            set_property!(graph, edge, property, value)
        end

    end

    for node in vertices(graph) # set enabled/disables buses and gens
        node_type = graph.metadata[node][:node_type]
        id = graph.metadata[node][:id]

        component = get_data(graph, node)
        status = component[_PM.pm_component_status[node_type]]

        if status == _PM.pm_component_status_inactive[node_type]
            if node_type == "bus"
                set_property!(graph, node, :edge_membership, "inactive_bus")
            elseif node_type == "gen"
                set_property!(graph, node, :edge_membership, "inactive_gen")
            elseif node_type == "storage"
                set_property!(graph, node, :edge_membership, "inactive_storage")
            else
                set_property!(graph, node, :edge_membership, "inactive_node")
            end
        elseif status != _PM.pm_component_status_inactive[node_type]
            if node_type == "bus"
                set_property!(graph, node, :edge_membership, "active_bus")

                # check if load shed. if yes, change membership
                if hasprop(graph, node, :load)
                    loads = get_property(graph, node, :load, Dict())
                    load_shed=false
                    for (id,load) in loads
                        if load["status"] != 1.0
                            @show load["status"]
                            load_shed = true
                        end
                    end
                    if load_shed == true
                        set_property!(graph, node, :edge_membership, "active_bus_load_shed")
                    end
                end
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

        for (property, value) in properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
        end
    end
end