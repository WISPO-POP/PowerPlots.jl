
"""
    PowerModelsGraph{T<:LightGraphs.AbstractGraph}

A structure containing a graph of a PowerModels or PowerModelsDistribution network in
the format of a LightGraphs.AbstractGraph and corresponding metadata necessary for
analysis / plotting.
"""
mutable struct PowerModelsGraph{T<:LightGraphs.AbstractGraph}
    graph::LightGraphs.AbstractGraph

    metadata::Dict{Union{Int,LightGraphs.AbstractEdge},Dict{Symbol,<:Any}}

    annotationdata::Dict{String,Any}
end


"""
    PowerModelsGraph(nvertices)

Constructor for the PowerModelsGraph struct, given a number of vertices `nvertices`
"""
function PowerModelsGraph(nvertices::Int)
    graph = LightGraphs.SimpleDiGraph(nvertices)

    metadata = Dict{Union{Int,LightGraphs.AbstractEdge},Dict{Symbol,<:Any}}()
    annotationdata = Dict{String,Dict{String<:Any}}()

    return PowerModelsGraph{LightGraphs.SimpleDiGraph}(graph, metadata, annotationdata)
end
