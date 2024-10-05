

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

function apply_kwarg_attributes!(plot_attributes::Dict; kwargs...)
    for (k,v) in kwargs
      _apply_kwarg_attributes!(plot_attributes, k, v)
    end
end

function _apply_kwarg_attributes!(plot_attributes::AbstractDict, k::Symbol, v::Any)
  if !haskey(plot_attributes, k)
    Memento.warn(_LOGGER, "Ignoring unexpected attribute $(repr(k))")
  end
  plot_attributes[k] = v
end

function _apply_kwarg_attributes!(plot_attributes::AbstractDict, k::Symbol, v::AbstractVector)
  for (k1,v1) in v
    if !haskey(plot_attributes[k], k1)
      Memento.warn(_LOGGER, "Ignoring unexpected attribute $(repr(k1)) for component $(repr(k))")
    end
    plot_attributes[k][k1] = v1
  end
end


"Convert a color scheme `cs` into an array of string hex colors, usable by VegaLite"
function colorscheme2array(cs::ColorSchemes.ColorScheme)
    return a = ["#$(Colors.hex(c))" for c in cs]
end


function ucfirst(s::AbstractString)
    return uppercase(s[1]) * s[2:end]
end