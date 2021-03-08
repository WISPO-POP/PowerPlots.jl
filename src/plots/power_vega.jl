
## Experimental Feature!

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


function layout_graph_vega(case::Dict{String,<:Any}, spring_const;
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

# Checks that the given column plot_attributes[data_attr] exists in the data
function _validate_data(data::DataFrames.DataFrame, data_column::Union{String, Symbol}, data_name::String)
    if !(data_column in names(data) || data_column in propertynames(data))
        Memento.warn(_LOGGER, "Data column $(repr(data_column)) does not exist for $(data_name)")
    end
end

# Checks that the given data type attribute is a valid VegaLite data type
function _validate_data_type(plot_attributes::Dict{Symbol, Any}, attr::Symbol)
    valid_types = Set([:quantitative, :temporal, :ordinal, :nominal, :geojson])
    data_type = plot_attributes[attr]
    if !(Symbol(data_type) in valid_types)
        Memento.warn(_LOGGER, "Data type $(repr(data_type)) not a valid VegaLite data type")
    end
end

function plot_vega( case::Dict{String,<:Any};
                    spring_constant::Float64=1e-3,
                    color_symbol=:ComponentType,
                    kwargs...
    )
    @prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
    _validate_plot_attributes(plot_attributes) # check the attributes for valid input types

    data = layout_graph_vega(case, spring_constant)
    remove_information!(data)
    PMD = PowerModelsDataFrame(data)

    # validate data-related attributes
    _validate_data_type(plot_attributes, :gen_data_type)
    _validate_data(PMD.gen, plot_attributes[:gen_data], "generator")
    _validate_data_type(plot_attributes, :bus_data_type)
    _validate_data(PMD.bus, plot_attributes[:bus_data], "bus")
    _validate_data_type(plot_attributes, :branch_data_type)
    _validate_data(PMD.branch, plot_attributes[:branch_data], "branch")
    _validate_data_type(plot_attributes, :dcline_data_type)
    _validate_data(PMD.dcline, plot_attributes[:dcline_data], "DC line")

    # make the plots
    p = VegaLite.@vlplot(
        width=plot_attributes[:width],
        height=plot_attributes[:height],
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
        x={:xcoord_1,type="quantitative"},
        x2={:xcoord_2,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        y2={:ycoord_2,type="quantitative"},
        size={value=plot_attributes[:branch_size]},
        color={
            field=plot_attributes[:branch_data],
            type=plot_attributes[:branch_data_type],
            title="Branch",
            scale={
                range=[plot_attributes[:branch_color]]
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
        x={:xcoord_1,type="quantitative"},
        x2={:xcoord_2,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        y2={:ycoord_2,type="quantitative"},
        size={value=plot_attributes[:dcline_size]},
        color={
            field=plot_attributes[:dcline_data],
            type=plot_attributes[:dcline_data_type],
            title="DCLine",
            scale={
                range=[plot_attributes[:dcline_color]]
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
        x={:xcoord_1,type="quantitative"},
        x2={:xcoord_2,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        y2={:ycoord_2,type="quantitative"},
        size={value=plot_attributes[:connector_size]},
        strokeDash={value=[4,4]},
        color={
            field="ComponentType",
            type="nominal",
            title="Connector",
            scale={
                range=[plot_attributes[:connector_color]]
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
        x={:xcoord_1,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        size={value=plot_attributes[:bus_size]},
        color={
            field=plot_attributes[:bus_data],
            type=plot_attributes[:bus_data_type],
            title="Bus",
            scale={
                range=[plot_attributes[:bus_color]]
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
        x={:xcoord_1,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        size={value=plot_attributes[:gen_size]},
        color={
            field=plot_attributes[:gen_data],
            type=plot_attributes[:gen_data_type],
            title="Gen",
            scale={
                range=[plot_attributes[:gen_color]]
            }
            # legend={orient="bottom-right"}
        },
    )
    return p
end


function remove_information!(data::Dict{String,<:Any})
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
