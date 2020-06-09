
const default_branch_flow_properties = Dict(
            "max_power" => Dict(:color => colorant"red", :size => 2),
            "min_power" => Dict(:color => colorant"black", :size => 2),
            "branch" => Dict(:color => colorant"green", :size => 3),
            "bus" => Dict(:color => colorant"green", :size => 10),
            "gen" => Dict(:color => colorant"green", :size => 10),
            "storage" => Dict(:color => colorant"blue", :size => 10),
            "dcline" => Dict(:color => colorant"black", :size => 3),
            "no_membership" => Dict(:color => colorant"gray", :size => 20),
            "connector" => Dict(:color => colorant"lightgrey", :size => 3, :style => :dash),
            "label" => Dict(:color => colorant"black", :size => 10, :fontfamily=>"Arial", :textalign=>:center, :offset => 0.1)
            )


function set_properties_branch_flow!(graph::PowerModelsGraph{T};
                   membership_properties::Dict{String,Any}=Dict{String,Any}(),
                    ) where T <: LightGraphs.AbstractGraph

    properties = deepcopy(default_branch_flow_properties)
    update_properties!(properties, membership_properties) ## write a properites update

    nodes = Dict(node => [get_property(graph, node, :x, 0.0), get_property(graph, node, :y, 0.0)] for node in vertices(graph))
    node_keys = sort(collect(keys(nodes)))
    node_x = [nodes[node][1] for node in node_keys]
    node_y = [nodes[node][2] for node in node_keys]

    power_colors = Colors.range(properties["min_power"][:color], properties["max_power"][:color], length=100)

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

        for (property, value) in properties[get_property(graph, edge, :edge_membership, "no_membership")]
            set_property!(graph, edge, property, value)
        end

        if edge_type != "connector"  ## Create power flow labels

            fontsize=properties["label"][:size]
            fontfamily=properties["label"][:fontfamily]
            fontcolor=properties["label"][:color]
            textalign=properties["label"][:textalign]
            offset=properties["label"][:offset]

            component = get_data(graph, edge)

            if edge_type == "branch" #  set branch color based on power flow, not edge_membership
                percent_rated_power = max(1,round(Int,abs(component["pt"]/component["rate_a"]))*100)
            elseif edge_type == "dcline"
                percent_rated_power = max(1,round(Int,abs(component["pt"]/component["pmaxt"]))*100)
            end
            edge_color = power_colors[percent_rated_power]
            set_property!(graph, edge, :color, edge_color)

            label = "$(round(abs(component["pt"]), sigdigits=3)) MW"  # TODO need to mult by "baseMVA"

            edge_x, edge_y = [], []
            for n in [LightGraphs.src(edge), LightGraphs.dst(edge)]
                push!(edge_x, nodes[n][1])
                push!(edge_y, nodes[n][2])
            end

            rotation = rad2deg(atan(edge_y[1]-edge_y[2],edge_x[1]-edge_x[2]))
            if get(get_data(graph,edge), "pt", 0.0) < 0.0
                rotation += 180
            end

            if rotation > 90
                label_rotation = rotation - 180
            elseif rotation < -90
                label_rotation = rotation + 180
            else
                label_rotation = rotation
            end

            x = mean(edge_x) + offset*cosd(label_rotation+90)
            y = mean(edge_y) + offset*sind(label_rotation+90)

            graph.annotationdata["label"][edge] = Dict{Symbol,Any}(:x=>x,:y=>y,
                        :text => Plots.text(label, fontsize, fontcolor, textalign, fontfamily, label_rotation))
            graph.annotationdata["powerflow"][edge] = Dict{Symbol,Any}(:x=>mean(edge_x), :y=>mean(edge_y),
                        :text=>Plots.text(">>>", round(Int, 1.5*fontsize), edge_color, :center, fontfamily, rotation))
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

        for (property, value) in properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
        end
    end
end
