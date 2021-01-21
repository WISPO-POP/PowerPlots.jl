# Default plot attributes
const default_plot_attributes = Dict{Symbol, Any}(
  :nodecolor => :blue,
  :edgecolor => :black
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
  :nodecolor => [:marker_color, :markercolor],
  :edgecolor => [:edge_color, :ec]
)