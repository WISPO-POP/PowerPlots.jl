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
                    create_annotations=true,
                    fontsize=12,
                    fontfamily="Arial",
                    fontcolor=:black,
                    textalign=:center,
                    plot_size=(600,600),
                    dpi=300,
                    background_color=:transparent,
                    kwargs...) where T <: LightGraphs.AbstractGraph

    fig = Plots.plot(legend=false, xaxis=false, yaxis=false, grid=false, size=plot_size, dpi=dpi, aspect_ratio=:equal, background_color=background_color)
    nodes = Dict(node => [get_property(graph, node, :x, 0.0), get_property(graph, node, :y, 0.0)] for node in vertices(graph))
    node_keys = sort(collect(keys(nodes)))
    node_x = [nodes[node][1] for node in node_keys]
    node_y = [nodes[node][2] for node in node_keys]
    node_colors = [get_property(graph, node, :color, :black) for node in node_keys]
    node_sizes = [get_property(graph, node, :size, 1) for node in node_keys]


    edge_x = zeros(2,length(edges(graph)))
    edge_y = zeros(2,length(edges(graph)))
    edge_color = []
    edge_width = []
    edge_style = []
    edge_inc = 0
    for edge in edges(graph)
        edge_inc += 1
        edge_x[1,edge_inc] = nodes[LightGraphs.src(edge)][1]
        edge_x[2,edge_inc] = nodes[LightGraphs.dst(edge)][1]
        edge_y[1,edge_inc] = nodes[LightGraphs.src(edge)][2]
        edge_y[2,edge_inc] = nodes[LightGraphs.dst(edge)][2]


        push!(edge_color, get_property(graph, edge, :color, :black))
        push!(edge_width, get_property(graph, edge, :size, 1))
        push!(edge_style, get_property(graph, edge, :style, :solid))

        if label_edges
            label = get_label(graph, edge, Dict(:x=>0.0,:y=>0.0, :text=>Plots.text("")))
            Plots.annotate!(mean(edge_x),mean(edge_y), Plots.text(get_property(graph, edge, :label, ""), fontsize, fontcolor, textalign, fontfamily))
        end
    end

    edge_color = reshape(edge_color, 1, length(edge_color))
    edge_width = reshape(edge_width, 1, length(edge_width))
    edge_style = reshape(edge_style, 1, length(edge_style))
    Plots.plot!(edge_x, edge_y; line=(edge_width, edge_style, edge_color))


    if label_nodes
        node_labels = [Plots.text(get_property(graph, node, :label, ""), fontsize, fontcolor, textalign, fontfamily) for node in node_keys]
        Plots.scatter!(node_x, node_y; color=node_colors, markerstrokewidth=0, markersize=node_sizes, series_annotations=node_labels)
    else
        Plots.scatter!(node_x, node_y; color=node_colors, markerstrokewidth=0, markersize=node_sizes)
    end

    if create_annotations
        annotations = keys(graph.annotationdata)
        for annotation_type in annotations
            for (edge, data) in graph.annotationdata[annotation_type]
                Plots.annotate!(data[:x], data[:y], data[:text])
            end
        end
    end

    return fig
end
