
const supported_component_types = ["bus","gen","branch","dcline","load", "connector", "nw"]

"""
    PowerModelsGraph
        graph::LightGraphs.SimpleDiGraph
        node_comp_map::Dict{Int,Tuple{String, String}}
        edge_comp_map::Dict{LightGraphs.AbstractEdge,Tuple{String, String}}
        edge_connector_map::Dict{LightGraphs.AbstractEdge,Tuple{String, String}}

A structure containing a graph of a PowerModels or PowerModelsDistribution network with
four fields: a LightGraphs.SimpleDiGraph, a map from the node ids to the components, and
 a map from the edges to the components, and a map from the edges to conenctors.
"""
mutable struct PowerModelsGraph
    graph::LightGraphs.SimpleDiGraph
    node_comp_map::Dict{Int,Tuple{String, String}}
    edge_comp_map::Dict{Tuple{Int,Int},Tuple{String, String}}
    edge_connector_map::Dict{Tuple{Int,Int},Tuple{String, String}}

    function PowerModelsGraph(data::Dict{String,<:Any}, node_types::Array{String,1}, edge_types::Array{String,1})

        node_count = sum(length(keys(get(data,node_type,Dict()))) for node_type in node_types)
        G = LightGraphs.SimpleDiGraph(node_count) # create graph

        node_comp_array = Vector{Tuple{String,String}}(undef,node_count)
        i_1 = 1
        for comp_type in node_types
            if haskey(data,comp_type)
                for comp_id in sort(collect(keys(data[comp_type]))) #sort seems to get better layout results?
                    node_comp_array[i_1] = (comp_type,comp_id)
                    i_1+=1
                end
            end
        end
        comp_node_map = Dict(zip(node_comp_array,1:node_count))
        node_comp_map = Dict(zip(1:node_count,node_comp_array))



        edge_comp_count = sum(length(keys(get(data,edge_type,Dict()))) for edge_type in edge_types)
        edge_comp_array = Vector{Tuple{String,String}}(undef,edge_comp_count)
        edge_node_array = Vector{Tuple{Int,Int}}(undef,edge_comp_count)
        i_2 = 1
        for comp_type in edge_types # add edges
            if haskey(data,comp_type)
                for (comp_id,comp) in data[comp_type]
                    edge_comp_array[i_2] = (comp_type,comp_id)
                    s = comp_node_map[("bus",string(comp["f_bus"]))]
                    d = comp_node_map[("bus",string(comp["t_bus"]))]
                    edge_node_array[i_2] = (s,d)
                    LightGraphs.add_edge!(G, s, d)
                    i_2+=1
                end
            end
        end
        edge_comp_map = Dict(zip(edge_node_array,edge_comp_array))

        # sum does not work when "bus" is only node_type
        # edge_connector_count = sum(length(keys(get(data,node_type,Dict()))) for node_type in node_types if node_type != "bus")
        edge_connector_count = 0
        for node_type in node_types
            if node_type != "bus"
                edge_connector_count+= length(keys(get(data,node_type,Dict())))
            end
        end

        edge_connector_array = Vector{Tuple{String,String}}(undef,edge_connector_count)
        edge_node_array = Vector{Tuple{Int,Int}}(undef,edge_comp_count)
        i_3 = 1
        for comp_type in node_types #add connectors
            if comp_type != "bus"
                if haskey(data,comp_type)
                    for (comp_id,comp) in data[comp_type]
                        edge_connector_array[i_3] = (comp_type,comp_id)
                        s = comp_node_map[("bus",string(comp["$(comp_type)_bus"]))]
                        d = comp_node_map[(comp_type,comp_id)]
                        edge_node_array[i_3] = (s,d)
                        LightGraphs.add_edge!(G, s, d)
                        i_3+=1
                    end
                end
            end
        end
        edge_connector_map = Dict(zip(edge_node_array,edge_connector_array))

        return new(G, node_comp_map, edge_comp_map, edge_connector_map)
    end
