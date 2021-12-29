

"""
    `kamada_kawai(
        G::PowerModelsGraph,
        dist::Union{Nothing,AbstractMatrix{<:Real}}=nothing,
        pos::Union{Nothing,AbstractMatrix{<:Real}}=nothing,
        weight="weight",
        scale=1,
        center=nothing,
        dim=2)
    `
    calculate node positions use Kamada Kawai layout algorithm
"""
function kamada_kawai(G::PowerModelsGraph, dist::Union{Nothing,AbstractMatrix{<:Real}}=nothing, pos::Union{Nothing,AbstractMatrix{<:Real}}=nothing, weight="weight", scale=1, center=nothing, dim=2; kwargs...)
    graph = G.graph # convert to undirected graph
    nNodes = Graphs.nv(graph)
    if nNodes == 0
        return
    end

    if dist===nothing
        dist=Dict()
        for i in 1:nNodes
            dist[i]=Graphs.dijkstra_shortest_paths(graph, i).dists
        end
    end
    dist_mtx = 1e6 * ones(nNodes, nNodes)
    for nr in Graphs.vertices(graph)
        rdist = dist[nr]
        for nc in Graphs.vertices(graph)
            dist_mtx[nr,nc] = rdist[nc]
        end
    end
    if pos===nothing
        if dim >= 3
            pos= 2 .* rand(Float64,dim, nNodes) .- 1
        elseif dim == 2
            a = Graphs.adjacency_matrix(graph)
            pos = convert(Array,RecursiveArrayTools.VectorOfArray(NetworkLayout.Shell()(a)))
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
function _kamada_kawai_solve(dist_mtx::AbstractMatrix{<:Real}, pos_arr::AbstractMatrix{<:Real}, dim::Int, nNodes::Int)#<:AbstractMatrix{<:Real}
    pos_vec = pos_arr[:]
    meanwt = 1e-3
    invdist = 1.0./(dist_mtx + LinearAlgebra.I(nNodes) * 1e-3)

    delta = Array{eltype(pos_arr),3}(undef,dim,nNodes,nNodes)
    nodesep = similar(dist_mtx)
    inv_nodesep = similar(dist_mtx)
    parr = similar(pos_arr)
    direction = Array{eltype(pos_arr),3}(undef,dim,nNodes,nNodes)
    offset = similar(dist_mtx)
    gradient = similar(pos_arr)
    g1 = similar(pos_arr)
    g2 = similar(pos_arr)


    opt = NLopt.Opt(:LD_LBFGS, length(pos_vec))
    opt.xtol_rel = 1e-4
    opt.min_objective = (pos_vec, grad)->_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,g1,g2,invdist,delta,direction,offset, meanwt, dim, nNodes)
    (minf,minx,ret) = NLopt.optimize(opt, pos_vec)

    numevals = opt.numevals # the number of function evaluations
    # println("got $minf at $minx after $numevals iterations (returned $ret)")
    # println("got $minf after $numevals iterations (returned $ret)")
    return reshape(minx, dim, nNodes)
end

"Cost-function and gradient for Kamada-Kawai layout algorithm"
function _kamada_kawai_costfn(
    pos_vec::AbstractVector{<:Real},
    grad::AbstractVector{<:Real},
    nodesep::AbstractMatrix{<:Real},
    inv_nodesep::AbstractMatrix{<:Real},
    pos_arr::AbstractMatrix{<:Real},
    gradient::AbstractMatrix{<:Real},
    g1::AbstractMatrix{<:Real},
    g2::AbstractMatrix{<:Real},
    invdist::AbstractMatrix{<:Real},
    delta::AbstractArray{<:Real,3},
    direction::AbstractArray{<:Real,3},
    offset::AbstractMatrix{<:Real},
    meanweight::Real,
    dim::Int,
    nNodes::Int
    )::Real

    pos_arr .= reshape(pos_vec,dim,nNodes)
    for i in 1:nNodes
        delta[:,:,i] .= pos_arr .- pos_arr[:,i]
    end

    nodesep .=  sqrt.(reshape(sum(x -> x^2, delta; dims=1),nNodes,nNodes)) # 1/3 allocations
    inv_nodesep .= 1.0./(nodesep+LinearAlgebra.I(nNodes)*1e-3) # 1/3 allocations
    _calc_direction!(delta,inv_nodesep,direction)

    offset .= nodesep .* invdist .- 1.0
    for i in 1:nNodes
        offset[i,i] = 0.0
    end

    cost = 0.5 * sum(x -> x^2, offset)
    _calc_gradient!(invdist, offset, direction, g1,g2,gradient)

    # Additional parabolic term to encourage mean position to be near origin:
    sumpos = sum(pos_arr, dims=2)
    cost += 0.5 .* meanweight .* sum(sumpos.^2)
    origin_penalty = meanweight*sumpos
    @inbounds for i in 1:nNodes
        gradient[:,i] = gradient[:,i] .+ origin_penalty
    end
    if length(grad) > 0
        grad[:] = gradient[:]
    end

    return cost
end

function _calc_direction!(x::AbstractArray{<:Real, 3},y::AbstractArray{<:Real, 2}, z::AbstractArray{<:Real,3})::AbstractArray{<:Real,3}
    @simd for i in axes(z,1)
        @views z[i,:,:] = x[i,:,:].*y[:,:]
    end
    return z
end


function _calc_gradient!(
    u::AbstractArray{<:Real, 2},v::AbstractArray{<:Real, 2}, w::AbstractArray{<:Real,3},
    z1::AbstractArray{<:Real, 2},z2::AbstractArray{<:Real, 2},z::AbstractArray{<:Real,2}
    )
    z1 .= zero(eltype(z1))
    z2 .= zero(eltype(z2))

    @simd for i in axes(z,1)
        for j in axes(z,2)
             for k in axes(z,2)
                z1[i,j] += u[j,k]*v[j,k]*w[i,j,k]
                z2[i,k] += u[j,k]*v[j,k]*w[i,j,k]
            end
        end
    end
    z .= z1.-z2
    return z
end