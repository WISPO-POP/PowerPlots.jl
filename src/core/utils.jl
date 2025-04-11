

function initialize_default_attributes(edge_components, node_components, connected_components)
    plot_attributes = deepcopy(default_plot_attributes)
    for comp_type in edge_components
        plot_attributes[comp_type] = deepcopy(default_edge_attributes)
    end
    for comp_type in [node_components..., connected_components...]
        plot_attributes[comp_type] = deepcopy(default_node_attributes)
    end
    plot_attributes[:connector] = deepcopy(default_connector_attributes)
    return plot_attributes
end


function add_color_attributes!(
    plot_attributes::Dict,
    PMD::PowerModelsDataFrame,
)
    color_index = 1
    for comp_type in [
            plot_attributes[:node_components]...,
            plot_attributes[:edge_components]...,
            plot_attributes[:connected_components]...
        ]
        if !(isempty(PMD.components[comp_type]))
            if isnothing(plot_attributes[comp_type][:color])
                plot_attributes[comp_type][:color] = color_schemes[component_color_order[color_index]]
                color_index += 1
            end
        else
            plot_attributes[comp_type][:color] = "black"
        end
    end
    return plot_attributes
end



function apply_components_filters!(plot_attributes::AbstractDict,
    node_components::Union{Symbol, Tuple, AbstractArray{<:Any,1}},
    edge_components::Union{Symbol, Tuple, AbstractArray{<:Any,1}},
    connected_components::Union{Symbol, Tuple, AbstractArray{<:Any,1}},
    )

    if eltype(node_components) != Symbol
        Memento.error(_LOGGER, "node_components must be a Symbol, Tuple of Symbols, or Array of Symbols")
    end
    if eltype(edge_components) != Symbol
        Memento.error(_LOGGER, "edge_components must be a Symbol, Tuple of Symbols, or Array of Symbols")
    end
    if eltype(connected_components) != Symbol
        Memento.error(_LOGGER, "connected_components must be a Symbol, Tuple of Symbols, or Array of Symbols")
    end

    plot_attributes[:edge_components] = Symbol[i for i in node_components]
    plot_attributes[:node_components] = Symbol[i for i in edge_components]
    plot_attributes[:connected_components] = Symbol[i for i in connected_components]

    return plot_attributes
end

function apply_kwarg_attributes!(plot_attributes::Dict,;kwargs...)
    for (var, val) in kwargs
        if !( var in plot_attributes[:edge_components] ||
              var in plot_attributes[:node_components] ||
              var in plot_attributes[:connected_components]
            )
            process_plot_attributes!(plot_attributes, var, val)
        else
            process_comp_attributes!(plot_attributes, var, val)
        end
    end
    return plot_attributes
end

function process_plot_attributes!(plot_attributes, k, v)
    if k in keys(default_plot_attributes)
        plot_attributes[k] = v
    else
        Memento.warn(_LOGGER, "Ignoring unexpected attribute $(repr(k))")
    end
    return plot_attributes
end

function process_comp_attributes!(plot_attributes, var, vals)
    for (k,v) in vals #zip(keys(vals), vals)
        if var in plot_attributes[:edge_components]
            if k in keys(default_edge_attributes)
                plot_attributes[var][k] = v
            else
                Memento.warn(_LOGGER, "Ignoring unexpected edge attribute $(repr(k))")
            end
        elseif var in plot_attributes[:node_components]
            if k in keys(default_node_attributes)
                plot_attributes[var][k] = v
            else
                Memento.warn(_LOGGER, "Ignoring unexpected node attribute $(repr(k))")
            end
        elseif var in plot_attributes[:connected_components]
            if k in keys(default_node_attributes)
                plot_attributes[var][k] = v
            else
                Memento.warn(_LOGGER, "Ignoring unexpected connected component attribute $(repr(k))")
            end
        elseif var ==:connector
            if k in keys(default_connector_attributes)
                plot_attributes[var][k] = v
            else
                Memento.warn(_LOGGER, "Ignoring unexpected connector attribute $(repr(k))")
            end
        else
            Memento.warn(_LOGGER, "Ignoring unexpected component type $(repr(var))")
        end
    end
    return plot_attributes
end


"Convert a color scheme `cs` into an array of string hex colors, usable by VegaLite"
function colorscheme2array(cs::ColorSchemes.ColorScheme)
    return a = ["#$(Colors.hex(c))" for c in cs]
end


function ucfirst(s::AbstractString)
    return uppercase(s[1]) * s[2:end]
end