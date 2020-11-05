
## Experimental Feature!

using VegaLite, VegaDatasets, DataFrames

# import PyCall
# const nx = PyCall.PyNULL()
# const scipy = PyCall.PyNULL()

# function __init__()
#     copy!(nx, PyCall.pyimport_conda("networkx", "networkx"))
#     copy!(scipy, PyCall.pyimport_conda("scipy", "scipy"))
# end

## convert to DataFrames
const node_types = ["bus","gen","storage"]
const edge_types = ["switch","branch","dcline","transformer"]


function layout_graph_vega!(case::Dict{String,Any};
    node_types::Array{String,1} = ["bus","gen","storage"],
    edge_types::Array{String,1} = ["switch","branch","dcline","transformer"]
    )
    data = deepcopy(case)
    node_comp_map = Dict()
    for node_type in node_types
            temp_node = get(data, node_type, Dict())
            temp_map = Dict(string(comp["source_id"][1],"_",comp["source_id"][2]) => comp  for (comp_id, comp) in temp_node)
            merge!(node_comp_map,temp_map)
    end

    edge_comp_map = Dict()
    for edge_type in edge_types
            temp_edge = get(data, edge_type, Dict())
            for (id,edge) in temp_edge
                edge["src"] = "bus_$(edge["f_bus"])"
                edge["dst"] = "bus_$(edge["t_bus"])"
            end
            temp_map = Dict(string(comp["source_id"][1],"_",comp["source_id"][2]) => comp for (comp_id, comp) in temp_edge)
            merge!(edge_comp_map,temp_map)
    end
    for node_type in node_types
        if node_type != "bus"
            connector_edge = get(data, node_type, Dict())
            for (id,edge) in connector_edge
                edge["src"] = string(edge["source_id"][1],"_",edge["source_id"][2])
                edge["dst"] = string("bus_",data["bus"][string(edge["$(node_type)_bus"])]["index"])
            end
            connector_map = Dict(string(comp["source_id"][1],"_",comp["source_id"][2],"_connector") => comp  for (comp_id, comp) in connector_edge)
            merge!(edge_comp_map,connector_map)
        end
    end

    G = nx.Graph()
    for (id,node) in node_comp_map
        G.add_node(id)
    end
    for (id,edge) in edge_comp_map
        G.add_edge(edge["src"], edge["dst"], weight=1.0)
    end


    positions = nx.kamada_kawai_layout(G, dist=nothing, pos=nothing, weight="weight", scale=1.0, center=nothing, dim=2)

    # Set Node Positions
    for (node, (x, y)) in positions
        (comp_type,comp_id) = split(node, "_")
        case[comp_type][comp_id]["x"] = x
        case[comp_type][comp_id]["y"] = y
    end
    # Set Edge positions
    for (edge, val) in (edge_comp_map)
        (x,y) = positions[val["src"]]
        (x2,y2) = positions[val["dst"]]
        (comp_type,comp_id) = split(edge, "_")
        case[comp_type][comp_id]["x"] = x
        case[comp_type][comp_id]["y"] = y
        case[comp_type][comp_id]["x2"] = x2
        case[comp_type][comp_id]["y2"] = y2
    end
end


"create a dataframe based on powermodels dictionary"
function form_df(data::Dict{String,<:Any};)

    if InfrastructureModels.ismultinetwork(data)
        Memento.error(_LOGGER, "form_df does not yet support multinetwork data")
    end

    df_return = Dict{String,DataFrame}()
    component_types = []
    other_types = []

    #Network meta_data
    df_return["metadata"] = DataFrame()
    for (k,v) in sort(collect(data); by=x->x[1])
        if typeof(v) <: Dict && InfrastructureModels._iscomponentdict(v)
            push!(component_types, k)
            continue
        end
        df_return["metadata"][k] = v
    end

    # for comp_type in sort(component_types, by=x->get(component_types_order, x, max_parameter_value))
    for comp_type in component_types

        if length(data[comp_type]) <= 0 ## Should there be an empty dataframe, or a nonexistent dataframe?
            continue
        end

        components = data[comp_type]

        columns = [Symbol(k) => (typeof(v) <: Array || typeof(v) <: Dict) ? String[] : typeof(v)[] for (k,v) in first(components)[2]]
        df_return[comp_type] = DataFrame(columns...)
        for (i, component) in components
            for (k,v) in component
                if typeof(v) <: Array || typeof(v) <: Dict
                    component[k] = string(v)
                end
            end
            push!(df_return[comp_type], component)
        end
    end

    return df_return
end



## For testing
# __init__()


function plot_vega(case)
    layout_graph_vega!(case)
    df = form_df(case)
    @vlplot(
        width=500,
        height=500,
        config={view={stroke=nothing}},
        x={axis=nothing},
        y={axis=nothing},
    ) +
    @vlplot(
        mark ={:rule, "tooltip" =("content" => "data")},
        data=df["branch"],
        x = :x,
        x2 = :x2,
        y = :y,
        y2 = :y2,
        size={value=5},
    ) +
    @vlplot(
        data = df["bus"],
        mark ={:circle, "tooltip" =("content" => "data")},
        x={:x,},
        y={:y,},
        size={value=1e3},
        color={:area}
    )
end

