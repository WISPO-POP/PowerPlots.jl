

const default_connected_types = [:gen,:load,:storage,:generator,:voltage_source,:solar,:shunt]
const default_node_types = [:bus]
const default_edge_types = [:branch,:dcline,:switch,:transformer,:line]

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
            connected_components::Vector{Symbol}
        )
        @assert !isempty(node_components) # must have at least one node type
        @assert !isempty(edge_components) # must have at least one edge type

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
                    edge_comp_array[i_2] = (comp_type,Symbol(comp_id))
                    #TODO  generically identify the node type and keys of source and destination
                    if haskey(comp,"bus")
                        # some transformers have three buses (but seem to be only two unique ones...)
                        edge_node_ids = unique(comp["bus"])
                        @assert length(edge_node_ids) == 2 # one source, one destination
                        (n1,n2) = edge_node_ids
                        s = comp_node_map[(:bus,Symbol(n1))]
                        d = comp_node_map[(:bus,Symbol(n2))]
                    else
                        s = comp_node_map[(:bus,Symbol(comp["f_bus"]))]
                        d = comp_node_map[(:bus,Symbol(comp["t_bus"]))]
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
                    # s = comp_node_map[(:bus,comp["$(string(comp_type))_bus"])]
                    if haskey(comp,"bus")
                        s = comp_node_map[(:bus,Symbol(comp["bus"]))]
                    elseif haskey(comp,"$(string(comp_type))_bus")
                        s = comp_node_map[(:bus,Symbol(comp["$(string(comp_type))_bus"]))]
                    else
                        error("key $(string(comp_type))_bus or bus not found in $(string(comp_type)) component $comp_id")
                    end
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
    if isempty(node_components)
        node_components = Symbol[]
    end
    if isempty(edge_components)
        edge_components = Symbol[]
    end
    if isempty(connected_components)
        connected_components = Symbol[]
    end

    return PowerModelsGraph(data, node_components, edge_components, connected_components)
end

""
function PowerModelsGraph(data::Dict{String,<:Any},
    node_components::AbstractVector{<:Any},
    edge_components::AbstractVector{<:Any},
    connected_components::AbstractVector{<:Any},
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
     if isempty(node_components)
        node_components = Symbol[]
    end
    if isempty(edge_components)
        edge_components = Symbol[]
    end
    if isempty(connected_components)
        connected_components = Symbol[]
    end

    return PowerModelsGraph(data, node_components, edge_components, connected_components)
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
