
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


function layout_graph_vega(case::Dict{String,Any}, spring_const;
    node_types::Array{String,1} = ["bus","gen","storage"],
    edge_types::Array{String,1} = ["switch","branch","dcline","transformer"],
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
    # connectors
    connector_map = Dict()
    for node_type in node_types
        if node_type!="bus"
            nodes = get(data, node_type, Dict())
            for (id,node) in nodes
                temp_connector = Dict()
                temp_connector["src"] = "$(node_type)_$(id)"
                temp_connector["dst"] = "bus_$(node["$(node_type)_bus"])"

                temp_map = Dict(string("connector_",(length(connector_map)+1)) => temp_connector)
                merge!(connector_map,temp_map)
            end
        end
    end


    # find fixed positions of nodes
    pos = Dict()
    for (id,node) in node_comp_map
        if haskey(node, "xcoord_1") && haskey(node, "ycoord_1")
            pos[id] = [node["xcoord_1"], node["ycoord_1"]]
        else
            pos[id] = missing
        end
    end
    fixed = [node for (node, p) in pos if !ismissing(p)]

    G = nx.Graph()
    for (id,node) in node_comp_map
        G.add_node(id)
    end
    for (id,edge) in edge_comp_map
        G.add_edge(edge["src"], edge["dst"], weight=1.0)
    end
    for (id,edge) in connector_map
        G.add_edge(edge["src"], edge["dst"], weight=1.0)
    end

    if isempty(fixed)
        positions = nx.kamada_kawai_layout(G, dist=nothing, pos=nothing, weight="weight", scale=1.0, center=nothing, dim=2)
    else
        avg_x, avg_y = mean(hcat(skipmissing([v for v in values(pos)])...), dims=2)
        std_x, std_y = std(hcat(skipmissing([v for v in values(pos)])...), dims=2)
        for (v, p) in pos
            if ismissing(p)
                #get parent bus coord, or center of figure
                comp_type, comp_id = split(v, "_")
                x1 = get(get(data["bus"],string(get(case[comp_type][comp_id],"$(comp_type)_bus", NaN)),Dict()),"xcoord_1", avg_x)
                y1 = get(get(data["bus"],string(get(case[comp_type][comp_id],"$(comp_type)_bus", NaN)),Dict()),"ycoord_1", avg_x)
                pos[v] = [x1,y1] + [std_x*(rand()-0.5), std_y*(rand()-0.5)]*300
            end
        end
        # spring_const = 1e-2
        k=spring_const*minimum(std([p for p in values(pos)]))
        positions = nx.spring_layout(G; pos,  fixed, k,  iterations=100)
        # positions = pos
    end

    # Set Node Positions
    for (node, (x, y)) in positions
        (comp_type,comp_id) = split(node, "_")
        data[comp_type][comp_id]["xcoord_1"] = x
        data[comp_type][comp_id]["ycoord_1"] = y
    end
    # Set Edge positions
    for (edge, val) in (edge_comp_map)
        (x,y) = positions[val["src"]]
        (x2,y2) = positions[val["dst"]]
        (comp_type,comp_id) = split(edge, "_")
        data[comp_type][comp_id]["xcoord_1"] = x
        data[comp_type][comp_id]["ycoord_1"] = y
        data[comp_type][comp_id]["xcoord_2"] = x2
        data[comp_type][comp_id]["ycoord_2"] = y2
    end

    # Create connector dictionary
    data["connector"] = Dict()
    for (edge, con) in connector_map
        _,id = split(edge, "_")
        data["connector"][id]=  Dict(
            "src" => con["src"],
            "dst" => con["dst"],
            "xcoord_1" => 0.0,
            "ycoord_1" => 0.0,
            "xcoord_2" => 0.0,
            "ycoord_2" => 0.0,
        )
    end
    # Set Connector positions
    for (edge, val) in (connector_map)
        (x,y) = positions[val["src"]]
        (x2,y2) = positions[val["dst"]]
        (comp_type,comp_id) = split(edge, "_")
        data[comp_type][comp_id]["xcoord_1"] = x
        data[comp_type][comp_id]["ycoord_1"] = y
        data[comp_type][comp_id]["xcoord_2"] = x2
        data[comp_type][comp_id]["ycoord_2"] = y2
    end

    return data
end


"create a dataframe based on powermodels dictionary"
function form_df(case::Dict{String,<:Any};)

    if InfrastructureModels.ismultinetwork(case)
        Memento.error(_LOGGER, "form_df does not yet support multinetwork data")
    end

    data = deepcopy(case)

    df_return = Dict{String,DataFrame}()
    component_types = []
    metadata_key = Symbol[]
    metadata_val = Any[]

    #Network meta_data
    for (k,v) in sort(collect(data); by=x->x[1])
        if typeof(v) <: Dict && InfrastructureModels._iscomponentdict(v)
            push!(component_types, k)
        else
            push!(metadata_key,Symbol(k))
            push!(metadata_val,[v])
        end
    end
    df_return["metadata"] = DataFrame(metadata_val,metadata_key)

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

        df_return[comp_type][!,:ComponentType] .=comp_type
    end

    return df_return
end



function plot_vega(case, spring_constant=1e-3)
    data = layout_graph_vega(case, spring_constant)
    remove_information!(data)
    df = form_df(data)
    p = @vlplot(
        width=500,
        height=500,
        config={view={stroke=nothing}},
        x={axis=nothing},
        y={axis=nothing},
        color={
            :ComponentType,
            scale={
                domain=[
                    "branch","bus","gen","connector",
                ],
                range=[
                    :green,
                    :blue,
                    :red,
                    :gray
                ]
            }
        },
    ) +
    @vlplot(
        mark ={
            :rule,
            tooltip=("content" => "data"),
            opacity =  1.0
        },
        data=df["branch"],
        x = :xcoord_1,
        x2 = :xcoord_2,
        y = :ycoord_1,
        y2 = :ycoord_2,
        size={value=5},
    ) +
    @vlplot(
        mark ={
            :rule,
            "tooltip" =("content" => "data"),
            opacity =  1.0
        },
        data=df["connector"],
        x = :xcoord_1,
        x2 = :xcoord_2,
        y = :ycoord_1,
        y2 = :ycoord_2,
        size={value=3},
        strokeDash={value=[4,4]}
    ) +
    @vlplot(
        data = df["bus"],
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0
        },
        x={:xcoord_1,},
        y={:ycoord_1,},
        size={value=1e2},
    )+
    @vlplot(
        data = df["gen"],
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0
        },
        x={:xcoord_1,},
        y={:ycoord_1,},
        size={value=5e1},
    )
    return p
end


function remove_information!(data)
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "br_status", "t_bus",  "qf", "angmin", "angmax", "qt", "transformer", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index"],
                        "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id", "area","lam_p","zone", "bus_i"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
                        "gen"     => ["gen_status","vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin","model", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",],#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", ]
    )
    for comp_type in ["bus","branch","gen"]
        for (id, comp) in data[comp_type]
            for key in keys(comp)
                if (key in invalid_keys[comp_type])
                    delete!(comp,key)
                end
            end
        end
    end
end
