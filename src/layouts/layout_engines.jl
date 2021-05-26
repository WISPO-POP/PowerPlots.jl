
"Kamada Kawai Layout"
function kamada_kawai(G::PowerModelsGraph{T}, dist::Union{Nothing,Matrix{Float64}}=nothing, pos::Union{Nothing,Matrix{Float64}}=nothing, weight="weight", scale=1, center=nothing, dim=2) where T<:LightGraphs.AbstractGraph #::Array{Array{Float64,1},1}
    graph = LightGraphs.SimpleGraph(G.graph) # convert to undirected graph
    nNodes = LightGraphs.nv(graph)
    if nNodes == 0
        return
    end

    if dist===nothing
        dist=Dict()
        for i in 1:nNodes
            dist[i]=LightGraphs.dijkstra_shortest_paths(graph, i).dists
        end
    end
    dist_mtx = 1e6 * ones(nNodes, nNodes) #reform dist into matrix, probably easier??
    for nr in LightGraphs.vertices(graph)
        rdist = dist[nr]
        for nc in LightGraphs.vertices(graph)
            dist_mtx[nr,nc] = rdist[nc]
        end
    end
    if pos===nothing
        if dim >= 3
            pos= 2 .* rand(Float64,dim, nNodes) .- 1 #??? make a matrix n x dim
        elseif dim == 2
            a = LightGraphs.adjacency_matrix(graph)
            pos = convert(Array,RecursiveArrayTools.VectorOfArray(NetworkLayout.Circular.layout(a)))
        else
            pos = [pt for pt in range(0, 1, length=nNodes)]
        end
    end

    pos = _kamada_kawai_solve(dist_mtx, pos, dim, nNodes)
    positions = [[pos[1,i],pos[2,i]] for i in 1:size(pos,2)]
    return positions
end


"""
Anneal node locations based on the Kamada-Kawai cost-function,
using the supplied matrix of preferred inter-node distances,
and starting locations.
"""
function _kamada_kawai_solve(dist_mtx::Array{Float64,2}, pos_arr::Array{Float64,2}, dim::Int, nNodes::Int)::Matrix{Float64}
    pos_vec = pos_arr[:]
    meanwt = 1e-3

    opt = NLopt.Opt(:LD_LBFGS, length(pos_vec))
    opt.xtol_rel = 1e-4
    opt.min_objective = (pos_vec, grad)->_kamada_kawai_costfn(pos_vec,grad,1.0./(dist_mtx + LinearAlgebra.I(nNodes) * 1e-3), meanwt, dim, nNodes)
    (minf,minx,ret) = NLopt.optimize(opt, pos_vec)

    numevals = opt.numevals # the number of function evaluations
    #println("got $minf at $minx after $numevals iterations (returned $ret)")
    return reshape(minx, dim, nNodes)
end

"Cost-function and gradient for Kamada-Kawai layout algorithm"
function _kamada_kawai_costfn(pos_vec::Vector{Float64}, grad::Vector{Float64}, invdist::Array{Float64,2}, meanweight::Float64, dim::Int, nNodes::Int)
    pos_arr = reshape(pos_vec,dim,nNodes)
    delta = zeros(Float64,dim,nNodes,nNodes)
    for i in 1:nNodes
        delta[:,:,i] = pos_arr .- pos_arr[:,i]
    end

    nodesep = zeros(Float64, dim, nNodes)
    nodesep =  reshape(sqrt.(sum(x -> x^2, delta; dims=1)),nNodes,nNodes)
    direction = OMEinsum.ein"ijk,jk -> ijk"(delta, 1.0./(nodesep+LinearAlgebra.I(nNodes)*1e-3))

    offset = nodesep .* invdist .- 1.0
    for i in 1:nNodes
        offset[i,i] = 0.0
    end

    cost = 0.5 * sum(offset.^2)
    gradient = OMEinsum.ein"jk,jk,ijk->ij"(invdist, offset, direction) - OMEinsum.ein"jk,jk,ijk->ik"(invdist, offset, direction)

    # # Additional parabolic term to encourage mean position to be near origin:
    sumpos = sum(pos_arr, dims=2)
    cost += 0.5 .* meanweight .* sum(sumpos.^2)
    origin_penalty = meanweight*sumpos
    for i in 1:nNodes
        gradient[:,i] += origin_penalty
    end
    if length(grad) > 0
        grad[:] = gradient[:]
    end

    return cost
end

function layout_graph_kamada_kawai!(G,ids) #return type must be dictionary
    pos = kamada_kawai(G)
    positions = Dict(zip(ids,pos)) #zip node ids to generated positions
    return positions
end


module Spring_v2
import GeometryBasics
import LinearAlgebra
Point = GeometryBasics.Point #eliminate need to specify package when using Point type in module
norm = LinearAlgebra.norm
struct Layout{M<:AbstractMatrix,P<:AbstractVector,T<:AbstractFloat}
    adj_matrix::M
    positions::P
    C::T
    iterations::Int
    initialtemp::T
