"""
    build_graph_network(case; kwargs...)

Builds a PowerModelsGraph of a PowerModels/PowerModelsDistribution network `case`.

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

    Dictionary containing information about different generator types, including basic `gen` and `storage`.

* `exclude_sources::Union{Nothing,Array}`

    Default: `nothing`. A list of patterns of generator names to not include in the graph.

* `aggregate_sources::Bool`

    Default: `false`. If `true`, generators will be aggregated by type for each bus.

* `switch::String`

    Default: `"breaker"`. The keyword that indicates branches are switches.

# Returns

* `graph::PowerModelsGraph{LightGraphs.SimpleDiGraph}`

    Simple Directional Graph including metadata
"""
function build_graph_network(case::Dict{String,Any};
                             edge_types=["branch", "dcline", "transformer"],
                             source_types::Dict{String,Dict{String,String}}=Dict("gen"=>Dict("active"=>"pg", "reactive"=>"qg", "status"=>"gen_status", "active_max"=>"pmax", "active_min"=>"pmin"),
                                                                              "storage"=>Dict("active"=>"ps", "reactive"=>"qs", "status"=>"status")),
                             exclude_sources::Union{Nothing,Array}=nothing,
                             aggregate_sources::Bool=false)::PowerModelsGraph

    connected_buses = Set(edge[k] for k in ["f_bus", "t_bus"] for edge_type in edge_types for edge in values(get(case, edge_type, Dict())))

    sources = [(source_type, source) for source_type in keys(source_types) for source in values(get(case, source_type, Dict()))]
    n_buses = length(connected_buses)
    n_sources = length(sources)

    graph = PowerModelsGraph(n_buses + n_sources)
    bus_graph_map = Dict(bus["bus_i"] => i for (i, bus) in enumerate(values(get(case, "bus", Dict()))))
    source_graph_map = Dict("$(source_type)_$(gen["index"])" => i for (i, (source_type, gen)) in zip(n_buses+1:n_buses+n_sources, sources))

    graph_bus_map = Dict(v => k for (k, v) in bus_graph_map)
    graph_source_map = Dict(v => k for (k, v) in source_graph_map)
    graph_map = merge(graph_bus_map, graph_source_map)

    for edge_type in edge_types
        for edge in values(get(case, edge_type, Dict()))
            add_edge!(graph, bus_graph_map[edge["f_bus"]], bus_graph_map[edge["t_bus"]])

            props = Dict{Symbol,Any}(:id => edge["index"],
                                     # :label => edge["index"],
                                     :edge_type => edge_type,
                                     )
            set_properties!(graph, LightGraphs.Edge(bus_graph_map[edge["f_bus"]], bus_graph_map[edge["t_bus"]]), props)
        end
    end

    # Add Generator Nodes
    for (source_type, keymap) in source_types
        for source in values(get(case, source_type, Dict()))
            add_edge!(graph, source_graph_map["$(source_type)_$(source["index"])"], bus_graph_map[source["$(source_type)_bus"]])
            # label =  if source_type == "storage"; "S"; else "~" end
            # active = get(source, PowerModels.pm_component_status[source_type], 1) > 0
            # energized = active && (any(get(source, get(keymap, "active", "pg"), 0.0) .> 0) || any(get(source, get(keymap, "reactive", "qg"), 0.0) .> 0))
            node_props = Dict(:id => source["index"],
                              # :active_power => _convert_nan(sum(get(source, get(keymap, "active", "pg"), 0.0))),
                              # :reactive_power => _convert_nan(sum(get(source, get(keymap, "reactive", "qg"), 0.0))),
                              :node_type => source_type,
                              :parent_node =>bus_graph_map[source[string(source_type,"_bus")]]
                              # :node_membership => node_membership
                              )
            set_properties!(graph, source_graph_map["$(source_type)_$(source["index"])"], node_props)

            edge_props = Dict(:id => source["index"],
                              # :label => "",
                              # :switch => false,
                              :edge_type => "connector",
                              # :edge_membership => "connector"
                              )
            set_properties!(graph, LightGraphs.Edge(source_graph_map["$(source_type)_$(source["index"])"], bus_graph_map[source["$(source_type)_bus"]]), edge_props)
        end
    end

    # Set color of buses based on mean served load
    for bus in values(get(case, "bus", Dict()))
        if haskey(bus, "buscoord")
            set_property!(graph, bus_graph_map[bus["bus_i"]], :buscoord, bus["buscoord"])
        end

        # loads = [load for load in values(get(case, "load", Dict())) if load["load_bus"] == bus["bus_i"]]
        # load_status = length(loads) > 0 ? trunc(Int, round(sum(mean(get(load, "status", 1.0) for load in loads) * 10))) + 1 : 1
        node_props = Dict(:id => bus["index"],
                          :node_type => "bus",

                          # :node_membership => node_membership,
                          # :active => bus[PowerModels.pm_component_status["bus"]] != PowerModels.pm_component_status_inactive,
                          # :load_status => load_status
                          )
        set_properties!(graph, bus_graph_map[bus["bus_i"]], node_props)
    end

    return graph
