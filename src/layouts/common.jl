# re-export NetworkLayout algorithms
function Shell(; Ptype=Float64, nlist=Vector{Int}[], kwargs...)
    NetworkLayout.Shell(; Ptype=Ptype, nlist=nlist)
end

function SFDP(; dim=2, Ptype=Float64, tol=1.0, C=0.2, K=1.0, iterations=100, initialpos=GeometryBasics.Point{dim,Ptype}[], seed=1, kwargs...)
    NetworkLayout.SFDP(;dim=dim,  Ptype=Ptype, tol=tol, C=C, K=K, iterations=iterations, initialpos=initialpos, seed=seed)
end

function Buchheim(;Ptype=Float64, node_size=Float64[], kwargs...)
    NetworkLayout.Buchheim(; Ptype=Ptype, node_size=node_size)
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
function layout_network(case::Dict{String,<:Any};
    fixed = false,
    layout_algorithm = kamada_kawai,
    node_types::Array{String,1}=["bus","gen","storage","load"],
    edge_types::Array{String,1}=["switch","branch","dcline","transformer"],
    connector_weight=0.5,
    edge_weight=1.0,
    kwargs...
    )

    data = deepcopy(case)
    PMG = PowerModelsGraph(data,node_types,edge_types)

    # calculate weights
    weights = zeros(size(PMG.graph))
    for ((s,d),(comp_type,comp_id)) in PMG.edge_comp_map

        if haskey(case[comp_type][comp_id],"weight")
            w = compcase[comp_type][comp_id]["weight"]
        else
            w=edge_weight
        end
        if w>weights[s,d]
            weights[s,d]= w
            weights[d,s]= w
        end
    end
    for ((s,d),(comp_type,comp_id)) in PMG.edge_connector_map
        if haskey(case[comp_type][comp_id],"weight")
            w = compcase[comp_type][comp_id]["weight"]
        else
            w=connector_weight
        end
        if w>weights[s,d]
            weights[s,d]= w
            weights[d,s]= w
        end
    end

    if fixed==true # use fixed-position SFDP layout
        rng = MersenneTwister(1)

        # Find nodes with assigned positions
        N = Graphs.nv(PMG.graph)
        fixed_pos = BitVector(undef,N)
        initialpos = Vector{GeometryBasics.Point{2,Float64}}(undef, N)
        for i in 1:length(fixed_pos)
            (comp_type, comp_id) = PMG.node_comp_map[i]
            fixed_pos[i] = haskey(data[comp_type][comp_id], "xcoord_1") && haskey(data[comp_type][comp_id], "ycoord_1")
            initialpos[i] = GeometryBasics.Point(get(data[comp_type][comp_id], "xcoord_1", 2*rand(rng)-1), get(data[comp_type][comp_id], "ycoord_1", 2*rand(rng)-1))
        end

        # Create SFDP layout with fixed nodes
        a = Graphs.adjacency_matrix(PMG.graph)
        a = a.*weights
        pos = convert(Array,RecursiveArrayTools.VectorOfArray(SFDP_fixed(; fixed = fixed_pos, initialpos=initialpos, kwargs...)(a)))
        positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]

    elseif layout_algorithm ∈ [Shell, SFDP, Buchheim, Spring, Stress, SquareGrid, Spectral]  # Create layout from NetworkLayouts algorithms
        a = Graphs.adjacency_matrix(PMG.graph)
        a = a.*weights
        pos = convert(Array,RecursiveArrayTools.VectorOfArray(layout_algorithm(;kwargs...)(a)))
        positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]

    elseif layout_algorithm==kamada_kawai
        # create layout using Kamada Kawai algorithm
        positions = layout_algorithm(PMG; weights=weights, kwargs...)
    else
        Memento.error(_LOGGER, "layout_algorithm `$(layout_algorithm)` not supported.")
    end

    apply_node_positions!(data,positions, PMG)
    extract_layout_extent!(data, positions)

    return data
end


"Apply positions to the data, using the mapping in edge_comp_map and connector_map"
function apply_node_positions!(data,positions, PMG)
    # Set Node Positions
    for (node,(comp_type,comp_id)) in PMG.node_comp_map
        data[comp_type][comp_id]["xcoord_1"] = positions[node][1]
        data[comp_type][comp_id]["ycoord_1"] = positions[node][2]
    end
    # Set Edge positions
    for ((s,d),(comp_type,comp_id)) in PMG.edge_comp_map
        data[comp_type][comp_id]["xcoord_1"] = positions[s][1]
        data[comp_type][comp_id]["ycoord_1"] = positions[s][2]
        data[comp_type][comp_id]["xcoord_2"] = positions[d][1]
        data[comp_type][comp_id]["ycoord_2"] = positions[d][2]
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
            "source_id"=> (comp_type,comp_id)
        )
        id+=1
    end

    return data
end

"Extract layout coordinate extent for scaling purposes"
function extract_layout_extent!(data::Dict{String,<:Any}, positions)
    # find the extremes
    min_x = min_y = Inf
    max_x = max_y = -Inf
    for pos in positions
        x, y = pos
        min_x, min_y = min(min_x, x), min(min_y, y)
        max_x, max_y = max(max_x, x), max(max_y, y)
    end

    width, height = (max_x - min_x), (max_y - min_y)
    padding = min(50, 0.2 * (width + height) / 2) # set padding to be minimum of 50 px or 20% the average of the width and height

    # add to data
    data["layout_extent"] = Dict{String, Any}()
    data["layout_extent"]["min_x"] = min_x
    data["layout_extent"]["min_y"] = min_y
    data["layout_extent"]["max_x"] = max_x
    data["layout_extent"]["max_y"] = max_y
    data["layout_extent"]["width"] = width
    data["layout_extent"]["height"] = height
    data["layout_extent"]["padding"] = padding

    return data
end