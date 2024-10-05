
"Validates the given plot_attributes according to their type"
function _validate_plot_attributes!(plot_attributes::Dict{Symbol, Any})
  for (k,v) in plot_attributes
    _validate_plot_attributes!(plot_attributes, k,v)
  end
end

"Validates the given plot_attributes according to their type"
function _validate_plot_attributes!(plot_attributes::Dict{Symbol,Any}, k::Symbol, v::Dict{Symbol,Any})
  for (k1,v1) in v
    _validate_plot_attributes!(v, k1,v1)
  end
end

"Validates the given plot_attributes according to their type"
function _validate_plot_attributes!(plot_attributes::Dict{Symbol,Any}, attr::Symbol, v::Any)
  if attr in _color_attributes
    _validate_color_attribute!(plot_attributes, attr, v)
  elseif attr in _numeric_attributes
    _validate_numeric_attribute!(plot_attributes, attr, v)
  elseif attr in _label_attributes
    _validate_label_attribute!(plot_attributes, attr, v)
  elseif attr in _boolean_attributes
    _validate_boolean_attribute!(plot_attributes, attr, v)
  end
end

function _validate_color_attribute!(plot_attributes::Dict{Symbol,Any}, attr::Symbol, v::Any)
  if !(typeof(v) <: Union{String, Symbol, AbstractVector})
    Memento.warn(_LOGGER, "Color value for $(repr(attr)) should be given as symbol or string")
  else
    try
      if typeof(v) <: AbstractVector
        parse.(Colors.Colorant, v) # parses all colors as CSS color
      else
        parse(Colors.Colorant, v) # try to parse the color as a CSS color
        plot_attributes[attr] = [v] # package color into an array
      end
    catch e
      Memento.warn(_LOGGER, "Invalid color $(repr(v)) given for $(repr(attr))")
    end
  end
end

function _validate_numeric_attribute!(plot_attributes::Dict{Symbol,Any}, attr::Symbol, v::Any)
  if !(typeof(v) <: Union{Number, String})
    Memento.warn(_LOGGER, "Value for $(repr(attr)) should be given as a number or numeric String")
  elseif typeof(v) <: String
    try
      parse(Float64, v)
    catch e
      Memento.warn(_LOGGER, "Invalid number $(repr(v)) given for $(repr(attr))")
    end
  end
end

function _validate_label_attribute!(plot_attributes::Dict{Symbol,Any}, attr::Symbol, v::Any)
  if !(typeof(v) <: Union{String, Symbol})
    Memento.warn(_LOGGER, "Value for $(repr(attr)) should be given as a String or Symbol")
  end
end

function _validate_boolean_attribute!(plot_attributes::Dict{Symbol,Any}, attr::Symbol, v::Any)
  if !(typeof(v) <: Bool)
    Memento.warn(_LOGGER, "Value for $(repr(attr)) should be given as a Bool")
  end
end

"Checks that the given column plot_attributes[data_attr] exists in the data"
function _validate_data(data::DataFrames.DataFrame, data_column::Any, data_name::Symbol)
    if !(typeof(data_column) <: Union{String, Symbol})
      Memento.warn(_LOGGER, "Value for $(repr(attr)) should be given as a String or Symbol")
      return
    end
    if !(data_column in names(data) || data_column in propertynames(data))
        Memento.warn(_LOGGER, "Data column $(repr(data_column)) does not exist for $(data_name)")
    end
end

"Checks that the given data type attribute is a valid VegaLite data type"
function _validate_data_type(plot_attributes::Dict{Symbol, Any}, attr::Symbol)
    valid_types = Set([:quantitative, :temporal, :ordinal, :nominal, :geojson])
    data_type = plot_attributes[attr]
    if !(Symbol(data_type) in valid_types)
        Memento.warn(_LOGGER, "Data type $(repr(data_type)) not a valid VegaLite data type")
    end
end
