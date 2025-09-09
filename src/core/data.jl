
"return a Dict indexed by bus pairs, with a value of an array of tuples of edge types and edge ids of parallel edges"
 function get_parallel_edges(data, edge_types=default_edge_types, edge_keys=default_edge_keys)
    edge_pairs = Dict()
    for edge_type in edge_types # supported edge_types
        for (id,edge) in get(data, string(edge_type), Dict())

             # get all keys in edge that match edge_keys
            keys_in_edge = _get_edge_keys(edge_keys, keys(edge))
            # if no keys, error
            @assert !isempty(keys_in_edge) "No edge keys found in edgeonent $edge_type $id. Searched for keys: $edge_keys"
            # if more than 2 keys, error
            @assert length(keys_in_edge) <= 1 "More than two edge keys found in edgeonent $edge_type $id. Found keys: $keys_in_edge"

            keys_in_edge = keys_in_edge[1] # only one key or tuple of keys allowed
            # if 1 key, check length on value -> requires it to be length two (unique) ids
            if length(keys_in_edge) == 1
                @assert length(edge[string(keys_in_edge[1])]) == 2 "One edge key $(keys_in_edge[1]) in edgeonent $edge_type $id found. Must refer to two unique nodes. Found nodes: $(edge[string(keys_in_edge[1])])"
                s = edge[string(keys_in_edge[1])][1]
                d = edge[string(keys_in_edge[1])][2]
            end
            # if 2 keys, one is source, one is destination
            if length(keys_in_edge) == 2
                @assert length(edge[string(keys_in_edge[1])]) == 1 && length(edge[string(keys_in_edge[2])]) == 1 "Two edge keys $(keys_in_edge)"*
                " in edgeonent $edge_type $id found. Each key must refer to a single node. Found nodes: $(edge[string(keys_in_edge[1])]) and $(edge[string(keys_in_edge[2])])"
                s = edge[string(keys_in_edge[1])][1]
                d = edge[string(keys_in_edge[2])][1]
            end
            bus_pair = (min(s,d), max(s,d)) # get unique direction

            if !haskey(edge_pairs, bus_pair)
                edge_pairs[bus_pair] = []
            end
            push!(edge_pairs[bus_pair], (edge_type, id))
        end
    end

    for (bus_pair, edges) in edge_pairs
        if length(edges)==1
            delete!(edge_pairs,bus_pair)
        end
    end
    return edge_pairs
end

"Add x/y coords for all any parallel branches, and offset the endpoints so each branch is visible"
function offset_parallel_edges!(data,offset; edge_types=default_edge_types, edge_keys=default_edge_keys)
    get_parallel_edges(data, edge_types, edge_keys)
    for (bus_pair, edges) in get_parallel_edges(data, edge_types, edge_keys)
        n_edges = length(edges)
        xcoord_1 = data["bus"]["$(bus_pair[1])"]["xcoord_1"]
        ycoord_1 = data["bus"]["$(bus_pair[1])"]["ycoord_1"]
        xcoord_2 = data["bus"]["$(bus_pair[2])"]["xcoord_1"]
        ycoord_2 = data["bus"]["$(bus_pair[2])"]["ycoord_1"]

        dx = xcoord_2 - xcoord_1
        dy = ycoord_2 - ycoord_1
        normal_direction = (-dy, dx)./(sqrt(dx^2+dy^2))

        offset_range = range(-offset, offset, length=n_edges)

        for i in eachindex(edges)
            (edge_type, edge_id) = edges[i]
            data[string(edge_type)][edge_id]["ycoord_1"] = ycoord_1 + offset_range[i]*normal_direction[2]
            data[string(edge_type)][edge_id]["ycoord_2"] = ycoord_2 + offset_range[i]*normal_direction[2]
            data[string(edge_type)][edge_id]["xcoord_1"] = xcoord_1 + offset_range[i]*normal_direction[1]
            data[string(edge_type)][edge_id]["xcoord_2"] = xcoord_2 + offset_range[i]*normal_direction[1]
        end
    end
    return data
end


