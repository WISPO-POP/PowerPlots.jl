## Experimental Feature!

## convert to DataFrames
const node_types = ["bus","gen","storage"]
const edge_types = ["switch","branch","dcline","transformer"]


function _layout_graph!(G,ids) #generate positions using NetworkLayout:Spring
    a = adjacency_matrix(G)
    positions = Spring.layout(a,2;C = 0.5,iterations = 100)
    positions = Dict(zip(ids,positions)) #zip node ids to generated positions
    return positions
end

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


    # find fixed positions of nodes--not currently supported with NetworkLayout.jl
 #=    pos = Dict()
    for (id,node) in node_comp_map
        if haskey(node, "xcoord_1") && haskey(node, "ycoord_1")
            pos[id] = [node["xcoord_1"], node["ycoord_1"]]
        else
            pos[id] = missing
        end
    end
    fixed = [node for (node, p) in pos if !ismissing(p)] =#

    G = PowerModelsGraph(0) #construct empty powermodels graph
    ids = []
    idmap = Dict()
    i = 1 #set up iterator, need to associate LG generated indices with the 'id' field, can use metagraph to add 'id' field to 
    for (id,node) in node_comp_map
        add_vertex!(G) #add vertex to graph
        set_property!(G, i, :id, id) #set :id property to be equal to id.
        push!(ids,id) #add node id (a string "compType_idNo") to list
        push!(idmap,id => i) # push map from id to lg index to dictionary
        i = i + 1 #increment i
    end

    #need to modify so that edges are indexed from src id to dst id, rather than lightgraph index to index
    #current workaround is to create dictionary mapping component ids to lightgraph indices
    #this means that idmap[componentID] == lg index for a given component (bus in this case)

    
    for (id,edge) in edge_comp_map
        add_edge!(G, idmap[edge["src"]], idmap[edge["dst"]])
    end

    for (id,edge) in connector_map
        add_edge!(G, idmap[edge["src"]], idmap[edge["dst"]])
    end

    fixed = [] #empty to force position generation for all nodes
    if isempty(fixed)
        positions =layout_graph_KK!(G,ids)
    else #not accessible
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
        positions = nx.spring_layout(G; pos=pos,  fixed=fixed, k=k,  iterations=100)
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
    data["connector"] = Dict{String,Any}()
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



function plot_vega( case;
                    spring_constant::Float64=1e-3,
                    bus_color=:green,
                    gen_color=:blue,
                    branch_color=:black,
                    dcline_color=:steelblue,
                    connector_color=:gray,
                    color_symbol=:ComponentType
    )
    data = layout_graph_vega(case, spring_constant) #grabs dictionary with positions
    remove_information!(data)
    PMD = PowerModelsDataFrame(data)
    p = VegaLite.@vlplot(
        width=500,
        height=500,
        config={view={stroke=nothing}},
        x={axis=nothing},
        y={axis=nothing},
        resolve={
            scale={
                color=:independent
            }
        },
    ) +
    VegaLite.@vlplot(
        mark ={
            :rule,
            tooltip=("content" => "data"),
            opacity =  1.0,
        },
        data=PMD.branch,
        x = :xcoord_1,
        x2 = :xcoord_2,
        y = :ycoord_1,
        y2 = :ycoord_2,
        size={value=5},
        color={
            field="ComponentType",
            type="nominal",
            title="Branch",
            scale={
                range=[branch_color]
            },
            # legend={orient="bottom-right"}
        },    ) +
    VegaLite.@vlplot(
        mark ={
            :rule,
            tooltip=("content" => "data"),
            opacity =  1.0,
        },
        data=PMD.dcline,
        x = :xcoord_1,
        x2 = :xcoord_2,
        y = :ycoord_1,
        y2 = :ycoord_2,
        size={value=5},
        color={
            field="ComponentType",
            type="nominal",
            title="DCLine",
            scale={
                range=[dcline_color]
            },
            # legend={orient="bottom-right"}
        },
    ) +
    VegaLite.@vlplot(
        mark ={
            :rule,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        data=PMD.connector,
        x = :xcoord_1,
        x2 = :xcoord_2,
        y = :ycoord_1,
        y2 = :ycoord_2,
        size={value=3},
        strokeDash={value=[4,4]},
        color={
            field="ComponentType",
            type="nominal",
            title="Connector",
            scale={
                range=[connector_color]
            },
            # legend={orient="bottom-right"}
        },
    ) +
    VegaLite.@vlplot(
        data = PMD.bus,
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        x={:xcoord_1,},
        y={:ycoord_1,},
        size={value=1e2},
        color={
            field="ComponentType",
            type="nominal",
            title="Bus",
            scale={
                range=[bus_color]
            },
            # legend={orient="bottom-right"}
        },
    )+
    VegaLite.@vlplot(
        data = PMD.gen,
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        x={:xcoord_1,},
        y={:ycoord_1,},
        size={value=5e1},
        color={
            field="ComponentType",
            type="nominal",
            title="Gen",
            scale={
                range=[gen_color]
            }
            # legend={orient="bottom-right"}
        },
    )
    return p
end


function remove_information!(data)
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "transformer", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
                        "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id", "area","lam_p","zone", "bus_i"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
                        "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin","model", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",],#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status" ]
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