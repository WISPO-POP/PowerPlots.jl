
# move kwargs into plot_graph
                      # label_nodes::Bool=false,
                      # label_edges::Bool=false,
                      # fontsize::Real=12,
                      # fontfamily::String="Arial",
                      # fontcolor::Union{Symbol,<:Colors.AbstractRGB}=:black,
                      # textalign::Symbol=:center,
                      # plot_size::Tuple{Int,Int}=(300,300),
                      # dpi::Int=100

"""
    plot_network(graph; kwargs...)

Plots a network `graph`. Returns `PowerModelsGraph` and `Plots.AbstractPlot`.

# Parameters

* `graph::PowerModelsGraph{<:LightGraphs.AbstractGraph}`

    Network graph

* `filename::Union{Nothing,String}`

    Default: `nothing`. File to output the plot to, will use user-set Plots.jl backend.

* `label_nodes::Bool`

    Default: `false`. Plot labels on nodes.

* `label_edges::Bool`

    Default: `false`. Plot labels on edges.

* `colors::Dict{String,<:Colors.AbstractRGB}`

    Default: `Dict()`. Changes to default colors, see `default_colors` for available components.

* `load_color_range::Union{Nothing,Vector{<:Colors.AbstractRGB}}`

    Default: `nothing`. Range of colors for load statuses to be displayed in.

* `node_size_lims::Array`

    Default: `[10, 25]`. Min/Max values for the size of nodes.

* `edge_width_lims::Array`

    Default: `[1, 2.5]`. Min/Max values for the width of edges.

* `positions::Union{Dict, PowerModelsGraph}`

    Default: `Dict()`. Used to specify node locations of graph (avoids running layout algorithm every time).

* `use_buscoords::Bool`

    Default: `false`. Use buscoord field on buses for node positions.

* `spring_const::Float64`

    Default: `1e-3`. Only used if buscoords=true. Spring constant to be used to force-direct-layout buses with no buscoord field.

* `apply_spring_layout::Bool`

    Default: `false`. Apply spring layout after initial layout.

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

* `graph::PowerModelsGraph`

    PowerModelsGraph of the network
"""
function plot_network!(plt::Plots.Plot,
                      graph::PowerModelsGraph{T};
                      filename::Union{Nothing,String}=nothing,
                      create_annotations::Bool=true,
                      positions::Union{Dict,PowerModelsGraph}=Dict(),
                      use_buscoords::Bool=false,
                      spring_const::Float64=1e-3,
                      apply_spring_layout::Bool=false,
                      set_network_properties=set_properties_network_status!,
                      membership_properties::Dict{String,<:Any}=Dict{String,Any}(),
                      kwargs...
                      ) where T <: LightGraphs.AbstractGraph

    # Graph Layout
    if isa(positions, PowerModelsGraph)
        positions = Dict(node => [get_property(positions, node, :x, 0.0), get_property(positions, node, :y, 0.0)] for node in vertices(positions))
    end
    for (node, (x, y)) in positions
        set_properties!(graph, node, Dict(:x=>x, :y=>y))
    end

    if !all(hasprop(graph, node, :x) && hasprop(graph, node, :y) for node in vertices(graph))
        layout_graph!(graph, kamada_kawai_layout; use_buscoords=use_buscoords, apply_spring_layout=apply_spring_layout, spring_const=spring_const)
    end

    # Apply membership and formatting
    set_network_properties(graph; membership_properties=membership_properties)


    # Plot
    plot_graph!(plt, graph; kwargs...)
    # label_nodes=label_nodes, label_edges=label_edges, create_annotations=create_annotations, fontsize=fontsize, fontfamily=fontfamily, fontcolor=fontcolor, textalign=textalign, plot_size=plot_size, dpi=dpi)

    if !isnothing(filename)
        Plots.savefig(plt, filename)
    else
        Plots.display(plt)
    end

    return plt
end


