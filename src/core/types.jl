
const supported_component_types = ["bus","gen","branch","dcline","load", "connector", "nw"]

"""
    PowerModelsGraph{T<:LightGraphs.AbstractGraph}

A structure containing a graph of a PowerModels or PowerModelsDistribution network in
the format of a LightGraphs.AbstractGraph and corresponding metadata necessary for
analysis / plotting.
"""
mutable struct PowerModelsGraph{T<:LightGraphs.AbstractGraph}
    graph::LightGraphs.AbstractGraph

    metadata::Dict{Union{Int,LightGraphs.AbstractEdge},Dict{Symbol,<:Any}}

    annotationdata::Dict{String,Any}
end


"""
    PowerModelsGraph(nvertices)

Constructor for the PowerModelsGraph struct, given a number of vertices `nvertices`
"""
function PowerModelsGraph(nvertices::Int)
    graph = LightGraphs.SimpleDiGraph(nvertices)

    metadata = Dict{Union{Int,LightGraphs.AbstractEdge},Dict{Symbol,<:Any}}()
    annotationdata = Dict{String,Dict{String<:Any}}()

    return PowerModelsGraph{LightGraphs.SimpleDiGraph}(graph, metadata, annotationdata)
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
