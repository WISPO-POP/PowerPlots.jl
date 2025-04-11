
"""
    `powerplot(
        case::Dict{String,<:Any};
        layout_algorithm=kamada_kawai,
        edge_components=[:branch],
        node_components=[:bus],
        connected_components=[:gen,:load],
        fixed=false,
        kwargs...)`

Create a plower plot. Check github repo for documentation on kwarg options.
"""
function powerplot(
    case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    edge_components=supported_edge_types,
    node_components=supported_node_types,
    connected_components=supported_connected_types,
    fixed=false,
    kwargs...)

    if InfrastructureModels.ismultinetwork(case)
        return _powerplot_mn(case; layout_algorithm, fixed, edge_components, node_components, connected_components, kwargs...)
    end

    # copy data for modification by plots
    data = deepcopy(case)

    # Create plot_atrributes by taking kwargs and updating default values.  If kwarg is doesn't exist in an defaults, give error
    plot_attributes = initialize_default_attributes(edge_components, node_components, connected_components)
    plot_attributes = apply_components_filters!(plot_attributes, edge_components, node_components, connected_components)
    plot_attributes = apply_kwarg_attributes!(plot_attributes; kwargs...)

    data = layout_network(case; layout_algorithm=layout_algorithm, fixed=fixed,
        node_components=plot_attributes[:node_components], edge_components=plot_attributes[:edge_components],
        connected_components=plot_attributes[:connected_components], kwargs...
    )

    # fix parallel branch coordinates
    offset_parallel_edges!(data, plot_attributes[:parallel_edge_offset], edge_types=edge_components)

    # remove_information!(data, invalid_keys)
    PMD = PowerModelsDataFrame(data)

    # Add color if missing from plot attributes
    add_color_attributes!(plot_attributes, PMD)

    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    # make the plots
    p = plot_base(data, plot_attributes)
    for comp_type in edge_components
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_edge(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end
    for comp_type in [:connector]
        if !(isempty(PMD.components[comp_type]))
            # _validate_data_type(plot_attributes[comp_type], :data_type)
            # _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_connector(PMD.components[comp_type], plot_attributes[comp_type])
        end
    end
    for comp_type in [node_components..., connected_components...]
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_node(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end
    return p
end

"""
    `powerplot!(
        plt_layer::VegaLite.VLSpec, case::Dict{String,<:Any};
        layout_algorithm=kamada_kawai,
        edge_components=[:branch],
        node_components=[:bus],
        connected_components=[:gen,:load],
        fixed=false,
        kwargs...)`

Create a plower plot, with a different VegaLite plot as the bottom layer of the plot.  Primarily
used to plot geographic map data underneath a power grid.
"""
function powerplot!(plt_layer::VegaLite.VLSpec, case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    edge_components=supported_edge_types,
    node_components=supported_node_types,
    connected_components=supported_connected_types,
    fixed=false,
    kwargs...)

    if InfrastructureModels.ismultinetwork(case)
        return _powerplot_mn!(plt_layer, case; layout_algorithm, fixed, edge_components, node_components, connected_components, kwargs...)
    end

    # copy data for modification by plots
    data = deepcopy(case)

    # Create plot_atrributes by taking kwargs and updating default values.  If kwarg is doesn't exist in an defaults, give error
    plot_attributes = initialize_default_attributes(edge_components, node_components, connected_components)
    plot_attributes = apply_components_filters!(plot_attributes, edge_components, node_components, connected_components)
    plot_attributes = apply_kwarg_attributes!(plot_attributes; kwargs...)

    data = layout_network(case; layout_algorithm=layout_algorithm, fixed=fixed, node_components=node_components,
        edge_components=edge_components, connected_components=connected_components, kwargs...)

    # fix parallel branch coordinates
    offset_parallel_edges!(data, plot_attributes[:parallel_edge_offset], edge_types=edge_components)

    # remove_information!(data, invalid_keys)
    PMD = PowerModelsDataFrame(data)

    # Add color if missing from plot attributes
    add_color_attributes!(plot_attributes, PMD)

    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types


    # make the plots
    p = plot_base(data, plot_attributes)

    # add layer
    p = p + plt_layer

    for comp_type in edge_components
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_edge(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end
    for comp_type in [:connector]
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_connector(PMD.components[comp_type], plot_attributes[comp_type])
        end
    end
    for comp_type in [node_components..., connected_components...]
        if !(isempty(PMD.components[comp_type]))
            plot_attributes[comp_type]
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_node(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end
    return p
end


function _powerplot_mn(case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    edge_components=supported_edge_types,
    node_components=supported_node_types,
    connected_components=supported_connected_types,
    fixed=false,
    kwargs...)

    # copy data for modification by plots
    data = deepcopy(case)

    # Create plot_attributes by taking kwargs and updating default values.  If kwarg is doesn't exist in an defaults, give error
    plot_attributes = initialize_default_attributes(edge_components, node_components, connected_components)
    plot_attributes = apply_components_filters!(plot_attributes, edge_components, node_components, connected_components)
    plot_attributes = apply_kwarg_attributes!(plot_attributes; kwargs...)


    # fix parallel branch coordinates
    for (nwid, net) in data["nw"]
        data["nw"][nwid] = layout_network(net; layout_algorithm=layout_algorithm, fixed=fixed, node_components=node_components,
            edge_components=edge_components, connected_components=connected_components, kwargs...)

        offset_parallel_edges!(data["nw"][nwid], plot_attributes[:parallel_edge_offset], edge_types=edge_components)
    end

    PMD = PowerModelsDataFrame(data)

    # Add color if missing from plot attributes
    add_color_attributes!(plot_attributes, PMD)

    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types
    # make the plots
    p = plot_base_mn(data, plot_attributes)
    for comp_type in edge_components
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_edge(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end
    for comp_type in [:connector]
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_connector(PMD.components[comp_type], plot_attributes[comp_type])
        end
    end
    for comp_type in [node_components..., connected_components...]
        if !(isempty(PMD.components[comp_type]))
            plot_attributes[comp_type]
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_node(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end

    for i in keys(p.layer)  # add filter for nwid on each layer
        p.layer[i]["transform"] = OrderedCollections.OrderedDict{String,Any}[OrderedCollections.OrderedDict("filter" => "datum.nw_id == nwid")]
    end

    return p
end


function _powerplot_mn!(plt_layer::VegaLite.VLSpec, case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    edge_components=supported_edge_types,
    node_components=supported_node_types,
    connected_components=supported_connected_types,
    fixed=false,
    kwargs...)

    # copy data for modification by plots
    data = deepcopy(case)

    # Create plot_atrributes by taking kwargs and updating default values.  If kwarg is doesn't exist in an defaults, give error
    plot_attributes = initialize_default_attributes(edge_components, node_components, connected_components)
    plot_attributes = apply_components_filters!(plot_attributes, edge_components, node_components, connected_components)
    plot_attributes = apply_kwarg_attributes!(plot_attributes; kwargs...)


    # fix parallel branch coordinates
    for (nwid, net) in data["nw"]
        data["nw"][nwid] = layout_network(net; layout_algorithm=layout_algorithm, fixed=fixed, node_components=node_components,
            edge_components=edge_components, connected_components=connected_components, kwargs...)

        offset_parallel_edges!(data["nw"][nwid], plot_attributes[:parallel_edge_offset], edge_types=edge_components)
    end

    # remove_information!(data, invalid_keys)
    PMD = PowerModelsDataFrame(data)

    # Add color if missing from plot attributes
    add_color_attributes!(plot_attributes, PMD)

    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    # make the plots
    p = plot_base_mn(data, plot_attributes)

    # add layers
    old_layer_count = 1 # used to only reference new powerplot layers in logic below
    if hasproperty(plt_layer, :layer)
        old_layer_count = length(keys(plt_layer.layer))
    end
    p = p + plt_layer

    for comp_type in edge_components
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_edge(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end
    for comp_type in [:connector]
        if !(isempty(PMD.components[comp_type]))
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_connector(PMD.components[comp_type], plot_attributes[comp_type])
        end
    end
    for comp_type in [node_components..., connected_components...]
        if !(isempty(PMD.components[comp_type]))
            plot_attributes[comp_type]
            _validate_data_type(plot_attributes[comp_type], :data_type)
            _validate_data(PMD.components[comp_type], plot_attributes[comp_type][:data], comp_type)
            p = p + plot_node(PMD.components[comp_type], comp_type, plot_attributes[comp_type])
        end
    end

    for i in keys(p.layer)  # add filter for nwid on each powerplot layer
        if i > old_layer_count
            p.layer[i]["transform"] = OrderedCollections.OrderedDict{String,Any}[OrderedCollections.OrderedDict("filter" => "datum.nw_id == nwid")]
        end
    end

    return p
end


function plot_base(case::Dict{String,<:Any}, plot_attributes::Dict{Symbol,Any})
    return p = VegaLite.@vlplot(
        width = plot_attributes[:width],
        height = plot_attributes[:height],
        config = {view = {stroke = nothing}},
        x = {axis = nothing},
        y = {axis = nothing},
        resolve = {
            scale = {
                color = :independent
            }
        },
    )
end


function plot_base_mn(case::Dict{String,Any}, plot_attributes::Dict{Symbol,Any})
    return p = VegaLite.@vlplot(
        width = plot_attributes[:width],
        height = plot_attributes[:height],
        config = {view = {stroke = nothing}},
        x = {axis = nothing},
        y = {axis = nothing},
        resolve = {
            scale = {
                color = :independent
            }
        },
        params = [{
            name = "nwid",
            value = minimum(parse.(Int, collect(keys(case["nw"])))),
            bind = {
                input = "range",
                min = minimum(parse.(Int, collect(keys(case["nw"])))),
                max = maximum((parse.(Int, collect(keys(case["nw"]))))),
                step = 1}
        }],
    )
end

function plot_edge(edge_data::DataFrames.DataFrame, comp_type::Symbol, plot_attributes::Dict{Symbol,Any})
    flow_legend = true
    if plot_attributes[:show_flow_legend] in [nothing, false, :false, "false", :no, "no"]
        flow_legend = nothing
    end
    flow_opacity = 1.0
    if plot_attributes[:show_flow] in [nothing, false, :false, "false", :no, "no"]
        flow_opacity = 0.0
    end

    return VegaLite.@vlplot(
        data = edge_data,
        layer = [
            {
                mark = {
                    :rule,
                    tooltip = ("content" => "data"),
                    opacity = 1.0,
                },
                x = {:xcoord_1, type = "quantitative"},
                x2 = {:xcoord_2, type = "quantitative"},
                y = {:ycoord_1, type = "quantitative"},
                y2 = {:ycoord_2, type = "quantitative"},
                size = {value = plot_attributes[:size]},
                color = {
                    field = plot_attributes[:data],
                    type = plot_attributes[:data_type],
                    title = ucfirst(string(comp_type)),
                    scale = {
                        range = plot_attributes[:color]
                    },
                },
            },
            {
                transform = [
                    {
                        calculate = "(datum.xcoord_1 + datum.xcoord_2)/2",
                        as = "mid_x"
                    },
                    {
                        calculate = "(datum.ycoord_1 + datum.ycoord_2)/2",
                        as = "mid_y"
                    },
                    {
                        calculate = "180*(if(datum.pf >= 0,
                              atan2(datum.xcoord_2 - datum.xcoord_1, datum.ycoord_2 - datum.ycoord_1),
                              atan2(datum.xcoord_1 - datum.xcoord_2, datum.ycoord_1 - datum.ycoord_2)
                          ))/PI",
                        as = "angle"
                    },
                    {
                        calculate = "if(isValid(datum.pt), abs(datum.pt), 0.0)",
                        as = "power"
                    }
                ],
                mark = {
                    :point,
                    shape = :wedge,
                    filled = true,
                    tooltip = ("content" => "data"),
                    opacity = flow_opacity,
                    color = plot_attributes[:flow_color],
                },
                x = {:mid_x, type = "quantitative"},
                y = {:mid_y, type = "quantitative"},
                size = {:power, scale = {range = plot_attributes[:flow_arrow_size_range]}, type = "quantitative", legend = flow_legend},
                angle = {:angle, scale = {domain = [0, 360], range = [0, 360]}, type = "quantitative"}
            }
        ]
    )
end

function plot_node(node_data::DataFrames.DataFrame, comp_type::Symbol, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        data = node_data,
        mark = {
            :circle,
            "tooltip" = ("content" => "data"),
            opacity = 1.0,
        },
        x = {:xcoord_1, type = "quantitative"},
        y = {:ycoord_1, type = "quantitative"},
        size = {value = plot_attributes[:size]},
        color = {
            field = plot_attributes[:data],
            type = plot_attributes[:data_type],
            title = ucfirst(string(comp_type)),
            scale = {
                range = plot_attributes[:color]
            },
        },
    )
end

function plot_connector(connector_data::DataFrames.DataFrame, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        mark = {
            :rule,
            "tooltip" = ("content" => "data"),
            opacity = 1.0,
        },
        data = connector_data,
        x = {:xcoord_1, type = "quantitative"},
        x2 = {:xcoord_2, type = "quantitative"},
        y = {:ycoord_1, type = "quantitative"},
        y2 = {:ycoord_2, type = "quantitative"},
        size = {value = plot_attributes[:size]},
        strokeDash = {value = plot_attributes[:dash]},
        color = {
            field = "ComponentType",
            type = "nominal",
            title = "Connector",
            scale = {
                range = plot_attributes[:color]
            },
        },
    )
end
