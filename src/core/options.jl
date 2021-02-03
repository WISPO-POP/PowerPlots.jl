# Default plot attributes
const default_plot_attributes = Dict{Symbol, Any}(
  :gen_color => :blue,
  :bus_color => :green,
  :branch_color => :black,
  :connector_color => :gray,
  :dcline_color => :CadetBlue,
  :storage_color => :steelblue,
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
)