end

#
# """
#     build_graph_load_blocks(case; kwargs...)
#
# Builds a PowerModelsGraph of a PowerModels/PowerModelsDistribution network `case` separated into load blocks using switches / disabled branches.
#
# # Parameters
#
# * `case::Dict{String,Any}`
#
#     Network case data structure
#
# * `edge_types::Array`
#
#     Default: `["branch", "dcline", "transformer"]`. List of component types that are graph edges.
#
# * `source_types::Dict{String,Dict{String,String}}`
#
#     Default:
#     ```
#     Dict("gen"=>Dict("active"=>"pg", "reactive"=>"qg", "status"=>"gen_status", "active_max"=>"pmax", "active_min"=>"pmin"),
#         "storage"=>Dict("active"=>"ps", "reactive"=>"qs", "status"=>"status"))
#     ```
#
#     Dictionary containing information about different generator types, including basic `gen` and `storage`.
#
# * `exclude_sources::Union{Nothing,Array}`
#
#     Default: `nothing`. A list of patterns of generator names to not include in the graph.
#
# * `aggregate_sources::Bool`
#
#     Default: `false`. If `true`, generators will be aggregated by type for each bus.
#
# * `switch::String`
#
#     Default: `"breaker"`. The keyword that indicates branches are switches.
#
# # Returns
#
# * `graph::PowerModelsGraph{LightGraphs.SimpleDiGraph}`
#
#     Simple Directional Graph including metadata
# """
# function build_graph_load_blocks(case::Dict{String,Any};
#                                  edge_types=["branch", "dcline", "transformer"],
#                                  source_types::Dict{String,Dict{String,String}}=Dict("gen"=>Dict("active"=>"pg", "reactive"=>"qg", "status"=>"gen_status", "active_max"=>"pmax", "active_min"=>"pmin"),
#                                                                                   "storage"=>Dict("active"=>"ps", "reactive"=>"qs", "status"=>"status")),
#                                  exclude_sources::Union{Nothing,Array}=nothing,
#                                  aggregate_sources::Bool=false,
#                                  switch::String="breaker",
#                                  )::PowerModelsGraph
#         # Create copy of network to determine possible islands
#         _network = deepcopy(case)
#         for edge_type in edge_types
#            for edge in values(get(_network, edge_type, Dict()))
#                if get(edge, switch, false)
#                    edge["br_status"] = 0
#                end
#            end
#        end
#
#        # Build graph maps
#        islands = PowerModels.calc_connected_components(_network, edges=edge_types)  # Possible Islands
#        connected_islands = PowerModels.calc_connected_components(case, edges=edge_types)  # Actual Islands
#        n_islands = length(islands)
#
#        island_graph_map = Dict(island => i for (i, island) in enumerate(islands))
#        graph_island_map = Dict(i => island for (island, i) in island_graph_map)
#        connected_island_graph_map = Dict(i => connected_island for (island, i) in island_graph_map for bus in island for connected_island in connected_islands if bus in connected_island)
#        bus_island_map = Dict(bus => i for (island, i) in island_graph_map for bus in island)
#
#        sources = [(source_type, gen) for source_type in keys(source_types) for source in values(get(case, source_type, Dict()))]
#        n_sources = length(sources)
#
#        source_graph_map = Dict("$(source_type)_$(gen["index"])" => i for (i, (source_type, gen)) in zip(n_islands+1:n_islands+n_sources, sources))
#
#        # Initialize MetaGraph
#        graph = PowerModelsGraph(n_islands + n_sources)
#
#        # Add edges (of types in edge_types)
#        for edge_type in edge_types
#            for line in values(get(case, edge_type, Dict()))
#                f_island = bus_island_map[line["f_bus"]]
#                t_island = bus_island_map[line["t_bus"]]
#
#                if f_island != t_island
#                    add_edge!(graph, f_island, t_island)
#
#                    fixed = Bool(all(get(line, "fixed", false)))
#                    status = Bool(get(line, "br_status", 1))
#
#                    edge_membership = !fixed && status ? "closed switch" : !fixed && !status ? "open switch" : fixed && status ? "fixed closed switch" : "fixed open switch"
#                    edge_props = Dict(:label => "$(line["index"])",
#                                      :switch => true,
#                                      :fixed => false,
#                                      :id => line["index"],
#                                      :edge_membership => edge_membership)
#
#                    set_properties!(graph, LightGraphs.Edge(f_island, t_island), edge_props)
#                end
#            end
#        end
#
#        # Add Generators to graph
#        for (source_type, keymap) in source_types
#            for source in values(get(case, source_type, Dict()))
#                add_edge!(graph, source_graph_map["$(source_type)_$(gen["index"])"], bus_island_map[gen["$(source_type)_bus"]])
#                is_condenser = all(get(gen, get(keymap, "active_max", "pmax"), 0.0) .== 0) && all(get(gen, get(keymap, "active_min", "pmin"), 0.0) .== 0)
#                node_membership = get(gen, get(keymap, "status", "gen_status"), 1) == 0 ? "disabled generator" : any(get(gen, get(keymap, "active", "pg"), 0.0) .> 0) ? "energized generator" : is_condenser || (all(get(gen, get(keymap, "active", "pg"), 0.0) .== 0) && any(get(gen, get(keymap, "reactive", "qg"), 0.0) .> 0)) ? "energized synchronous condenser" : "enabled generator"
#                label = source_type == "storage" ? "S" : occursin("condenser", node_membership) ? "C" : "~"
#                node_props = Dict(:label => label,
#                                  :energized => get(gen, get(keymap, "status", "gen_status"), 1) > 0 && (any(get(gen, get(keymap, "active", "pg"), 0.0) .> 0) || any(get(gen, get(keymap, "reactive", "qg"), 0.0) .> 0)) ? true : false,
#                                  :active_power => _convert_nan(sum(get(gen, get(keymap, "active", "pg"), 0.0))),
#                                  :reactive_power => _convert_nan(sum(get(gen, get(keymap, "reactive", "qg"), 0.0))),
#                                  :node_membership => node_membership)
#                set_properties!(graph, source_graph_map["$(source_type)_$(gen["index"])"], node_props)
#
#                edge_props = Dict(:label => "",
#                                  :switch => false,
#                                  :edge_membership => "connector")
#                set_properties!(graph, LightGraphs.Edge(source_graph_map["$(source_type)_$(gen["index"])"], bus_island_map[gen["$(source_type)_bus"]]), edge_props)
#            end
#        end
#
#        # Color nodes based on average load served
#        for node in vertices(graph)
#            if !(node in values(source_graph_map))
#                actual_island = connected_island_graph_map[node]
#                possible_island = graph_island_map[node]
#
#                loads = [load for load in values(get(case, "load", Dict())) if load["load_bus"] in possible_island]
#                load_status = length(loads) > 0 ? trunc(Int, round(sum(mean(get(load, "status", 1.0) for load in loads) * 10))) + 1 : 1
#
#                has_load = length([load for load in loads if get(load, "status", 1.0) > 0]) > 0
#                is_energized = any(get(gen, get(keymap, "status", "gen_status"), 1) != 0 && (any(get(gen, get(keymap, "active", "pg"), 0.0) .> 0) || any(get(gen, get(keymap, "reactive", "qg"), 0.0) .> 0)) for (source_type, keymap) in source_types for source in values(get(case, source_type, Dict())) if gen["$(source_type)_bus"] in actual_island)
#
#                node_membership = has_load && is_energized ? "loaded enabled bus" : has_load && !is_energized ? "loaded disabled bus" : !has_load && is_energized ? "unloaded enabled bus" : "unloaded disabled bus"
#                node_props = Dict(:label => "$node",
#                                  :energized => is_energized,
#                                  :node_membership => node_membership,
#                                  :load_status => load_status)
#
#                set_properties!(graph, node, node_props)
#            end
#        end
#     return graph
# end


