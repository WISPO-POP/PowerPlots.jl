using Base: Float64
Pkg.activate(".")

using PowerModels
using PowerPlots
# using LightGraphs
# using OMEinsum
# using RecursiveArrayTools
# using NetworkLayout
# using NLopt


data = PowerModels.parse_file("C:/Users/noahx/Documents/PowerDev/pglib-opf/pglib_opf_case118_ieee.m")
pmg = PowerModelsGraph(data)



@time PowerPlots.kamada_kawai(pmg)
@time PowerPlots.new_kamada_kawai(pmg)

all(PowerPlots.kamada_kawai(pmg) .≈  new_kamada_kawai(pmg))


##
# test costfn
using LinearAlgebra
using OMEinsum

pos_vec = rand(5000)
dim = 2
nNodes = 2500
grad = similar(pos_vec)

pos_arr = reshape(pos_vec,dim, nNodes)
# nodesep = zeros(nNodes, nNodes)

dist_mtx = 1e6 * ones(nNodes, nNodes)
invdist = 1.0./(dist_mtx + LinearAlgebra.I(nNodes) * 1e-3)
meanweight = 1e-3

delta = Array{eltype(pos_arr),3}(undef,dim,nNodes,nNodes)
delta_new = Array{eltype(pos_arr),3}(undef,nNodes,nNodes,dim)
nodesep = similar(dist_mtx)
parr = similar(pos_arr)
direction = Array{eltype(pos_arr),3}(undef,dim,nNodes,nNodes)
offset = similar(dist_mtx)
gradient = similar(pos_arr)


@time new_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,inv_dist,delta,direction,offset, meanweight, dim, nNodes)


@time pos_arr .= reshape(pos_vec,dim,nNodes)
@time for i in 1:nNodes
    delta[:,:,i] .= pos_arr .- pos_arr[:,i]
end

@time nodesep .=  sqrt.(reshape(sum(x -> x^2, delta; dims=1),nNodes,nNodes))
@time inv_nodesep .= 1.0./(nodesep+LinearAlgebra.I(nNodes)*1e-3)
@time direction .= OMEinsum.ein"ijk,jk -> ijk"(delta, inv_nodesep)

@time offset .= nodesep .* invdist .- 1.0
@time for i in 1:nNodes
    offset[i,i] = 0.0
end

@time cost = 0.5 * sum(offset.^2)
@time gradient .= OMEinsum.ein"jk,jk,ijk->ij"(invdist, offset, direction) .- OMEinsum.ein"jk,jk,ijk->ik"(invdist, offset, direction)


# # # Additional parabolic term to encourage mean position to be near origin:
@time sumpos = sum(pos_arr, dims=2)
@time cost += 0.5 .* meanweight .* sum(sumpos.^2)
@time origin_penalty = meanweight*sumpos
@time for i in 1:nNodes
    gradient[:,i] += origin_penalty
end
if length(grad) > 0
    grad[:] = gradient[:]
end