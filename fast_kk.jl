using LinearAlgebra: isapprox
Pkg.activate(".")

using PowerModels
using PowerPlots
# using LightGraphs
using OMEinsum
using ProfileView
# using RecursiveArrayTools
# using NetworkLayout
# using NLopt

path = "C:/Users/noahx/Documents/PowerDev/pglib-opf/"
PowerModels.silence()

for case in ["pglib_opf_case14_ieee.m","pglib_opf_case118_ieee.m","pglib_opf_case500_goc.m","pglib_opf_case1354_pegase.m"]
    println(case)
    pmg = PowerModelsGraph(PowerModels.parse_file("$(path)$(case)"))
    # ProfileView.@profview pos1 = PowerPlots.kamada_kawai(pmg)
    # ProfileView.@profview pos2 = PowerPlots.new_kamada_kawai(pmg)
    @time pos1 = PowerPlots.kamada_kawai(pmg)
    @time pos2 = PowerPlots.new_kamada_kawai(pmg)
    println("Same Layout: $(isapprox(pos1,pos2; atol=1e-3))") # same result?
    isapprox(pos1,pos2; atol=1e-3)
    println()
end


using LinearAlgebra
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

ProfileView.@profview
@time new_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,g1,g2,invdist,delta,direction,offset, meanwt, dim, nNodes)

@benchmark new_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,g1,g2,invdist,delta,direction,offset, meanwt, dim, nNodes)


ProfileView.@profview
@time PowerPlots._kamada_kawai_costfn(pos_vec,grad,1.0./(dist_mtx + LinearAlgebra.I(nNodes) * 1e-3), meanwt, dim, nNodes)

## Testing things with EINSUM



##


## Tesing many packages
using Einsum,TensorCast, Tullio, TensorOperations

A = 1:2
B = 1:8000
C = 1:8000

x = rand(length(A),length(B),length(C))
y = rand(length(B),length(C))

u = rand(length(B),length(C))
v = rand(length(B),length(C))
w = rand(length(A),length(B),length(C))

z = rand(length(A),length(B), length(C))
z1=similar(z)
z2=similar(z)


@time call_tull3(u,v,w,z1,z2,z)

# @time Einsum.@einsum z1[a,c] := y[b,c] * x[a,b,c]
# @time OMEinsum.@ein z2[a,c] := y[b,c] * x[a,b,c]
# @time TensorCast.@reduce z3[a,c] := sum(b) y[b,c] * x[a,b,c]
# @time Tullio.@tullio z4[a,c] := y[b,c] * x[a,b,c]

function call_tull2(x::AbstractArray{<:Real, 3},y::AbstractArray{<:Real, 2}, z::AbstractArray{<:Real,3})
    # Tullio.@tullio z[a,c] := y[b,c] * x[a,b,c]
    Tullio.@tullio z[i,j,k] = x[i,j,k] * y[j,k]
    return z
end

function call_tull3(
    u::AbstractArray{<:Real, 2},v::AbstractArray{<:Real, 2}, w::AbstractArray{<:Real,3},
    z1::AbstractArray{<:Real, 2},z2::AbstractArray{<:Real, 2},z::AbstractArray{<:Real,2}
    )
    z .= (Tullio.@tullio a1[i,j] := u[j,k]*v[j,k]*w[i,j,k] grad=false ) .- (Tullio.@tullio a2[i,k] := u[j,k]*v[j,k]*w[i,j,k] grad=false )
    return z
end

function call_ome2(x::AbstractArray{<:Real, 3},y::AbstractArray{<:Real, 2}, z::AbstractArray{<:Real,3})
    # OMEinsum.@ein z[a,c] := y[b,c] * x[a,b,c]
    # z1 = OMEinsum.ein"ijk,jk -> ijk"(x, y)
    OMEinsum.@ein z[i,j,k] := x[i,j,k] * y[j,k]
    return z
end

function call_ome3(u::AbstractArray{<:Real, 2},v::AbstractArray{<:Real, 2}, w::AbstractArray{<:Real,3}, z::AbstractArray{<:Real, 2})
    # OMEinsum.@ein z[a,c] := y[b,c] * x[a,b,c]
    # z1 = OMEinsum.ein"ijk,jk -> ijk"(x, y)
    # OMEinsum.@ein z[i,j,k] := x[i,j,k] * y[j,k]
    z .= OMEinsum.ein"jk,jk,ijk->ij"(u, v, w) .- OMEinsum.ein"jk,jk,ijk->ik"(u, v, w)
    # OMEinsum.@ein z1[i,j] := u[j,k]*v[j,k]*w[i,j,k]
    # OMEinsum.@ein z2[i,k] := u[j,k]*v[j,k]*w[i,j,k]
    # z = z1 .- z2
    return z
end


# @time call_tull(x,y)

@time call_tull2(x,y); @time call_ome(x,y)

@benchmark call_tull2(u,v,w)
@benchmark call_ome3(u,v,w,z)
@benchmark call_tull3(u,v,w,z1,z2,z)

@time call_tull3(u,v,w,z1,z2,z)

@time call_ome2(x,y,z); @time call_tull2(x,y,z);


@time sum(x.^2)
@time sum(x -> x^2, x)
@time sum(x -> x^2, x);