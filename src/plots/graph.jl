"""
    plot_graph(graph; kwargs...)

Plots a graph. Returns `Plots.AbstractPlot`.

# Parameters

* `graph::PowerModelsGraph{<:LightGraphs.AbstractGraph}`

    Network graph

* `label_nodes::Bool`

    Default: `false`. Plot labels on nodes.

* `label_edges::Bool`

    Default: `false`. Plot labels on edges.

* `fontsize::Real`

    Default: `12`. Fontsize of labels.

* `fontfamily::String`

    Default: `"Arial"`. Font Family of labels.

* `fontcolor::Union{Symbol,<:Colors.AbstractRGB}`

    Default: `:black`. Color of the labels.

* `textalign::Symbol`

    Default: `:center`. Alignment of text.

* `plot_size::Tuple{Int,Int}`

    Default: `(300, 300)`. Size of the plot in pixels.

* `dpi::Int`

    Default: `100`. Dots-per-inch of the plot.

# Returns

* `fig<:Plots.AbstractPlot`

    Plots.jl figure
"""
function plot_graph(graph::PowerModelsGraph{T};
                    label_nodes=false,
                    label_edges=false,
                    fontsize=12,
                    fontfamily="Arial",
                    fontcolor=:black,
                    textalign=:center,
                    plot_size=(600,600),
                    dpi=300,
                    kwargs...) where T <: LightGraphs.AbstractGraph

    fig = Plots.plot(legend=false, xaxis=false, yaxis=false, grid=false, size=plot_size, dpi=dpi)
    nodes = Dict(node => [get_property(graph, node, :x, 0.0), get_property(graph, node, :y, 0.0)] for node in vertices(graph))
    node_keys = sort(collect(keys(nodes)))
    node_x = [nodes[node][1] for node in node_keys]
    node_y = [nodes[node][2] for node in node_keys]
    node_colors = [get_property(graph, node, :color, :black) for node in node_keys]
    node_sizes = [get_property(graph, node, :size, 1) for node in node_keys]

    for edge in edges(graph)
        edge_x, edge_y = [], []
        edge_color = get_property(graph, edge, :color, :black)
        edge_width = get_property(graph, edge, :size, 1)
        edge_style = get_property(graph, edge, :style, :solid)
        for n in [LightGraphs.src(edge), LightGraphs.dst(edge)]
            push!(edge_x, nodes[n][1])
            push!(edge_y, nodes[n][2])
        end

        Plots.plot!(edge_x, edge_y; line=(edge_width, edge_style, edge_color))
        if label_edges
            Plots.annotate!(mean(edge_x), mean(edge_y), Plots.text(label_edges ? get_property(graph, edge, :label, "") : "", fontsize, fontcolor, textalign, fontfamily))
        end
    end

    if label_nodes
        node_labels = [Plots.text(get_property(graph, node, :label, ""), fontsize, fontcolor, textalign, fontfamily) for node in node_keys]
        Plots.scatter!(node_x, node_y; color=node_colors, markerstrokewidth=0, markersize=node_sizes, series_annotations=node_labels)
    else
        Plots.scatter!(node_x, node_y; color=node_colors, markerstrokewidth=0, markersize=node_sizes)
    end

    return fig
end