"""
    plot_network(case; kwargs...)

Plots a whole network `case` at the bus-level. Returns `PowerModelsGraph` and `Plots.AbstractPlot`.
This function will build the graph from the `case`. Additional `kwargs` are passed to
`plot_network(graph; kwargs...)`.

# Parameters

* `case::Dict{String,Any}`

    Network case data structure

* `edge_types::Array`

    Default: `["branch", "dcline", "transformer"]`. List of component types that are graph edges.

* `source_types::Dict{String,Dict{String,String}}`

    Default:
    ```
    Dict("gen"=>Dict("active"=>"pg", "reactive"=>"qg", "status"=>"gen_status", "active_max"=>"pmax", "active_min"=>"pmin"),
                     "storage"=>Dict("active"=>"ps", "reactive"=>"qs", "status"=>"status"))
    ```

    Dictionary containing information about different source types, including basic `gen` and `storage`.

* `exclude_sources::Union{Nothing,Array}`

    Default: `nothing`. A list of patterns of source names to not include in the graph.

* `aggregate_sources::Bool`

    Default: `false`. If `true`, generators will be aggregated by type for each bus.

* `switch::String`

    Default: `"breaker"`. The keyword that indicates branches are switches.

* `kwargs`

    Passed to `plot_network(graph; kwargs...)`

# Returns

* `graph::PowerModelsGraph`

    PowerModelsGraph of the network
"""
function plot_network!(plt::Plots.Plot,
                      case::Dict{String,Any};
                      edge_types::Array{String}=["branch", "dcline", "transformer"],
                      source_types::Array{String}=["gen", "storage"],
                      exclude_sources::Bool=false,
                      aggregate_sources::Bool=false,
                      kwargs...)

    graph = build_graph_network(case; edge_types=edge_types, source_types=source_types, exclude_sources=exclude_sources, aggregate_sources=aggregate_sources)
    graph = plot_network!(plt, graph; kwargs...)
    return graph
end

function plot_network!(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...)  where T <: LightGraphs.AbstractGraph
      local plt
      try
          plt = Plots.current()
      catch
          return plot_network(network; kwargs...)
      end
      plot_network!(Plots.current(), network; kwargs...)
end

function plot_network(network::Union{PowerModelsGraph{T},Dict{String,Any}};
                    plot_size=(300,300),
                    dpi=300,
                    background_color=:transparent,
                    kwargs...) where T <: LightGraphs.AbstractGraph
    @show plt = Plots.plot(legend=false, xaxis=false, yaxis=false, grid=false, size=plot_size, dpi=dpi, aspect_ratio=:equal, background_color=background_color)
    plot_network!(plt,network; kwargs...)
    return plt
end



"Plot the network with the color defining active status components."
function plot_network_status(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network(network; set_network_properties=set_properties_network_status!, kwargs...)
end

function plot_network_status!(plt::Plots.Plot, network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network!(plt, network; set_network_properties=set_properties_network_status!, kwargs...)
end

function plot_network_status!(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network!(network; set_network_properties=set_properties_network_status!, kwargs...)
end


"Plot the network with branch color showing the percentage of rated power flowing"
function plot_power_flow(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network(network; set_network_properties=set_properties_power_flow!, kwargs...)
end

function plot_power_flow!(plt::Plots.Plot, network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network!(plt, network; set_network_properties=set_properties_power_flow!, kwargs...)
end

function plot_power_flow!(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network(network; set_network_properties=set_properties_power_flow!, kwargs...)
end


"Plot the network with branch color showing the voltage level"
function plot_system_voltage(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network(network; set_network_properties=set_properties_system_voltage!, kwargs...)
end

function plot_system_voltage!(plt::Plots.Plot, network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network!(plt, network; set_network_properties=set_properties_system_voltage!, kwargs...)
end

function plot_system_voltage!(network::Union{PowerModelsGraph{T},Dict{String,Any}}; kwargs...) where T <: LightGraphs.AbstractGraph
    plot_network!(network; set_network_properties=set_properties_system_voltage!, kwargs...)
end