# "converts nan values to 0.0"
# _convert_nan(x) = isnan(x) ? 0.0 : x
# _replace_nan(v) = map(x -> isnan(x) ? zero(x) : x, v)


# "Returns true if PowerModelsGraph `graph` has a `property` on an edge or a node `obj`"
# function hasprop(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}, property::Symbol) where T <: Graphs.AbstractGraph
#     if haskey(graph.metadata, obj)
#         return haskey(graph.metadata[obj], property)
#     else
#         return false
#     end
# end


# "Sets a `property` in the metadata at `key` of `graph` on `obj`"
# function set_property!(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}, key::Symbol, property::Any) where T <: Graphs.AbstractGraph
#     if !haskey(graph.metadata, obj)
#         graph.metadata[obj] = Dict{Symbol,Any}()
#     end

#     graph.metadata[obj][key] = property
# end


# "Sets multiple `properties` in the metadata of `graph` on `obj` at `key`"
# function set_properties!(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}, properties::Dict{Symbol,<:Any}) where T <: Graphs.AbstractGraph
#     if !haskey(graph.metadata, obj)
#         graph.metadata[obj] = Dict{Symbol,Any}()
#     end

#     merge!(graph.metadata[obj], properties)
# end


# "Gets the property in the metadata of `graph` on `obj` at `key`. If property doesn't exist, returns `default`"
# function get_property(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}, key::Symbol, default::Any) where T <: Graphs.AbstractGraph
#     return get(get(graph.metadata, obj, Dict{Symbol,Any}()), key, default)
# end


# "Adds an edge defined by `i` & `j` to `graph`"
# function add_edge!(graph::PowerModelsGraph{T}, i::Int, j::Int) where T <: Graphs.AbstractGraph
#     Graphs.add_edge!(graph.graph, i, j)
# end

# "Add vertex to the graph"
# function add_vertex!(graph::PowerModelsGraph{T}) where T <: Graphs.AbstractGraph
#     Graphs.add_vertex!(graph.graph)
# end

# function adjacency_matrix(graph::PowerModelsGraph{T}) where T <: Graphs.AbstractGraph
#     return Graphs.adjacency_matrix(graph.graph)
# end

# function  dijkstra_shortest_paths(graph::PowerModelsGraph{T}, i) where T <: Graphs.AbstractGraph
#     return Graphs.dijkstra_shortest_paths(graph.graph,i)
# end

# "Returns an iterator of all of the nodes/vertices in `graph`"
# function vertices(graph::PowerModelsGraph{T}) where T <: Graphs.AbstractGraph
#     return Graphs.vertices(graph.graph)
# end

# function nv(graph::PowerModelsGraph{T}) where T <: Graphs.AbstractGraph
#     return Graphs.nv(graph.graph)
# end


# "Returns an iterator of all the edges in `graph`"
# function edges(graph::PowerModelsGraph{T}) where T <: Graphs.AbstractGraph
#     return Graphs.edges(graph.graph)
# end


# "Returns all of the metadata for `obj` in `graph`"
# function properties(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}) where T <: Graphs.AbstractGraph
#     return get(graph.metadata, obj)
# end


# "get node/edge data from graph struct"
# function get_data(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}) where T <: Graphs.AbstractGraph
#     return get_property(graph, obj, :data, Dict{String,Any}())
# end


# "Return label information for `obj` in graph.annotationdata[\"label\"]"
# function get_label(graph::PowerModelsGraph{T}, obj::Union{Int,Graphs.AbstractEdge}, default::Any) where T <: Graphs.AbstractGraph
#     return get(get(graph.annotationdata, "label", Dict{Union{Int,Graphs.AbstractEdge},Any}()), obj, default)
# end

# "Update properties dictionary recursively."
# function update_properties!(default::Dict, new_data::Dict)
#     for (key,v_new) in new_data
#         if haskey(default, key)
#             v_default = default[key]
#             if isa(v_default, Dict) && isa(v_new, Dict)
#                 update_properties!(v_default, v_new)
#             else
#                 default[key] = v_new
#             end
#         else
#             default[key] = v_new
#         end
#     end
# end