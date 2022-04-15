
"return a Dict indexed by bus pairs, with a value of an array of the branch ids of parallel branches"
 function get_parallel_branches(data)
    branch_pairs = Dict()
    for (id,branch) in data["branch"]
        if !haskey(branch_pairs, (branch["f_bus"],branch["t_bus"]))
            branch_pairs[(branch["f_bus"],branch["t_bus"])] = []
        end
        push!(branch_pairs[(branch["f_bus"],branch["t_bus"])], id)
    end

    for (bus_pair, branch_ids) in branch_pairs
        if length(branch_ids)==1
            delete!(branch_pairs,bus_pair)
        end
    end
    return branch_pairs
end

"Add x/y coords for all any parallel branches, and offset the endpoints so each branch is visible"
function offset_parallel_branches!(data,offset)
    for (bp, branch_ids) in get_parallel_branches(data)
        n_branches = length(branch_ids)
        found_coords = false
        ycoord_1 = 0.0
        ycoord_2 = 0.0
        xcoord_1 = 0.0
        xcoord_2 = 0.0
        for br_id in branch_ids
            if haskey(data["branch"][br_id], "ycoord_1")
                ycoord_1 = data["branch"][br_id]["ycoord_1"]
                ycoord_2 = data["branch"][br_id]["ycoord_2"]
                xcoord_1 = data["branch"][br_id]["xcoord_1"]
                xcoord_2 = data["branch"][br_id]["xcoord_2"]
                found_coords=true
            end
        end
        if found_coords ==  false
            Memento.warn(_LOGGER, "Could not find coordinates for any parallel branches in $branch_ids")
        end

        dx = xcoord_2 - xcoord_1
        dy = ycoord_2 - ycoord_1
        normal_direction = (-dy, dx)

        of_range = range(-offset, offset, length=n_branches)

        for i in 1:n_branches
            data["branch"][branch_ids[i]]["ycoord_1"] = ycoord_1 + of_range[i]*normal_direction[2]
            data["branch"][branch_ids[i]]["ycoord_2"] = ycoord_2 + of_range[i]*normal_direction[2]
            data["branch"][branch_ids[i]]["xcoord_1"] = xcoord_1 + of_range[i]*normal_direction[1]
            data["branch"][branch_ids[i]]["xcoord_2"] = xcoord_2 + of_range[i]*normal_direction[1]
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