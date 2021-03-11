# Default plot attributes
const default_plot_attributes = Dict{Symbol, Any}(
  :gen_color => :blue,
  :bus_color => :green,
  :branch_color => :black,
  :connector_color => :gray,
  :dcline_color => :CadetBlue,
  :storage_color => :steelblue,
  :gen_size => 5e2,
  :bus_size => 5e2,
  :branch_size => 5,
  :connector_size => 3,
  :dcline_size => 5,
  :storage_size => 5e2,
  :width => 500,
  :height => 500,
  :gen_data => "ComponentType",
  :bus_data => "ComponentType",
  :branch_data => "ComponentType",
  :dcline_data => "ComponentType",
  :storage_data => "ComponentType",
  :gen_data_type => "nominal",
  :bus_data_type => "nominal",
  :branch_data_type => "nominal",
  :dcline_data_type => "nominal",
  :storage_data_type => "nominal",
);

# Returns a deepcopy of the default_plot_attributes, used to initialize plot_attributes in utils.jl
function copy_default_attributes()
  return deepcopy(default_plot_attributes);
end

# Dictionary of aliases of properties
# Aliases are replaced by their key in plot_attributes
# for example, nodecolor/markercolor/marker_color, edgecolor/edge_color/ec can be used to
# set nodecolor and edgecolor respectively
const attribute_aliases = Dict(
  :gen_color => [:gencolor, :generatorcolor, :generator_color],
  :bus_color => [:buscolor, :substationcolor, :substation_color],
  :branch_color => [:branchcolor, :transmissionlinecolor, :transmissionline_color,:transmission_line_color],
  :connector_color => [:connectorcolor],
  :storage_color => [:storagecolor, :batterycolor, :battery_color],
  :dcline_color => [:dclinecolor, :dc_line_color],
  :bus_size => [:bussize, :node_size],
  :gen_size => [:gensize, :node_size],
  :storage_size => [:storagesize, :node_size],
  :branch_size => [:branchsize, :line_size, :edge_size],
  :dcline_size => [:dclinesize, :line_size, :edge_size],
  :connector_size => [:connectorsize, :edge_size],
)

const _color_attributes = [ # color (String or Symbol) type parameters
  :gen_color, 
  :bus_color, 
  :branch_color, 
  :connector_color, 
  :storage_color, 
  :dcline_color
]
const _numeric_attributes = [ # numeric parameters
  :gen_size, 
  :bus_size, 
  :branch_size, 
  :connector_size, 
  :dcline_size, 
  :storage_size, 
  :width, 
  :height
]
const _label_attributes = [ # label (String or Symbol) type parameters
  :gen_data,
  :bus_data,
  :branch_data,
  :dcline_data,
  :storage_data,
  :gen_data_type,
  :bus_data_type,
  :branch_data_type,
  :dcline_data_type,
  :storage_data_type
]