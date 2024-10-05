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

default_plot_attributes = Dict{Symbol, Any}(
  :width => 500,
  :height => 500,
  :parallel_edge_offset=>0.05,
)

default_edge_attributes = Dict{Symbol, Any}(
  :color => color_schemes[:blues],
  :size => 5,
  :data => "ComponentType",
  :data_type => "nominal",
  :flow_color => :black,
  :flow_arrow_size_range=>[500,3000],
  :show_flow => false,
  :show_flow_legend => false,
)

default_connector_attributes = Dict{Symbol, Any}(
  :color => [:gray],
  :size => 3,
  :dash => [4, 4],
  :data => "ComponentType",
  :data_type => "nominal",
)

default_node_attributes = Dict{Symbol, Any}(
  :color => color_schemes[:greens],
  :size => 5e2,
  :data => "ComponentType",
  :data_type => "nominal",
)


const _color_attributes = [ # color (String or Symbol) type parameters
  :color,
]
const _numeric_attributes = [ # numeric parameters
  :size,
  :width,
  :height,
  :parallel_edge_offset,
]
const _label_attributes = [ # label (String or Symbol) type parameters
  :data,
  :data_type
]
const _boolean_attributes = [ # boolean type parameters
  :show_flow,
  :show_flow_legend,
]

