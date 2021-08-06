Pkg.activate(".")

using LinearAlgebra
using LoopVectorization
# using PowerPlots

function _calc_direction!(x::AbstractArray{<:Real, 3},y::AbstractArray{<:Real, 2}, z::AbstractArray{<:Real,3})::AbstractArray{<:Real,3}
    @turbo for i in 1:size(z)[1]
        for j in 1:size(z)[2]
            for k in 1:size(z)[3]
                z[i,j,k] = x[i,j,k]*y[j,k]
            end
        end
    end
    return z
end

function _calc_gradient!(
    u::AbstractArray{<:Real, 2},v::AbstractArray{<:Real, 2}, w::AbstractArray{<:Real,3},
    z1::AbstractArray{<:Real, 2},z2::AbstractArray{<:Real, 2},z::AbstractArray{<:Real,2}
    )
    z1 .= zero(eltype(z1))
    z2 .= zero(eltype(z2))
    # @turbo
    for i in 1:size(z)[1]
        for j in 1:size(z)[2]
            for k in 1:size(z)[2]
                z1[i,j] += u[j,k]*v[j,k]*w[i,j,k]
                z2[i,k] += u[j,k]*v[j,k]*w[i,j,k]
            end
        end
    end
    z .= z1.-z2
    return z
end

"Cost-function and gradient for Kamada-Kawai layout algorithm"
function new_kamada_kawai_costfn(
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
    # _calc_direction!(delta,inv_nodesep,direction)
    @turbo for i in 1:size(direction)[1]
        for j in 1:size(direction)[2]
            for k in 1:size(direction)[3]
                direction[i,j,k] = delta[i,j,k]*inv_nodesep[j,k]
            end
        end
    end

    offset .= nodesep .* invdist .- 1.0
    for i in 1:nNodes
        offset[i,i] = 0.0
    end

    cost = 0.5 * sum(x -> x^2, offset)
    _calc_gradient!(invdist, offset, direction, g1,g2,gradient)
    # @turbo for i in 1:size(gradient)[1]
    #     for j in 1:size(gradient)[2]
    #         for k in 1:size(gradient)[2]
    #             g1[i,j] += invdist[j,k]*offset[j,k]*direction[i,j,k]
    #             g2[i,k] += invdist[j,k]*offset[j,k]*direction[i,j,k]
    #         end
    #     end
    # end
    # gradient .= g1.-g2

    # # Additional parabolic term to encourage mean position to be near origin:
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


dim = 2
nNodes = 1000
pos_arr = rand(dim,nNodes)
dist_mtx = rand(nNodes,nNodes)
pos_vec = pos_arr[:]
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

grad = similar(pos_vec)
meanwt = 1e-3

# @time new_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,g1,g2,invdist,delta,direction,offset, meanwt, dim, nNodes)

# @time _calc_direction!(delta,inv_nodesep,direction)

@time _calc_gradient!(invdist, offset, direction, g1,g2,gradient)

# @time PowerPlots._kamada_kawai_costfn(pos_vec,grad,1.0./(dist_mtx + LinearAlgebra.I(nNodes) * 1e-3), meanwt, dim, nNodes)
