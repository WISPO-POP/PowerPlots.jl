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
    println("Same Layout: $(all(pos1 .≈  pos2))") # same result?
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

grad = similar(pos_vec)
meanwt = 1e-3

allow_loops(true)
ProfileView.@profview new_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,invdist,delta,direction,offset, meanwt, dim, nNodes)

@time new_kamada_kawai_costfn(pos_vec,grad,nodesep,inv_nodesep,parr,gradient,invdist,delta,direction,offset, meanwt, dim, nNodes)