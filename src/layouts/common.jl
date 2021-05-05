# """
#     layout_graph!(graph, layout_engine; kwargs...)

# A routine to assign positions to all nodes of a `graph` for plotting using `layout_engine`.
# Positions are assigned to the metadata of each node at `:x` and `:y`.

# # Parameters

# * `graph::PowerModelsGraph`

#     Network graph

# * `layout_engine`

#     Default: `kamada_kawai_layout`. Layout Function to use. Applies only when not using `use_buscoords`.

# * `use_buscoords::Bool`

#     Default: `false`. If true, `spring_layout` will be used instead of `layout_engine`.

# * `apply_spring_layout::Bool`

#     Default: `false`. If true, `spring_layout` will be applied after `layout_engine` to ensure separation of overlapping nodes.

# * `spring_const::Float64`

#     Default: `1e-3`. Spring constant to be used by `spring_layout`.

# * `kwargs`

#     Keyword arguments to be used in `layout_engine`.
# """
# function layout_graph!(graph::PowerModelsGraph{T}, layout_engine=kamada_kawai_layout;
#                        use_buscoords::Bool=false,
#                        apply_spring_layout::Bool=false,
#                        spring_const::Float64=1e-3,
#                        kwargs...) where T <: LightGraphs.AbstractGraph
#     if use_buscoords
#         pos = Dict(node => get_property(graph, node, :buscoord, missing) for node in vertices(graph))
#         fixed = [node for (node, p) in pos if !ismissing(p)]

#         avg_x, avg_y = mean(hcat(skipmissing([v for v in values(pos)])...), dims=2)
#         std_x, std_y = std(hcat(skipmissing([v for v in values(pos)])...), dims=2)
#         for (v, p) in pos
#             if ismissing(p)
#                 pos[v] = get(pos,get_property(graph,v,:parent_node,missing),[avg_x,avg_y]) + [std_x*rand(), std_y*rand()]
#             end
#         end
#         positions = spring_layout(graph; pos=pos, fixed=fixed, k=spring_const*minimum(std([p for p in values(pos)])), iterations=100)
#     else
#         positions = layout_engine(graph; kwargs...)
#         if apply_spring_layout
#             positions = spring_layout(graph; pos=positions, k=spring_const*minimum(std([p for p in values(positions)])), iterations=100)
#         end
#     end

#     for (node, (x, y)) in positions
#         set_property!(graph, node, :x, x)
#         set_property!(graph, node, :y, y)
#     end
# end
