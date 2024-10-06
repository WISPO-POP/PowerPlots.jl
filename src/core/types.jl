

const supported_connected_types = [:gen,:load,:storage]
const supported_node_types = [:bus]
const supported_edge_types = [:branch,:dcline,:switch,:transformer]

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

    function PowerModelsGraph(data::Dict{String,<:Any}, node_components::Array{Symbol,1}, edge_components::Array{Symbol,1}, connected_components::Array{Symbol,1})

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
                    s = comp_node_map[(:bus,comp["f_bus"])]
                    d = comp_node_map[(:bus,comp["t_bus"])]
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
                    s = comp_node_map[(:bus,comp["$(string(comp_type))_bus"])]
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
    node_components=supported_node_types::Array{Symbol,1},
    edge_components=supported_edge_types::Array{Symbol,1},
    connected_components=supported_connected_types::Array{Symbol,1}
    )
    return PowerModelsGraph(data, node_components, edge_components, connected_components)
end


"""
PowerModelsDataFrame

A structure containing a dataframe for each component type.
"""
mutable struct PowerModelsDataFrame
    metadata::DataFrames.DataFrame
    components::Dict{Symbol,DataFrames.DataFrame}

    function PowerModelsDataFrame(case::Dict{String,<:Any}; components=nothing)
        data = deepcopy(case)

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
