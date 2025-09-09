

const default_connected_types = [:gen,:load,:storage,:generator,:voltage_source,:solar,:shunt]
const default_node_types = [:bus]
const default_edge_types = [:branch,:dcline,:switch,:transformer,:line]
default_edge_keys = [(:f_bus, :t_bus), :bus] # allow either (src,dst) or a single key that refers to [src, dst]
default_connector_keys = [:bus, [Symbol(string(i)*"_bus") for i in default_connected_types]...]

function _get_edge_keys(keys_to_check, comp_keys)
    sample_edge_keys = Any[]
    for key in keys_to_check
        if key isa Tuple
            if all(k -> string(k) in comp_keys, key)
                push!(sample_edge_keys, key)
            end
        else
            if string(key) in comp_keys
                push!(sample_edge_keys, key)
            end
        end
    end
    return sample_edge_keys
end

function _validate_edge_keys(keys_to_check)
    for key in keys_to_check
        if key isa Tuple
            @assert length(key) == 2 "Edge key tuple $key must be length 2"
            @assert all(k -> k isa Symbol, key) "Edge key tuple $key must contain only Symbols"
        else
            @assert key isa Symbol error("Edge key $key must be a Symbol or a Tuple of Symbols")
        end
    end
    return nothing
end

"""
    PowerModelsGraph
        graph::Graphs.SimpleDiGraph
        node_comp_map::Dict{Int,Tuple{String, String}}
        edge_comp_map::Dict{Graphs.AbstractEdge,Tuple{String, String}}
        edge_connector_map::Dict{Graphs.AbstractEdge,Tuple{String, String}}

A structure containing a graph of a PowerModels or PowerModelsDistribution network with
four fields: a Graphs.SimpleDiGraph, a map from the node ids to the components, and
 a map from the edges to the components, and a map from the edges to conenctors.
"""
mutable struct PowerModelsGraph
    graph::Graphs.SimpleGraph
    node_comp_map::Dict{Int,Tuple{Symbol, Symbol}}
    edge_comp_map::Dict{Tuple{Int,Int},Tuple{Symbol, Symbol}}
    edge_connector_map::Dict{Tuple{Int,Int},Tuple{Symbol, Symbol}}

    function PowerModelsGraph(data::Dict{String,<:Any},
            node_components::Vector{Symbol},
            edge_components::Vector{Symbol},
            connected_components::Vector{Symbol},
            edge_keys::Vector{<:Any}, # Vector of Symbols or Tuples of Symbols
            connector_keys::Vector{Symbol}
        )
        @assert !isempty(node_components) # must have at least one node type
        @assert !isempty(edge_components) # must have at least one edge type
        _validate_edge_keys(edge_keys) # assert that each key is a Symbol or Tuple of Symbols


        graph_node_count = sum(length(keys(get(data,string(comp_type),Dict()))) for comp_type in [node_components...,connected_components...])
        G = Graphs.SimpleGraph(graph_node_count) # create graph

        node_comp_array = Vector{Tuple{Symbol,Symbol}}(undef,graph_node_count)
        i_1 = 1
        for comp_type in [node_components...,connected_components...]
            if haskey(data,string(comp_type))
                for comp_id in Symbol.(sort(collect(keys(data[string(comp_type)])))) #sort seems to get better layout results?
                    node_comp_array[i_1] = (comp_type,comp_id)
                    i_1+=1
                end
            end
        end
        comp_node_map = Dict(zip(node_comp_array,1:graph_node_count))
        node_comp_map = Dict(zip(1:graph_node_count,node_comp_array))


        edge_comp_count = sum(length(keys(get(data,string(comp_type),Dict()))) for comp_type in edge_components)
        edge_comp_array = Vector{Tuple{Symbol,Symbol}}(undef,edge_comp_count)
        edge_node_array = Vector{Tuple{Int,Int}}(undef,edge_comp_count)

        i_2 = 1
        for comp_type in edge_components # add edges
            if haskey(data,string(comp_type))
                for (comp_id,comp) in data[string(comp_type)]
                    edge_comp_array[i_2] = (comp_type, Symbol(comp_id))

                    # get all keys in comp that match edge_keys
                    keys_in_comp = _get_edge_keys(edge_keys, keys(comp))

                    # if no keys, error
                    @assert !isempty(keys_in_comp) "No edge keys found in component $comp_type $comp_id. Searched for keys: $edge_keys"
                    # if more than 2 keys, error
                    @assert length(keys_in_comp) <= 1 "More than two edge keys found in component $comp_type $comp_id. Found keys: $keys_in_comp"

                    keys_in_comp = keys_in_comp[1] # only one key or tuple of keys allowed
                    # if 1 key, check length on value -> requires it to be length two (unique) ids
                    if length(keys_in_comp) == 1
                        @assert length(comp[string(keys_in_comp[1])]) == 2 "One edge key $(keys_in_comp[1]) in component $comp_type $comp_id found. Must refer to two unique nodes. Found nodes: $(comp[string(keys_in_comp[1])])"
                        s = comp_node_map[(:bus, Symbol(comp[string(keys_in_comp[1])][1]))]
                        d = comp_node_map[(:bus, Symbol(comp[string(keys_in_comp[1])][2]))]
                    end
                    # if 2 keys, one is source, one is destination
                    if length(keys_in_comp) == 2
                        @assert length(comp[string(keys_in_comp[1])]) == 1 && length(comp[string(keys_in_comp[2])]) == 1 "Two edge keys $(keys_in_comp)"*
                        " in component $comp_type $comp_id found. Each key must refer to a single node. Found nodes: $(comp[string(keys_in_comp[1])]) and $(comp[string(keys_in_comp[2])])"
                        s = comp_node_map[(:bus, Symbol(comp[string(keys_in_comp[1])][1]))]
                        d = comp_node_map[(:bus, Symbol(comp[string(keys_in_comp[2])][1]))]
                    end
                    edge_node_array[i_2] = (s,d)
                    Graphs.add_edge!(G, s, d)
                    i_2+=1
                end
            end
        end
        edge_comp_map = Dict(zip(edge_node_array,edge_comp_array))

        edge_connector_count = sum(length(keys(get(data,string(comp_type),Dict()))) for comp_type in connected_components; init=0)
        edge_connector_array = Vector{Tuple{Symbol,Symbol}}(undef,edge_connector_count)
        edge_node_array = Vector{Tuple{Int,Int}}(undef,edge_connector_count)
        i_3 = 1
        for comp_type in connected_components #add connectors
            if haskey(data,string(comp_type))
                for (comp_id,comp) in data[string(comp_type)]
                    edge_connector_array[i_3] = (comp_type,Symbol(comp_id))

                    # get key to the connected node
                    key_in_comp = intersect(connector_keys, Symbol.(keys(comp)))
                    @assert length(key_in_comp) !=0 "No connected keys found in component $comp_type $comp_id. Searched for keys: $connector_keys"
                    @assert length(key_in_comp) <= 1 "More than one connected key found in component $comp_type $comp_id. Found keys: $keys_in_comp"
                    key_in_comp = key_in_comp[1]
                    s = comp_node_map[(:bus,Symbol(comp[string(key_in_comp)]))]
                    d = comp_node_map[(comp_type,Symbol(comp_id))]
                    edge_node_array[i_3] = (s,d)
                    Graphs.add_edge!(G, s, d)
                    i_3+=1
                end
            end
        end
        edge_connector_map = Dict(zip(edge_node_array,edge_connector_array))

        return new(G, node_comp_map, edge_comp_map, edge_connector_map)
    end