end


""
function PowerModelsGraph(data::Dict{String,<:Any}; node_types=["bus","gen","storage"]::Array{String,1}, edge_types=["branch","dcline","switch"]::Array{String,1})
    return PowerModelsGraph(data, node_types, edge_types)
end


"""
PowerModelsDataFrame{T<:LightGraphs.AbstractGraph}

A structure containing a dataframe for each component type.
"""
mutable struct PowerModelsDataFrame
    metadata::DataFrames.DataFrame
    bus::DataFrames.DataFrame
    gen::DataFrames.DataFrame
    branch::DataFrames.DataFrame
    dcline::DataFrames.DataFrame
    load::DataFrames.DataFrame
    connector::DataFrames.DataFrame

    function PowerModelsDataFrame(case::Dict{String,<:Any})
        data = deepcopy(case)
        comp_dataframes = tuple((DataFrames.DataFrame() for i in 1:7)...)
        if InfrastructureModels.ismultinetwork(data)
            for (nw_id, net) in data["nw"]

                net["nw_id"]=nw_id # give each network, component its parent nw_id
                for comp_type in supported_component_types
                    for (comp_id, comp) in get(net,comp_type,Dict())
                        comp["nw_id"] = nw_id
                    end
                end

                comp_dataframes_new= _PowerModelsDataFrame(net::Dict{String,<:Any}, comp_dataframes...)
            end

            #combine toplevel and network metadata
            data["nw_id"] = "top_level"
            _metadata_to_dataframe(data, comp_dataframes[1])
        else
            ## not a multinetwork
            comp_dataframes = _PowerModelsDataFrame(data::Dict{String,<:Any}, comp_dataframes...)

        end
        new(comp_dataframes...)
    end
end


""
function _PowerModelsDataFrame(sn_net::Dict{String,<:Any}, metadata, bus, gen, branch, dcline, load, connector)

        data = deepcopy(sn_net) # prevent overwriting input data

        ## add comp_type to each component
        for comp_type in supported_component_types
            for (comp_id, comp) in get(data,comp_type,Dict())
                comp["ComponentType"] = comp_type
            end
        end


        ## Assign component DataFrames
        _metadata_to_dataframe(data, metadata)
        _comp_dict_to_dataframe(get(data,"bus", Dict{String,Any}()), bus)
        _comp_dict_to_dataframe(get(data,"gen", Dict{String,Any}()), gen)
        _comp_dict_to_dataframe(get(data,"branch", Dict{String,Any}()), branch)
        _comp_dict_to_dataframe(get(data,"dcline", Dict{String,Any}()), dcline)
        _comp_dict_to_dataframe(get(data,"load", Dict{String,Any}()), load)
        _comp_dict_to_dataframe(get(data,"connector",Dict{String,Any}()), connector)

    return (metadata,bus,gen,branch,dcline,load,connector)
end


"convert non-component data into a dataframe"
function _metadata_to_dataframe(data, metadata)
    ## Seperate componets Dicts from metadata
    metadata_key = Symbol[]
    metadata_val = Any[]
    for (k,v) in sort(collect(data); by=x->x[1])
        if typeof(v) <: Dict && InfrastructureModels._iscomponentdict(v)
            if ~(k in supported_component_types)
                Memento.warn(_PM._LOGGER, "Component type $k is not yet not supported")
            end
        else
            push!(metadata_key,Symbol(k))
            push!(metadata_val,v)
        end
    end

    metadata_dict = Dict(zip(metadata_key, metadata_val))
    DataFrames.push!(metadata, metadata_dict, cols=:union)
    return metadata
end


"convert a componet dictionary such as `bus` into a dataframe."
function _comp_dict_to_dataframe(comp_dict::Dict{String,<:Any}, df)
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
    return _comp_dict_to_dataframe(comp_dict, DataFrames.DataFrame())
end
