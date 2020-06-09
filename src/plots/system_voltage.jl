
const default_system_voltage_properties = Dict(
            "branch" => Dict(:color => colorant"black", :size => 3),
            "bus" => Dict(:color => colorant"black", :size => 10),
            "gen" => Dict(:color => colorant"green", :size => 10),
            "storage" => Dict(:color => colorant"blue", :size => 10),
            "dcline" => Dict(:color => colorant"gray3", :size => 3),
            "no_membership" => Dict(:color => colorant"gray", :size => 20),
            "connector" => Dict(:color => colorant"lightgrey", :size => 3, :style => :dash),
            "label" => Dict(:color => colorant"black", :size => 10, :fontfamily=>"Arial", :textalign=>:center, :offset => 0.1),
            "base_kv" => Dict(:palette => :Accent, :size=>[1,5]),
            )


function set_properties_system_voltage!(graph::PowerModelsGraph{T};
                               membership_properties::Dict{String,Any}=Dict{String,Any}(),
                                ) where T <: LightGraphs.AbstractGraph

    properties = deepcopy(default_system_voltage_properties)
    update_properties!(properties, membership_properties) ## write a properites update

    node_kv = Dict(node => get(get_data(graph, node),"base_kv",0.0) for node in vertices(graph))
    voltage_levels = sort!(unique([kv for (id,kv) in node_kv]))
    if length(voltage_levels) != 1
        color_set = Plots.palette(properties["base_kv"][:palette], length(voltage_levels))
    else
        color_set = Plots.palette(properties["base_kv"][:palette])
    end

    voltage_colors = Dict{Int,Colors.RGB{Float64}}()
    for i in 1:length(voltage_levels)
        voltage_colors[round(Int,voltage_levels[i])] = color_set[i]
    end


    for edge in edges(graph)  # set enabled/disabled lines
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

        if edge_type != "connector"  ## Set branch color
            component = get_data(graph, edge)
            src_kv = node_kv[LightGraphs.src(edge)]
            dst_kv = node_kv[LightGraphs.dst(edge)]
            base_kv = max(src_kv, dst_kv)

            color_kv = voltage_colors[round(Int,base_kv)]
            set_property!(graph, edge, :color, color_kv)
        end
    end



    for node in vertices(graph) # set enabled/disables buses and gens
        node_type = graph.metadata[node][:node_type]
        id = graph.metadata[node][:id]

        # component = get_data(graph, node)

        if node_type == "bus"
            set_property!(graph, node, :edge_membership, "bus")
        elseif node_type == "gen"
            set_property!(graph, node, :edge_membership, "gen")
        elseif node_type == "storage"
            set_property!(graph, node, :edge_membership, "storage")
        else
            set_property!(graph, node, :edge_membership, "no_membership")
        end

        for (property, value) in properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
        end

        color_kv = color_kv = voltage_colors[round(Int,node_kv[node])]
        set_property!(graph, node, :color, color_kv)
    end
end