end


""
function PowerModelsGraph(data::Dict{String,<:Any};
    node_components=default_node_types,
    edge_components=default_edge_types,
    connected_components=default_connected_types,
    edge_keys=default_edge_keys,
    connector_keys=default_connector_keys
    )
    if eltype(node_components) == String
        node_components = Symbol.(node_components)
    end
    if eltype(edge_components) == String
        edge_components = Symbol.(edge_components)
    end
    if eltype(connected_components) == String
        connected_components = Symbol.(connected_components)
    end
    # if eltype(edge_keys) == Symbol
    #     edge_keys = Symbol.(edge_keys)
    # end
    if eltype(connector_keys) == String
        connector_keys = Symbol.(connector_keys)
    end

    if isempty(node_components)
        node_components = Symbol[]
    end
    if isempty(edge_components)
        edge_components = Symbol[]
    end
    if isempty(connected_components)
        connected_components = Symbol[]
    end
    if isempty(edge_keys)
        edge_keys = Symbol[]
    end
    if isempty(connector_keys)
        connector_keys = Symbol[]
    end

    return PowerModelsGraph(
        data,
        node_components,
        edge_components,
        connected_components,
        edge_keys,
        connector_keys
    )
end

""
function PowerModelsGraph(data::Dict{String,<:Any},
    node_components::AbstractVector{<:Any},
    edge_components::AbstractVector{<:Any},
    connected_components::AbstractVector{<:Any},
    edge_keys::AbstractVector{<:Any},
    connector_keys::AbstractVector{<:Any}
    )
    if eltype(node_components) != Symbol
        node_components = Symbol.(node_components)
    end
    if eltype(edge_components) != Symbol
        edge_components = Symbol.(edge_components)
    end
    if eltype(connected_components) != Symbol
        connected_components = Symbol.(connected_components)
    end
    # if eltype(edge_keys) != Symbol
        # edge keys must be a vector of <:Any.  Validation of type occurs in PMG
    # end
    if eltype(connector_keys) != Symbol
        connector_keys = Symbol.(connector_keys)
    end
     if isempty(node_components)
        node_components = Symbol[]
    end
    if isempty(edge_components)
        edge_components = Symbol[]
    end
    if isempty(connected_components)
        connected_components = Symbol[]
    end
    if isempty(edge_keys)
        edge_keys = Symbol[]
    end
    if isempty(connector_keys)
        connector_keys = Symbol[]
    end

    return PowerModelsGraph(data, node_components, edge_components, connected_components, edge_keys, connector_keys)
