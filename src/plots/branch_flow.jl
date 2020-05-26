
const default_branch_flow_properties = Dict(
            "max_power" => Dict(:color => colorant"red", :size => 2),
            "min_power" => Dict(:color => colorant"black", :size => 2),
            "branch" => Dict(:color => colorant"green", :size => 2),
            "bus" => Dict(:color => colorant"green", :size => 5),
            "gen" => Dict(:color => colorant"green", :size => 2),
            "storage" => Dict(:color => colorant"blue", :size => 2),
            "no_membership" => Dict(:color => colorant"gray", :size => 10),
            "connector" => Dict(:color => colorant"lightgrey", :size => 1, :style => :dash)
            )


function set_properties_branch_flow!(graph::PowerModelsGraph{T},
                   case::Dict{String,Any};
                   membership_properties::Dict{String,Any}=Dict{String,Any}(),
                    ) where T <: LightGraphs.AbstractGraph

    membership_properties = merge(default_branch_flow_properties, membership_properties)

    # if haskey
    # min_power_flow = minimum(abs(branch["pt"]) for (id,branch) in case["branch"])
    # max_power_flow = maximum(abs(branch["pt"]) for (id,branch) in case["branch"])
    power_colors = Colors.range(membership_properties["min_power"][:color], membership_properties["max_power"][:color], length=100)

    for edge in edges(graph) # setedge properties
        edge_type = graph.metadata[edge][:edge_type]
        id = graph.metadata[edge][:id]

        if edge_type == "connector"
            set_property!(graph, edge, :edge_membership, "connector")
        else
            set_property!(graph, edge, :edge_membership,  "$(edge_type)")
        end

        for (property, value) in membership_properties[get_property(graph, edge, :edge_membership, "no_membership")]
            set_property!(graph, edge, property, value)
        end

        if edge_type != "connector" #  set branch color based on power flow, not edge_membership
            component = case[edge_type]["$(id)"]
            value = max(1,round(Int,abs(component["pt"]/component["rate_a"]))*100)
            # value = round(Int,(abs(component["pt"])-min_power_flow)*(100-1)/(max_power_flow-min_power_flow) + 1)
            set_property!(graph, edge, :color, power_colors[value])

            label = "$(round(component["pt"]*case["baseMVA"], sigdigits=3)) MW"
            set_property!(graph, edge, :label, label)
        end
    end

    for node in vertices(graph) # set node properties
        node_type = graph.metadata[node][:node_type]
        id = graph.metadata[node][:id]

        component = case[node_type]["$(id)"]

        if node_type == "bus"
            set_property!(graph, node, :edge_membership, "bus")
        elseif node_type == "gen"
            set_property!(graph, node, :edge_membership, "gen")
        elseif node_type == "storage"
            set_property!(graph, node, :edge_membership, "storage")
        else
            set_property!(graph, node, :edge_membership, "inactive_node")
        end

        for (property, value) in membership_properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
        end
    end
end