function apply_membership!(graph::PowerModelsGraph{T}, case) where T <: LightGraphs.AbstractGraph

    for edge in edges(graph)  # set enabled/disabled lines
        edge_type = graph.metadata[edge][:edge_type]
        id = graph.metadata[edge][:id]

        if edge_type == "connector"
            set_property!(graph, edge, :edge_membership, "connector")
        else
            component = case[edge_type]["$(id)"]
            status = component[PowerModels.pm_component_status[edge_type]]
            if status == PowerModels.pm_component_status_inactive[edge_type]
                set_property!(graph, edge, :edge_membership, "inactive_line")
            elseif status != PowerModels.pm_component_status_inactive[edge_type]
                set_property!(graph, edge, :edge_membership, "active_line")
            else
                set_property!(graph, edge, :edge_membership, "no_membership")
            end
        end
    end

    for node in vertices(graph) # set enabled/disables buses and gens
        node_type = graph.metadata[node][:node_type]
        id = graph.metadata[node][:id]

        component = case[node_type]["$(id)"]
        status = component[PowerModels.pm_component_status[node_type]]

        if status == PowerModels.pm_component_status_inactive[node_type]
            if node_type == "bus"
                set_property!(graph, node, :edge_membership, "inactive_bus")
            elseif node_type == "gen"
                set_property!(graph, node, :edge_membership, "inactive_gen")
            elseif node_type == "storage"
                set_property!(graph, node, :edge_membership, "inactive_storage")
            else
                set_property!(graph, node, :edge_membership, "inactive_node")
            end
        elseif status != PowerModels.pm_component_status_inactive[node_type]
            if node_type == "bus"
                set_property!(graph, node, :edge_membership, "active_bus")
            elseif node_type == "gen"
                set_property!(graph, node, :edge_membership, "active_gen")
            elseif node_type == "storage"
                set_property!(graph, node, :edge_membership, "active_storage")
            else
                set_property!(graph, node, :edge_membership, "active_node")
            end
        else
            set_property!(graph, node, :edge_membership, "no_membership")
        end
    end

