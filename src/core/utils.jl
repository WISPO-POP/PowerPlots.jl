

function initialize_default_attributes(node_components, edge_components, connected_components)
    plot_attributes = deepcopy(default_plot_attributes)
    for comp_type in edge_components
        plot_attributes[Symbol(comp_type)] = deepcopy(default_edge_attributes)
    end
    for comp_type in [node_components..., connected_components...]
        plot_attributes[Symbol(comp_type)] = deepcopy(default_node_attributes)
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
    node_components::AbstractVector{<:Any},
    edge_components::AbstractVector{<:Any},
    connected_components::AbstractVector{<:Any},
    )
    if eltype(node_components) != Symbol
        node_components = Symbol.(node_components)
    end
    if eltype(edge_components) != Symbol
        edge_components = Symbol.(edge_components)
    end
    if eltype(connected_components) != Symbol
        connected_components = Symbol.(connected_components)
    end

    plot_attributes[:node_components] = Symbol[i for i in node_components]
    plot_attributes[:connected_components] = Symbol[i for i in connected_components]
    plot_attributes[:edge_components] = Symbol[i for i in edge_components]

    return plot_attributes
end

function apply_kwarg_attributes!(plot_attributes::Dict; kwargs...)
    for (k, v) in kwargs
        if !( k in plot_attributes[:edge_components] ||
              k in plot_attributes[:node_components] ||
              k in plot_attributes[:connected_components] ||
              k == :connector
            )
            process_plot_attributes!(plot_attributes, k, v)
        else
            process_comp_attributes!(plot_attributes, k, v)
        end
    end
    return plot_attributes
end

function process_plot_attributes!(plot_attributes::AbstractDict, k::Symbol, v::Any)
    if k in keys(default_plot_attributes) || k in keys(default_layout_attributes)
        plot_attributes[k] = v
    else
        Memento.warn(_LOGGER, "Ignoring unexpected attribute $(repr(k))")
    end
    return plot_attributes
end

function process_comp_attributes!(plot_attributes::AbstractDict, comp_type::Symbol, comp_attributes::Tuple)
    for (k,v) in comp_attributes
        _apply_comp_attributes!(plot_attributes, comp_type, k, v)
    end
    return plot_attributes
end

function process_comp_attributes!(plot_attributes::AbstractDict, comp_type::Symbol, comp_attribute::Pair)
    (k,v) = comp_attribute
    _apply_comp_attributes!(plot_attributes, comp_type, k, v)
    return plot_attributes
end

function _apply_comp_attributes!(plot_attributes::AbstractDict, comp_type::Symbol, k::Symbol, v::Any)
    if comp_type in plot_attributes[:edge_components]
        if k in keys(default_edge_attributes)
            plot_attributes[comp_type][k] = v
        else
            Memento.warn(_LOGGER, "Ignoring unexpected edge attribute $(repr(k))")
        end
    elseif comp_type in plot_attributes[:node_components]
        if k in keys(default_node_attributes)
            plot_attributes[comp_type][k] = v
        else
            Memento.warn(_LOGGER, "Ignoring unexpected node attribute $(repr(k))")
        end
    elseif comp_type in plot_attributes[:connected_components]
        if k in keys(default_node_attributes)
            plot_attributes[comp_type][k] = v
        else
            Memento.warn(_LOGGER, "Ignoring unexpected connected component attribute $(repr(k))")
        end
    elseif comp_type ==:connector
        if k in keys(default_connector_attributes)
            plot_attributes[comp_type][k] = v
        else
            Memento.warn(_LOGGER, "Ignoring unexpected connector attribute $(repr(k))")
        end
    else
        Memento.warn(_LOGGER, "Ignoring unexpected component type $(repr(comp_type))")
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