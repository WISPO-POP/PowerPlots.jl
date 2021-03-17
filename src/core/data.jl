"converts nan values to 0.0"
_convert_nan(x) = isnan(x) ? 0.0 : x
_replace_nan(v) = map(x -> isnan(x) ? zero(x) : x, v)


"Returns true if PowerModelsGraph `graph` has a `property` on an edge or a node `obj`"
function hasprop(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}, property::Symbol) where T <: LightGraphs.AbstractGraph
    if haskey(graph.metadata, obj)
        return haskey(graph.metadata[obj], property)
    else
        return false
    end
end


"Sets a `property` in the metadata at `key` of `graph` on `obj`"
function set_property!(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}, key::Symbol, property::Any) where T <: LightGraphs.AbstractGraph
    if !haskey(graph.metadata, obj)
        graph.metadata[obj] = Dict{Symbol,Any}()
    end

    graph.metadata[obj][key] = property
end


"Sets multiple `properties` in the metadata of `graph` on `obj` at `key`"
function set_properties!(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}, properties::Dict{Symbol,<:Any}) where T <: LightGraphs.AbstractGraph
    if !haskey(graph.metadata, obj)
        graph.metadata[obj] = Dict{Symbol,Any}()
    end

    merge!(graph.metadata[obj], properties)
end


"Gets the property in the metadata of `graph` on `obj` at `key`. If property doesn't exist, returns `default`"
function get_property(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}, key::Symbol, default::Any) where T <: LightGraphs.AbstractGraph
    return get(get(graph.metadata, obj, Dict{Symbol,Any}()), key, default)
end


"Adds an edge defined by `i` & `j` to `graph`"
function add_edge!(graph::PowerModelsGraph{T}, i::Int, j::Int) where T <: LightGraphs.AbstractGraph
    LightGraphs.add_edge!(graph.graph, i, j)
end

"Add vertex to the graph"
function add_vertex!(graph::PowerModelsGraph{T}) where T <: LightGraphs.AbstractGraph
    LightGraphs.add_vertex!(graph.graph)
end

function adjacency_matrix(graph::PowerModelsGraph{T}) where T <: LightGraphs.AbstractGraph
    return LightGraphs.adjacency_matrix(graph.graph)
end

function  dijkstra_shortest_paths(graph::PowerModelsGraph{T}, i) where T <: LightGraphs.AbstractGraph
    return LightGraphs.dijkstra_shortest_paths(graph.graph,i)
end

"Returns an iterator of all of the nodes/vertices in `graph`"
function vertices(graph::PowerModelsGraph{T}) where T <: LightGraphs.AbstractGraph
    return LightGraphs.vertices(graph.graph)
end

function nv(graph::PowerModelsGraph{T}) where T <: LightGraphs.AbstractGraph
    return LightGraphs.nv(graph.graph)
end


"Returns an iterator of all the edges in `graph`"
function edges(graph::PowerModelsGraph{T}) where T <: LightGraphs.AbstractGraph
    return LightGraphs.edges(graph.graph)
end


"Returns all of the metadata for `obj` in `graph`"
function properties(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}) where T <: LightGraphs.AbstractGraph
    return get(graph.metadata, obj)
end


"get node/edge data from graph struct"
function get_data(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}) where T <: LightGraphs.AbstractGraph
    return get_property(graph, obj, :data, Dict{String,Any}())
end


"Return label information for `obj` in graph.annotationdata[\"label\"]"
function get_label(graph::PowerModelsGraph{T}, obj::Union{Int,LightGraphs.AbstractEdge}, default::Any) where T <: LightGraphs.AbstractGraph
    return get(get(graph.annotationdata, "label", Dict{Union{Int,LightGraphs.AbstractEdge},Any}()), obj, default)
end

"Update properties dictionary recursively."
function update_properties!(default::Dict, new_data::Dict)
    for (key,v_new) in new_data
        if haskey(default, key)
            v_default = default[key]
            if isa(v_default, Dict) && isa(v_new, Dict)
                update_properties!(v_default, v_new)
            else
                default[key] = v_new
            end
        else
            default[key] = v_new
        end
    end
end