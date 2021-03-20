
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
        if InfrastructureModels.ismultinetwork(case)
            comp_dataframes = tuple((DataFrames.DataFrame() for i in 1:7)...)
            for (nw_id, net) in case["nw"]
                comp_dataframes_new= _PowerModelsDataFrame(net::Dict{String,<:Any})
                for df in comp_dataframes_new
                    df[!,"nw_id"].=nw_id
                end
                append!.(comp_dataframes, comp_dataframes_new)
            end
            #combine toplevel and network metadata
            metadata = _metadata_to_dataframe(case)
            metadata[!,"nw_id"].="top_level"
            for name in names(metadata)
                if !(name in names(comp_dataframes[1]))
                    comp_dataframes[1][!,name].=missing
                end
            end
            for name in names(comp_dataframes[1])
                if !(name in names(metadata))
                    metadata[!,name].=missing
                end
            end
            vcat(comp_dataframes[1],metadata)
        else
            comp_dataframes = _PowerModelsDataFrame(case::Dict{String,<:Any})
        end
        new(comp_dataframes...)
    end
end


""
function _PowerModelsDataFrame(sn_net::Dict{String,<:Any})

        data = deepcopy(sn_net) # prevent overwriting input data

        ## add comp_type to each component
        for comp_type in supported_component_types
            for (comp_id, comp) in get(data,comp_type,Dict())
                comp["ComponentType"] = comp_type
            end
        end

        ## Assign component DataFrames
        metadata = _metadata_to_dataframe(data)
        bus = _comp_dict_to_dataframe(data["bus"])
        gen = _comp_dict_to_dataframe(data["gen"])
        branch = _comp_dict_to_dataframe(data["branch"])
        dcline = _comp_dict_to_dataframe(data["dcline"])
        load = _comp_dict_to_dataframe(data["load"])
        connector = _comp_dict_to_dataframe(get(data,"connector",Dict{String,Any}()))

    return (metadata,bus,gen,branch,dcline,load,connector)
end


"convert non-component data into a dataframe"
function _metadata_to_dataframe(data)
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
            push!(metadata_val,[v])
        end
    end
    metadata = DataFrames.DataFrame(metadata_val,metadata_key)
    return metadata
end


"convert a componet dictionary such as `bus` into a dataframe."
function _comp_dict_to_dataframe(comp_dict::Dict{String,<:Any})
    if length(comp_dict) <= 0 ## Should there be an empty dataframe, or a nonexistent dataframe?
        return DataFrames.DataFrame()
    end

    columns = [Symbol(k) => (typeof(v) <: Array || typeof(v) <: Dict) ? String[] : typeof(v)[] for (k,v) in first(comp_dict)[2]]

    df = DataFrames.DataFrame(columns...)
    for (i, component) in comp_dict
        for (k,v) in component
            if typeof(v) <: Array || typeof(v) <: Dict
                component[k] = string(v)
            end
        end
        push!(df, component)
    end

    return df
end
