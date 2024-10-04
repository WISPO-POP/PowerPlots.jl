

# const supported_component_types = ["bus","gen","branch","dcline","load", "switch", "transformer"]
# const supported_node_types = ["bus","gen","load"]
# const supported_edge_types = ["branch","dcline", "switch", "transformer"]
const supported_component_types = [:bus,:gen,:branch,:dcline,:load,:switch,:transformer]
const supported_node_types = [:bus,:gen,:load]
const supported_edge_types = [:branch,:dcline,:switch,:transformer,:connector]

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
    node_comp_map::Dict{Int,Tuple{String, String}}
    edge_comp_map::Dict{Tuple{Int,Int},Tuple{String, String}}
    edge_connector_map::Dict{Tuple{Int,Int},Tuple{String, String}}

    function PowerModelsGraph(data::Dict{String,<:Any}, node_types::Array{String,1}, edge_types::Array{String,1})

        node_count = sum(length(keys(get(data,node_type,Dict()))) for node_type in node_types)
        G = Graphs.SimpleGraph(node_count) # create graph

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
                    Graphs.add_edge!(G, s, d)
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
        edge_node_array = Vector{Tuple{Int,Int}}(undef,edge_connector_count)
        i_3 = 1
        for comp_type in node_types #add connectors
            if comp_type != "bus"
                if haskey(data,comp_type)
                    for (comp_id,comp) in data[comp_type]
                        edge_connector_array[i_3] = (comp_type,comp_id)
                        s = comp_node_map[("bus",string(comp["$(comp_type)_bus"]))]
                        d = comp_node_map[(comp_type,comp_id)]
                        edge_node_array[i_3] = (s,d)
                        Graphs.add_edge!(G, s, d)
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
function PowerModelsGraph(data::Dict{String,<:Any};
    node_types=supported_node_types::Array{String,1},
    edge_types=supported_edge_types::Array{String,1})
    return PowerModelsGraph(data, node_types, edge_types)
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
                    for (comp_id, comp) in get(net,String(comp_type),Dict())
                        comp["nw_id"] = nw_id # give each component its nw_id
                        comp["ComponentType"] = comp_type # give each component its type name
                    end

                     #combine toplevel and network metadata
                     _metadata_to_dataframe!(net, metadata)
                    _comp_dict_to_dataframe!(get(net,String(comp_type), Dict{String,Any}()), comp_dataframes[comp_type])
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
                for (id,comp) in get(data, String(comp_type), Dict{String,Any}())
                    comp["ComponentType"] = comp_type
                end
                _comp_dict_to_dataframe!(get(data,String(comp_type), Dict{String,Any}()), comp_dataframes[comp_type])

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
