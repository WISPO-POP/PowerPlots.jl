"NetworkX Kamada-Kawai layout function"
function kamada_kawai_layout(graph::PowerModelsGraph{T}; dist=nothing, pos=nothing, weight="weight", scale=1.0, center=nothing, dim=2) where T <: LightGraphs.AbstractGraph
    G = nx.Graph()
    for edge in edges(graph)
        if get_property(graph,edge,:edge_type, "none") == "connector"
            G.add_edge(edge.src, edge.dst, weight=0.5)
        else
            G.add_edge(edge.src, edge.dst, weight=1.0)
        end
    end
    for node in vertices(graph)
        G.add_node(node)
    end

    positions = nx.kamada_kawai_layout(G, dist=dist, pos=pos, weight=weight, scale=scale, center=center, dim=dim)

    return positions
end


"NetworkX spring layout function"
function spring_layout(graph::PowerModelsGraph{T}; k=nothing, pos=nothing, fixed=nothing, iterations=50, threshold=0.0001, weight="weight", scale=1, center=nothing, dim=2, seed=nothing) where T <: LightGraphs.AbstractGraph
    G = nx.Graph()
    for edge in edges(graph)
        G.add_edge(edge.src, edge.dst)
    end

    for node in vertices(graph)
        G.add_node(node)
    end

    positions = nx.spring_layout(G, k=k, pos=pos, fixed=fixed, iterations=iterations, threshold=threshold, weight=weight, scale=scale, center=center, dim=dim, seed=seed)

    return positions
end


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
