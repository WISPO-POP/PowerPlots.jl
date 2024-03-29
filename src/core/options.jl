# Default Color Schemes
# catergory 20b and 20c used as reference
const color_schemes=Dict{Symbol,Any}(
    :blues => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#3182BD", Colors.colorant"#C6DBEF", length=5))),#["#$(Colors.hex(c))" for c in ColorSchemes.ColorScheme(range(Colors.colorant"#3182BD", Colors.colorant"#C6DBEF", length=5))],
    :greens => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#31A354", Colors.colorant"#C7E9C0", length=5))),
    :oranges => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#E6550D", Colors.colorant"#FDD0A2", length=5))),
    :reds => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#CB181D", Colors.colorant"#FCBBA1", length=5))),
    :purples => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#756BB1", Colors.colorant"#DADAEB", length=5))),
    :grays => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#555555", Colors.colorant"#FFFFFF", length=5))),
    :yellows => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8C6D31", Colors.colorant"#E7CB94", length=5))),
)


# Default plot attributes
default_plot_attributes = Dict{Symbol, Any}(
  :gen_color => color_schemes[:oranges],
  :bus_color => color_schemes[:greens],
  :load_color => color_schemes[:reds],
  :branch_color => color_schemes[:blues],
  :switch_color => color_schemes[:grays],
  :transformer_color => color_schemes[:yellows],
  :connector_color => [:gray],
  :dcline_color => color_schemes[:purples],
  :storage_color => color_schemes[:oranges],
  :flow_color => :black,
  :gen_size => 2e2,
  :bus_size => 5e2,
  :load_size => 2e2,
  :branch_size => 5,
  :switch_size => 5,
  :transformer_size => 5,
  :connector_size => 3,
  :dcline_size => 5,
  :storage_size => 2e2,
  :width => 500,
  :height => 500,
  :gen_data => "ComponentType",
  :bus_data => "ComponentType",
  :load_data => "ComponentType",
  :branch_data => "ComponentType",
  :switch_data => "ComponentType",
  :transformer_data => "ComponentType",
  :connector_data => "ComponentType",
  :dcline_data => "ComponentType",
  :storage_data => "ComponentType",
  :gen_data_type => "nominal",
  :bus_data_type => "nominal",
  :load_data_type => "nominal",
  :branch_data_type => "nominal",
  :switch_data_type => "nominal",
  :transformer_data_type => "nominal",
  :dcline_data_type => "nominal",
  :storage_data_type => "nominal",
  :show_flow => false,
  :show_flow_legend => false,
  :flow_arrow_size_range=>[500,3000],
  :parallel_edge_offset => 0.05,
  :connector_dash=>[4,4],
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
  :gen_color => [:gencolor, :generatorcolor, :generator_color, :node_color],
  :bus_color => [:buscolor, :substationcolor, :substation_color, :node_color],
  :load_color => [:loadcolor, :demandcolor, :demand_color, :node_color],
  :branch_color => [:branchcolor, :transmissionlinecolor, :transmissionline_color,:transmission_line_color, :edge_color],
  :switch_color => [:switchcolor, :edge_color],
  :transformer_color => [:transformercolor, :edge_color],
  :connector_color => [:connectorcolor, :edge_color],
  :storage_color => [:storagecolor, :batterycolor, :battery_color, :node_color],
  :dcline_color => [:dclinecolor, :dc_line_color, :edge_color],
  :bus_size => [:bussize, :node_size],
  :gen_size => [:gensize, :node_size],
  :load_size => [:loadsize, :node_size],
  :storage_size => [:storagesize, :node_size],
  :branch_size => [:branchsize, :line_size, :edge_size],
  :switch_size => [:switchsize, :edge_size],
  :transformer_size => [:transformersize, :edge_size],
  :dcline_size => [:dclinesize, :line_size, :edge_size],
  :connector_size => [:connectorsize, :edge_size],
  :flow_arrow_size_range =>[:flow_size, :flowsize, :arrow_size, :arrowsize],
  :flow_color => [:flowcolor, :arrow_color, :arrowcolor],
  :show_flow => [:flow, :showflow, :arrows, :show_arrows, :showarrows, :flows, :show_flows, :showflows],
  :show_flow_legend => [:flowlegend, :flow_legend, :arrowlegend, :arrow_legend, :show_arrow_legend],
)

const _color_attributes = [ # color (String or Symbol) type parameters
  :gen_color,
  :bus_color,
  :load_color,
  :branch_color,
  :connector_color,
  :switch_color,
  :transformer_color,
  :storage_color,
  :dcline_color,
  :flow_color
]
const _numeric_attributes = [ # numeric parameters
  :gen_size,
  :bus_size,
  :load_size,
  :branch_size,
  :connector_size,
  :switch_size,
  :transformer_size,
  :dcline_size,
  :storage_size,
  :width,
  :height,
  :parallel_edge_offset,
]
const _label_attributes = [ # label (String or Symbol) type parameters
  :gen_data,
  :bus_data,
  :load_data,
  :branch_data,
  :dcline_data,
  :switch_data,
  :transformer_data,
  :storage_data,
  :gen_data_type,
  :bus_data_type,
  :branch_data_type,
  :switch_data_type,
  :transformer_data_type,
  :dcline_data_type,
  :storage_data_type
]
const _boolean_attributes = [ # boolean type parameters
  :show_flow,
  :show_flow_legend,
]