end




"""
    apply_plot_network_metadata!(graph; kwargs...)

Builds metadata properties, i.e. color/size of nodes/edges, for plotting based on graph metadata
# Parameters

* `graph::PowerModelsGraph`

    Graph of power network

* `colors::Dict{String,<:Colors.AbstractRGB}`

    Default: `Dict()`. Dictionary of colors to be changed from `default_colors`.

* `load_color_range::Union{Nothing,Vector{<:Colors.AbstractRGB}}`

    Default: `nothing`. Range of colors for load statuses to be displayed in.

* `node_size_lims::Array`

    Default: `[10, 25]`. Min/Max values for the size of nodes.

* `edge_width_lims::Array`

    Default: `[1, 2.5]`. Min/Max values for the width of edges.
"""
function apply_plot_network_metadata!(graph::PowerModelsGraph{T};
                                      membership_properties::Dict{String,<:Colors.AbstractRGB}=Dict{String,Colors.AbstractRGB}(),
                                      # load_color_range::Union{Nothing,Vector{<:Colors.AbstractRGB}}=nothing,
                                      # node_size_lims::Array=[10, 25],
                                      # edge_width_lims::Array=[1, 2.5]
                                      ) where T <: LightGraphs.AbstractGraph
    membership_properties = merge(default_properties, membership_properties)
    # if isnothing(load_color_range)
    #     load_color_range = Colors.range(colors["loaded disabled bus"], colors["loaded enabled bus"], length=11)
    # end

    for edge in edges(graph)
        for (property, value) in membership_properties[get_property(graph, edge, :edge_membership, "no_membership")]
            set_property!(graph, edge, property, value)
            # set_property!(graph, edge, :edge_color, colors[get_property(graph, edge, :edge_membership, "enabled line")])
            # set_property!(graph, edge, :edge_size, get_property(graph, edge, :switch, false) ? 2 : 1)
        end
    end

    for node in vertices(graph)
        for (property, value) in membership_properties[get_property(graph, node, :edge_membership, "no_membership")]
            set_property!(graph, node, property, value)
            # set_property!(graph, edge, :edge_color, colors[get_property(graph, edge, :edge_membership, "enabled line")])
            # set_property!(graph, edge, :edge_size, get_property(graph, edge, :switch, false) ? 2 : 1)
        end
    end

    # for node in vertices(graph)
    #     node_membership = get_property(graph, node, :node_membership, "unloaded enabled bus")
    #     set_property!(graph, node, :node_color, colors[node_membership])
    #     set_property!(graph, node, :node_size, node_size_lims[1])
    #     if hasprop(graph, node, :active_power)
    #         active_powers = [(node, get_property(graph, node, :active_power, 0.0)) for node in vertices(graph) if hasprop(graph, node, :active_power)]
    #         reactive_powers = [(node, get_property(graph, node, :reactive_power, 0.0)) for node in vertices(graph) if hasprop(graph, node, :reactive_power)]
    #         pmin, pmax = length(active_powers) > 0 ? minimum(filter(!isnan,Float64[v[2] for v in active_powers])) : 0.0, length(active_powers) > 0 ? maximum(filter(!isnan,Float64[v[2] for v in active_powers])) : 0.0
    #         qmin, qmax = length(reactive_powers) > 0 ? minimum(filter(!isnan,Float64[v[2] for v in reactive_powers])) : 0.0, length(reactive_powers) > 0 ? maximum(filter(!isnan,Float64[v[2] for v in reactive_powers])) : 0.0
    #         if any(abs.([pmin, pmax, qmin, qmax]) .> 0)
    #                 amin, amax = minimum(filter(!isnan,Float64[pmin, qmin])), maximum(filter(!isnan,Float64[pmax, qmax]))
    #             for (node, value) in active_powers
    #                 set_property!(graph, node, :node_size, (value - amin) / (amax - amin) * (node_size_lims[2] - node_size_lims[1]) + node_size_lims[1])
    #             end
    #         end
    #     end
        #
        # if hasprop(graph, node, :load_status)
        #     load_status = get_property(graph, node, :load_status, 11)
        #     set_property!(graph, node, :node_color, occursin("disabled", node_membership) || occursin("unloaded", node_membership) ? colors[node_membership] : load_color_range[load_status])
        # end
    # end
end
