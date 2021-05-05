# "NetworkX Kamada-Kawai layout function"
# function kamada_kawai_layout_nx(graph::PowerModelsGraph{T}; dist=nothing, pos=nothing, weight="weight", scale=1.0, center=nothing, dim=2) where T <: LightGraphs.AbstractGraph
#     G = nx.Graph()
#     for edge in edges(graph)
#         if get_property(graph,edge,:edge_type, "none") == "connector"
#             G.add_edge(edge.src, edge.dst, weight=0.5)
#         else
#             G.add_edge(edge.src, edge.dst, weight=1.0)
#         end
#     end
#     for node in vertices(graph)
#         G.add_node(node)
#     end

#     positions = nx.kamada_kawai_layout(G, dist=dist, pos=pos, weight=weight, scale=scale, center=center, dim=dim)

#     return positions
# end


# "NetworkX spring layout function"
# function spring_layout(graph::PowerModelsGraph{T}; k=nothing, pos=nothing, fixed=nothing, iterations=50, threshold=0.0001, weight="weight", scale=1, center=nothing, dim=2, seed=nothing) where T <: LightGraphs.AbstractGraph
#     G = nx.Graph()
#     for edge in edges(graph)
#         G.add_edge(edge.src, edge.dst)
#     end

#     for node in vertices(graph)
#         G.add_node(node)
#     end

#     positions = nx.spring_layout(G, k=k, pos=pos, fixed=fixed, iterations=iterations, threshold=threshold, weight=weight, scale=scale, center=center, dim=dim, seed=seed)

#     return positions
# end


## Julia based spring layout
#todo check for bugs, speed.  Is it faster than networkx?
# function spring_layout(graph::PowerModelsGraph{T}; k::Float64=1.0, pos=nothing, fixed=nothing, iterations=50, threshold=0.0001) where T <: LightGraphs.AbstractGraph
#     adj_matrix = LightGraphs.adjacency_matrix(graph.graph)
#     N = size(adj_matrix,1)
#
#     t = max(maximum([pos[j][1] for j in 1:N]) - minimum([pos[j][1] for j in 1:N]), maximum([pos[j][2] for j in 1:N]) - minimum([pos[j][2] for j in 1:N])) * 0.1
#     dt = t / float(iterations + 1)
#
#     ## convert to array
#     positions = zeros(2,N)
#     index_to_key = Dict()
#     index = 1
#
#     for (k,v) in pos
#         index_to_key[index] = k
#         positions[:,index] = v
#         index += 1
#     end
#
#
#     for iteration in 1:iterations
#         displacement = zeros(Float64,2, N)
#         # loop over rows
#         for i in 1:1
#             if index_to_key[i] in fixed continue end
#             # difference between this row's node position and all others
#             delta = [positions[k,i]-positions[k,j] for j in 1:N, k in 1:2]'
#
#             # distance between points
#             distance = Float64[max(0.01,sqrt(sum(delta[j].^2))) for j in 1:N]
#             # displacement "force"
#             displacement[:,i] += sum(delta .* (k^2 / distance.^2 .- adj_matrix[i,:]' * distance / k), dims=2)
#         end
#         # update positions
#         displacement
#         length = sqrt.(sum(displacement.^2,dims=1))
#         for j in 1:N
#             if length[j] < 0.01
#                 length[j] = 0.1
#             end
#         end
#         delta_pos = (displacement * t ./ length)
#         for j in 1:N
#             if index_to_key[j] in fixed continue end
#             # pos[j] += delta_pos[:,j]
#             positions[:,j] += delta_pos[:,j]
#         end
#
#         # cool temperature
#         t -= dt
#         err = norm(delta_pos) / N
#         if err < threshold
#             break
#         end
#     end
#     # pos = Dict()
#     for index in 1:N
#         pos[index_to_key[index]] = positions[:,index]
#     end
#     return pos
#     # return pos
# end


#####################################################
## Basic script for testing VegaLite backend with  ##
#####################################################

###########################
# Needed for Kamada Kawai #
###########################

"Kamada Kawai Layout"
function kamada_kawai_layout(G::PowerModelsGraph{T}, dist::Union{Nothing,Matrix{Float64}}=nothing, pos::Union{Nothing,Matrix{Float64}}=nothing, weight="weight", scale=1, center=nothing, dim=2) where T<:LightGraphs.AbstractGraph #::Array{Array{Float64,1},1}
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

function layout_graph_KK!(G,ids) #return type must be dictionary
    pos = kamada_kawai_layout(G)
    positions = Dict(zip(ids,pos)) #zip node ids to generated positions
    return positions
end

