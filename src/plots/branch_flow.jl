
const default_branch_flow_properties = Dict(
            "max_power" => Dict(:color => colorant"red", :size => 2),
            "min_power" => Dict(:color => colorant"black", :size => 2),
            "branch" => Dict(:color => colorant"green", :size => 2),
            "bus" => Dict(:color => colorant"green", :size => 5),
            "gen" => Dict(:color => colorant"green", :size => 2),
            "storage" => Dict(:color => colorant"blue", :size => 2),
            "dcline" => Dict(:color => colorant"black", :size => 2),
            "no_membership" => Dict(:color => colorant"gray", :size => 10),
            "connector" => Dict(:color => colorant"lightgrey", :size => 1, :style => :dash),
            "label" => Dict(:color => colorant"black", :size => 12, :fontfamily=>"Arial", :textalign=>:center)
            )


function set_properties_branch_flow!(graph::PowerModelsGraph{T};
                   membership_properties::Dict{String,Any}=Dict{String,Any}(),
                    ) where T <: LightGraphs.AbstractGraph

    membership_properties = merge(default_branch_flow_properties, membership_properties)

    nodes = Dict(node => [get_property(graph, node, :x, 0.0), get_property(graph, node, :y, 0.0)] for node in vertices(graph))
    node_keys = sort(collect(keys(nodes)))
    node_x = [nodes[node][1] for node in node_keys]
    node_y = [nodes[node][2] for node in node_keys]

    power_colors = Colors.range(membership_properties["min_power"][:color], membership_properties["max_power"][:color], length=100)

    graph.annotationdata["label"] = Dict()
    graph.annotationdata["powerflow"] = Dict()

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

        if edge_type != "connector"
            component = get_data(graph, edge)

            if edge_type == "branch" #  set branch color based on power flow, not edge_membership
                percent_rated_power = max(1,round(Int,abs(component["pt"]/component["rate_a"]))*100)
            elseif edge_type == "dcline"
                percent_rated_power = max(1,round(Int,abs(component["pt"]/component["pmaxt"]))*100)
            end
            edge_color = power_colors[percent_rated_power]
            set_property!(graph, edge, :color, edge_color)

            label = "$(round(component["pt"], sigdigits=3)) MW"  # TODO need to mult by "baseMVA"
            # set_property!(graph, edge, :label, label)


            edge_x, edge_y = [], []
            for n in [LightGraphs.src(edge), LightGraphs.dst(edge)]
                push!(edge_x, nodes[n][1])
                push!(edge_y, nodes[n][2])
            end
            fontsize=membership_properties["label"][:size]
            fontfamily=membership_properties["label"][:fontfamily]
            fontcolor=membership_properties["label"][:color]
            textalign=membership_properties["label"][:textalign]

            graph.annotationdata["label"][edge] = Dict{Symbol,Any}(:x=>mean(edge_x),:y=>mean(edge_y),
                        :text => Plots.text(label, fontsize, fontcolor, textalign, fontfamily))


            rotation = 10.0
            graph.annotationdata["powerflow"][edge] = Dict{Symbol,Any}(:x=>mean(edge_x), :y=>mean(edge_y),
                        :text=>Plots.text(">>>", fontsize, edge_color, :center, fontfamily, rotation))
        end
    end

    for node in vertices(graph) # set node properties
        node_type = graph.metadata[node][:node_type]
        id = graph.metadata[node][:id]

        component = get_data(graph, node)

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
