
"Validates the given plot_attributes according to their type"
function _validate_plot_attributes!(plot_attributes::Dict{Symbol, Any})
    for attr in keys(plot_attributes)
      if !haskey(default_plot_attributes, attr)
        Memento.warn(_LOGGER, "Ignoring unexpected attribute $(repr(attr))")
      end
    end

    # validate color attributes
    for attr in _color_attributes
        color = plot_attributes[attr]
        if !(typeof(color) <: Union{String, Symbol, AbstractVector})
          Memento.warn(_LOGGER, "Color value for $(repr(attr)) should be given as symbol or string")
        else
          try
            if typeof(color) <: AbstractVector
                parse.(Colors.Colorant, color) # parses all colors as CSS color
            else
                parse(Colors.Colorant, color) # try to parse the color as a CSS color
                plot_attributes[attr] = [color] # package color into an array
            end
          catch e
            Memento.warn(_LOGGER, "Invalid color $(repr(color)) given for $(repr(attr))")
          end
        end
    end

    # validate numeric attributes
    for attr in _numeric_attributes
      value = plot_attributes[attr]
      if !(typeof(value) <: Union{Number, String})
        Memento.warn(_LOGGER, "Value for $(repr(attr)) should be given as a number or numeric String")
      elseif typeof(value) <: String
        try
            parse(Float64, value)
        catch e
            Memento.warn(_LOGGER, "Invalid number $(repr(value)) given for $(repr(attr))")
        end
      end
    end

    # validate data label attributes
    for attr in _label_attributes
      value = plot_attributes[attr]
      if !(typeof(value) <: Union{String, Symbol})
        Memento.warn(_LOGGER, "Value for $(repr(attr)) should be given as a String or Symbol")
      end
    end
end


"Checks that the given column plot_attributes[data_attr] exists in the data"
function _validate_data(data::DataFrames.DataFrame, data_column::Any, data_name::String)
    if !(typeof(data_column) <: Union{String, Symbol})
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