end

function Layout(adj_matrix, PT::Type{Point{N,T}}=Point{2,Float64};
                startpositions=map(x -> 2 .* rand(PT) .- 1, 1:size(adj_matrix, 1)), C=2.0, iterations=100,
                initialtemp=2.0) where {N,T}
    return Layout(adj_matrix, startpositions, T(C), Int(iterations), T(initialtemp))
end

layout(adj_matrix, dim::Int; kw_args...) = layout(adj_matrix, Point{dim,Float64}; kw_args...)

function layout(adj_matrix, PT::Type{Point{N,T}}=Point{2,Float64};
                startpositions=map(x -> 2 .* rand(PT) .- 1, 1:size(adj_matrix, 1)), fixed = nothing, kw_args...) where {N,T}

    #since random start positions are defined in this function, add functionality to set start positions for fixed nodes
    #note that type of start positions will be a dictionary with entries node => (x pos, y pos)
    #supports 2d only right now, no need for 3d power grids.

    #it is assumed that "fixed" is a dictionary mapping nodes to their positions, positions are expressed as Point{2,Float64}
    for x in 1:size(adj_matrix,1) #loop through nodes
        if fixed !=nothing
            if x ∈ keys(fixed)
                startpositions[x] = fixed[x]
            end
        end
    end

    #correct start positions are set for fixed nodes, and list of fixed nodes is passed forward to next function
    return layout!(adj_matrix, startpositions,fixed; kw_args...)
end

function layout!(adj_matrix, startpositions::AbstractVector{Point{N,T}},fixed; kw_args...) where {N,T}
    size(adj_matrix, 1) != size(adj_matrix, 2) && error("Adj. matrix must be square.")
    # Layout object for the graph
    network = Layout(adj_matrix, Point{N,T}; startpositions=startpositions, kw_args...)
    next = iterate(network)#just a check to see if only single iteration, no need for fixed nodes
    while next != nothing
        (i, state) = next
        next = iterate(network, state,fixed)
    end
    return network.positions
end

function iterate(network::Layout) #this is just a check to make sure that
    network.iterations == 1 && return nothing
    return network, 1
end

function iterate(network::Layout{M,P,T}, state,fixed) where {M,P,T}
    # The optimal distance bewteen vertices
    adj_matrix = network.adj_matrix
    N = size(adj_matrix, 1)
    force = zeros(eltype(P), N)
    locs = network.positions
    C = network.C
    iterations = network.iterations
    initialtemp = network.initialtemp
    N = size(adj_matrix, 1)
    Ftype = eltype(force)
    K = C * sqrt(4.0 / N)

    # Calculate forces
    for i in 1:N
        force_vec = Ftype(0)
        for j in 1:N
            i == j && continue
            d = norm(locs[j] .- locs[i])
            if adj_matrix[i, j] != zero(eltype(adj_matrix)) || adj_matrix[j, i] != zero(eltype(adj_matrix))
                # F = d^2 / K - K^2 / d
                F_d = d / K - K^2 / d^2
            else
                # Just repulsive
                # F = -K^2 / d^
                F_d = -K^2 / d^2
            end
            # d  /          sin θ = d_y/d = fy/F
            # F /| dy fy    -> fy = F*d_y/d
            #  / |          cos θ = d_x/d = fx/F
            # /---          -> fx = F*d_x/d
            # dx fx
            force_vec += Ftype(F_d .* (locs[j] .- locs[i]))
        end
        force[i] = force_vec
    end
    # Cool down
    temp = initialtemp / state
    # Now apply them, but limit to temperature
    for i in 1:N
        force_mag = norm(force[i])
        scale = min(force_mag, temp) ./ force_mag
        #if is is a fixed node, do not update its position
        if fixed != nothing
            if i ∉ keys(fixed)
                locs[i] += force[i] .* scale
            end
        end
    end

    network.iterations == state && return nothing #break out of while loop if iteration limit reached.
    return network, (state + 1)
end



end #end module


"Function to layout graph using NetworkLayouts 'Spring' algorithm"
function layout_graph_spring!(G,ids;fixed)
    graph = LightGraphs.SimpleGraph(G.graph) # convert to undirected graph
    a = LightGraphs.adjacency_matrix(graph)
    if fixed !=nothing
        #translate dictionary w/ entries int -> tuple(float64) to entries int -> Point{2,float64}
        fixed_temp = Dict()
        for (node,coords) in fixed
            push!(fixed_temp,node => GeometryBasics.Point{2,Float64}(coords[1],coords[2]))
        end
        fixed = fixed
        pos = Spring_v2.layout(a,fixed = fixed)
    else
        pos = Spring_v2.layout(a)
    end
    positions = Dict(zip(ids,pos))

    return positions
end