end


"""
PowerModelsDataFrame

A structure containing a dataframe for each component type.
"""
mutable struct PowerModelsDataFrame
    metadata::DataFrames.DataFrame
    components::Dict{Symbol,DataFrames.DataFrame}

    function PowerModelsDataFrame(case::Dict{String,<:Any}, components::Vector{Symbol})
        data = deepcopy(case)
        push!(components, :connector)
        if InfrastructureModels.ismultinetwork(data)
            if isnothing(components)
                components = Symbol[]
                for (id,nw) in data["nw"]
                    append!(components, [Symbol(k) for (k,v) in nw if v isa Dict ])
                end
                components = unique(components)
            end
            comp_dataframes = Dict(comp_type=>DataFrames.DataFrame() for comp_type in components)


            data["nw_id"] = "top_level"
            metadata = DataFrames.DataFrame()
            _metadata_to_dataframe!(data, metadata)

            for (nw_id, net) in data["nw"]

                net["nw_id"]=nw_id # give each network, component its parent nw_id
                for comp_type in components
                    for (comp_id, comp) in get(net,string(comp_type),Dict())
                        comp["nw_id"] = nw_id # give each component its nw_id
                        comp["ComponentType"] = comp_type # give each component its type name
                    end

                     #combine toplevel and network metadata
                     _metadata_to_dataframe!(net, metadata)
                    _comp_dict_to_dataframe!(get(net,string(comp_type), Dict{String,Any}()), comp_dataframes[comp_type])
                end
            end
        else # not a multinetwork
            if isnothing(components)
                components = [Symbol(k) for (k,v) in data if v isa Dict]
            end
            comp_dataframes = Dict(comp_type=>DataFrames.DataFrame() for comp_type in components)

            metadata = DataFrames.DataFrame()
            _metadata_to_dataframe!(data, metadata)

            for comp_type in components
                for (id,comp) in get(data, string(comp_type), Dict{String,Any}())

                    comp["ComponentType"] = comp_type
                end
                _comp_dict_to_dataframe!(get(data,string(comp_type), Dict{String,Any}()), comp_dataframes[comp_type])

            end
        end

        new(metadata, comp_dataframes)
    end
end

function PowerModelsDataFrame(case::Dict{String,<:Any}; components::Vector{<:Any}=vcat(default_node_types,default_edge_types,default_connected_types))
    return PowerModelsDataFrame(case, Symbol[Symbol(i) for i in components])
end

"convert non-component data into a dataframe"
function _metadata_to_dataframe!(data, metadata)
    ## Seperate componets Dicts from metadata
    metadata_key = Symbol[]
    metadata_val = Any[]
    for (k,v) in sort(collect(data); by=x->x[1])
        if typeof(v) <: Dict && InfrastructureModels._iscomponentdict(v)
            # if ~(k in [supported_component_types..., "connector"])
            #     Memento.warn(_PM._LOGGER, "Component type $k is not yet not supported")
            # end
        else
            push!(metadata_key,Symbol(k))
            push!(metadata_val,v)
        end
    end

    metadata_dict = Dict(zip(metadata_key, metadata_val))
    DataFrames.push!(metadata, metadata_dict, cols=:union)
    return metadata
end


"convert a component dictionary such as `bus` into a dataframe."
function _comp_dict_to_dataframe!(comp_dict::Dict{String,<:Any}, df)
    if length(comp_dict) <= 0 ## Should there be an empty dataframe, or a nonexistent dataframe?
        return df
    end

    for (i, component) in comp_dict
        for (k,v) in component
            if typeof(v) <: Array || typeof(v) <: Dict
                component[k] = string(v)
            end
        end
        DataFrames.push!(df, component, cols=:union)
    end

    return df
end

"convert a componet dictionary such as `bus` into a dataframe."
function comp_dict_to_dataframe(comp_dict::Dict{String,<:Any})
    return _comp_dict_to_dataframe!(comp_dict, DataFrames.DataFrame())
end
