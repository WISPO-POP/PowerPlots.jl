# re-export NetworkLayout algorithms
function Shell(; Ptype=Float64, nlist=Vector{Int}[], kwargs...)
    NetworkLayout.Shell(; Ptype=Ptype, nlist=nlist)
end

function SFDP(; dim=2, Ptype=Float64, tol=1.0, C=0.2, K=1.0, iterations=100, initialpos=GeometryBasics.Point{dim,Ptype}[], seed=1, kwargs...)
    NetworkLayout.SFDP(;dim=dim,  Ptype=Ptype, tol=tol, C=C, K=K, iterations=iterations, initialpos=initialpos, seed=seed)
end

function Spring(; dim=2, Ptype=Float64, C=2.0, iterations=100, initialtemp=2.0, initialpos=GeometryBasics.Point{dim,Ptype}[], seed=1, kwargs...)
    NetworkLayout.Spring(;dim=dim, Ptype=Ptype, C=C, iterations=iterations, initialtemp=initialtemp, initialpos=initialpos, seed=seed)
end

function Stress(;dim=2,Ptype=Float64,iterations=:auto,abstols=0.0,reltols=10e-6,abstolx=10e-6,weights=Array{Float64}(undef, 0, 0),initialpos=GeometryBasics.Point{dim,Ptype}[],seed=1, kwargs...)
    NetworkLayout.Stress(;dim=dim, Ptype=Ptype, iterations=iterations, abstols=abstols, reltols=reltols, abstolx=abstolx, weights=weights, initialpos=initialpos, seed=seed)
end

function SquareGrid(; Ptype=Float64, cols=:auto, dx=Ptype(1), dy=Ptype(-1), skip=Tuple{Int,Int}[], kwargs...)
    NetworkLayout.SquareGrid(; Ptype=Ptype,cols=cols,dx=dx,dy=dy,skip=skip)
end

function Spectral(;dim=3, Ptype=Float64, nodeweights=Float64[], kwargs...)
    NetworkLayout.Spectral(;dim=dim, Ptype=Ptype, nodeweights=nodeweights)
end



"""
Create a layout for a powermodels data dictionary.  This function creates a graph according to the specified keyword arguments `node_types`
and `edge_types`.  A layout function is then applied, by default `layout_graph_kamada_kawai!`.  A new case dictionary with the positions of the
components is returned.
"""
function layout_network(case::Dict{String,<:Any}; kwargs...)
    layout_network!(deepcopy(case); kwargs...)
end

"""
Create a layout for a powermodels data dictionary.  This function creates a graph according to the specified keyword arguments `node_types`
and `edge_types`.  A layout function is then applied, by default `layout_graph_kamada_kawai!`.  A new case dictionary with the positions of the
components is returned.
"""
function layout_network!(data::Dict{String,<:Any};
    node_components::AbstractArray{Symbol,1} = default_node_types,
    edge_components::AbstractArray{Symbol,1} = default_edge_types,
    connected_components::AbstractArray{Symbol,1} = default_connected_types,
    edge_keys::AbstractArray{Any,1} = default_edge_keys,
    connector_keys::AbstractArray{Symbol,1} = default_connector_keys,
    fixed::Bool = false,
    layout_algorithm = kamada_kawai,
    connector_weight::Union{Nothing, AbstractFloat}=nothing,
    edge_weight::Union{Nothing, AbstractFloat}=nothing,
    node_weight::Union{Nothing, AbstractFloat}=nothing,
    kwargs...
    )

    PMG = PowerModelsGraph(data,node_components,edge_components,connected_components,edge_keys,connector_keys)

    # get weights
    edge_weights =  get_edge_weights(data, PMG, edge_weight, connector_weight)
    node_weights = get_node_weights(data, PMG, node_weight)


    if fixed==true # use fixed-position SFDP layout
        rng = MersenneTwister(1)

        # Find nodes with assigned positions
        N = Graphs.nv(PMG.graph)
        fixed_pos = BitVector(undef,N)
        initialpos = Vector{GeometryBasics.Point{2,Float64}}(undef, N)
        for i in 1:length(fixed_pos)
            (comp_type, comp_id) = PMG.node_comp_map[i]
            fixed_pos[i] = haskey(data[string(comp_type)][string(comp_id)], "xcoord_1") && haskey(data[string(comp_type)][string(comp_id)], "ycoord_1")
            initialpos[i] = GeometryBasics.Point(get(data[string(comp_type)][string(comp_id)], "xcoord_1", NaN), get(data[string(comp_type)][string(comp_id)], "ycoord_1", NaN))
        end
        fixed_initial_pos = [j for j in initialpos if !isnan(j)]

        if isempty(fixed_initial_pos)
            Memento.warn(_LOGGER, "No components have a fixed positions provided for initial layout.")
            center= GeometryBasics.Point(0.0, 0.0)
            maxextent = (1.0, 1.0)
            minextent = (-1.0, -1.0)
            range = GeometryBasics.Point(maxextent.-minextent)
        else
            center = sum(fixed_initial_pos)/length(fixed_initial_pos)
            maxextent = (maximum([j[1] for j in initialpos if !isnan(j)]), maximum([j[2] for j in initialpos if !isnan(j)]))
            minextent = (minimum([j[1] for j in initialpos if !isnan(j)]), minimum([j[2] for j in initialpos if !isnan(j)]))
            range = GeometryBasics.Point(maxextent.-minextent)
        end

        for i in 1:length(initialpos)
            if isnan(initialpos[i])
                initialpos[i] = center+GeometryBasics.Point(rand(rng)-0.5,rand(rng)-0.5)*range
            end
        end

        # Create SFDP layout with fixed nodes
        a = Graphs.adjacency_matrix(PMG.graph)
        a = a.*edge_weights
        pos = convert(Array,RecursiveArrayTools.VectorOfArray(SFDP_fixed(; fixed = fixed_pos, initialpos=initialpos, kwargs...)(a)))
        positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]

    elseif layout_algorithm==kamada_kawai
        # create layout using Kamada Kawai algorithm
        positions = layout_algorithm(PMG; weights=edge_weights, kwargs...)

    elseif layout_algorithm == Spectral
        a = Graphs.adjacency_matrix(PMG.graph)
        pos = convert(Array,RecursiveArrayTools.VectorOfArray(layout_algorithm(; nodeweights=node_weights, kwargs...)(a)))
        positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]

    elseif layout_algorithm == Stress
        # weights use a distance between all nodes
        if Set(unique(edge_weights)) != Set([1.0, 0.0]) # if a weight is passed in
            Memento.warn(_LOGGER, "Stress layout does not use edge weights. A kwarg `weights` pairwise nodal distance matrix can be used instead")
        end
        a = Graphs.adjacency_matrix(PMG.graph)
        pos = convert(Array,RecursiveArrayTools.VectorOfArray(layout_algorithm(;kwargs...)(a)))
        positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]

    elseif layout_algorithm ∈ [Shell, Spring, SquareGrid, SFDP]  # Layout does not use weights
        if Set(unique(edge_weights)) != Set([1.0, 0.0]) # if a weight is passed in
            Memento.warn(_LOGGER, "$layout_algorithm layout does not use use weights.")
        end
        a = Graphs.adjacency_matrix(PMG.graph)
        pos = convert(Array,RecursiveArrayTools.VectorOfArray(layout_algorithm(;kwargs...)(a)))
        positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]

    else
        Memento.error(_LOGGER, "layout_algorithm `$(layout_algorithm)` not supported.")
    end

    apply_node_positions!(data, positions, PMG)
    return data
