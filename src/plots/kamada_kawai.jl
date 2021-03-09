
#####################################################
## Basic script for testing VegaLite backend with  ##
#####################################################

###########################
# Needed for Kamada Kawai #
###########################

"Kamada Kawai Layout"
function kamada_kawai_layout(G::PowerModelsGraph{T}, dist::Union{Nothing,Matrix{Float64}}=nothing, pos::Union{Nothing,Matrix{Float64}}=nothing, weight="weight", scale=1, center=nothing, dim=2) where T<:LightGraphs.AbstractGraph #::Array{Array{Float64,1},1}
    nNodes = nv(G)
    if nNodes == 0
        return
    end

    if dist===nothing
        dist=Dict()
        for i in 1:nNodes
            dist[i]=dijkstra_shortest_paths(G, i).dists
        end
    end
    dist_mtx = 1e6 * ones(nNodes, nNodes) #reform dist into matrix, probably easier??
    for nr in vertices(G)
        rdist = dist[nr]
        for nc in vertices(G)
            dist_mtx[nr,nc] = rdist[nc]
        end
    end
    if pos===nothing
        if dim >= 3
            pos= 2 .* rand(Float64,dim, nNodes) .- 1 #??? make a matrix n x dim
        elseif dim == 2
            a = adjacency_matrix(G)
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
    #println("Cost: $(cost) \t |G|: $(norm(grad)) \t |pos_vec|: $(norm(pos_vec))")
    return cost
end

function layout_graph_KK!(G,ids) #return type must be dictionary
    a = adjacency_matrix(G)
    pos = kamada_kawai_layout(G)
    positions = Dict(zip(ids,pos)) #zip node ids to generated positions
    return positions
end

###############
# Test Script #
###############

# # case = parse_file("pglib_opf_case1354_pegase.m")
#case = parse_file("pglib_opf_case5_pjm.m")
# # case = parse_file("pglib_opf_case3_lmbd.m")
#@time data = create_grid_layout_KK(case); # this takes a while to generate the bus coordinates.
#df = form_df(data)
#p = plot_power_system_vega(df)