end


"Apply positions to the data, using the mapping in edge_comp_map and connector_map"
function apply_node_positions!(data,positions, PMG)
    # Set Node Positions
    for (node,(comp_type,comp_id)) in PMG.node_comp_map
        data[string(comp_type)][string(comp_id)]["xcoord_1"] = positions[node][1]
        data[string(comp_type)][string(comp_id)]["ycoord_1"] = positions[node][2]
    end
    # Set Edge positions
    for ((s,d),(comp_type,comp_id)) in PMG.edge_comp_map
        data[string(comp_type)][string(comp_id)]["xcoord_1"] = positions[s][1]
        data[string(comp_type)][string(comp_id)]["ycoord_1"] = positions[s][2]
        data[string(comp_type)][string(comp_id)]["xcoord_2"] = positions[d][1]
        data[string(comp_type)][string(comp_id)]["ycoord_2"] = positions[d][2]
    end


    # Create connector dictionary
    data["connector"] = Dict{String,Any}()
    id = 1
    for ((s,d),(comp_type,comp_id)) in PMG.edge_connector_map
        data["connector"][string(id)] =  Dict{String,Any}(
            "src" => PMG.node_comp_map[s],
            "dst" => PMG.node_comp_map[d],
            "xcoord_1" => positions[s][1],
            "ycoord_1" => positions[s][2],
            "xcoord_2" => positions[d][1],
            "ycoord_2" => positions[d][2],
            "source_id"=> (string(comp_type),comp_id)
        )
        id+=1
    end

    return data
end


function get_edge_weights(data::Dict, PMG::PowerModelsGraph, edge_weight::Union{Nothing, AbstractFloat}, connector_weight::Union{Nothing, AbstractFloat})
     # calculate weights
     weights = zeros(size(PMG.graph))
     for ((s,d),(comp_type,comp_id)) in PMG.edge_comp_map

         if haskey(data[string(comp_type)][string(comp_id)],"weight")
             w = data[string(comp_type)][string(comp_id)]["weight"]
         else
             w = isnothing(edge_weight) ? 1.0 : edge_weight
         end
         if w>weights[s,d]
             weights[s,d] = w
             weights[d,s] = w
         end
     end
     for ((s,d),(comp_type,comp_id)) in PMG.edge_connector_map
         if haskey(data[string(comp_type)][string(comp_id)],"weight")
             w = data[string(comp_type)][string(comp_id)]["weight"]
         else
             w = isnothing(connector_weight) ? 1.0 : connector_weight
         end
         if w>weights[s,d]
             weights[s,d] = w
             weights[d,s] = w
         end
     end

    return weights
end

function get_node_weights(data::Dict, PMG::PowerModelsGraph, node_weight::Union{Nothing, AbstractFloat})
    # calculate weights
    weights = zeros(Graphs.nv(PMG.graph))
    for (node,(comp_type,comp_id)) in PMG.node_comp_map
        if haskey(data[string(comp_type)][string(comp_id)],"weight")
            w = data[string(comp_type)][string(comp_id)]["weight"]
        else
            w = isnothing(node_weight) ? 1.0 : node_weight
        end
        weights[node] = w
    end

    return weights
end
