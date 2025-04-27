# Default Color Schemes
color_schemes = Dict{Symbol,Any}(
    :blues => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#3182BD", Colors.colorant"#C6DBEF", length=5))),#["#$(Colors.hex(c))" for c in ColorSchemes.ColorScheme(range(Colors.colorant"#3182BD", Colors.colorant"#C6DBEF", length=5))],
    :greens => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#31A354", Colors.colorant"#C7E9C0", length=5))),
    :oranges => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#E6550D", Colors.colorant"#FDD0A2", length=5))),
    :reds => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#CB181D", Colors.colorant"#FCBBA1", length=5))),
    :purples => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#756BB1", Colors.colorant"#DADAEB", length=5))),
    :grays => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#555555", Colors.colorant"#FFFFFF", length=5))),
    :browns => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8C6D31", Colors.colorant"#E7CB94", length=5))),
    :pinks => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#e7298a", Colors.colorant"#fbb3cc", length=5))),
    :yellows => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#ffc108", Colors.colorant"#ffef79", length=5))),
    :teal => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#2a8482", Colors.colorant"#46e1d1", length=5))),
    :lime => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8df33c", Colors.colorant"#c8ff87", length=5))),
    :violet => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8f3f8f", Colors.colorant"#d6a0d6", length=5))),
    :cyan => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#00ffff", Colors.colorant"#99ffff", length=5))),
    :magenta => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#ff00ff", Colors.colorant"#ff99ff", length=5))),
    :indigo => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#4b0082", Colors.colorant"#9b59b6", length=5))),
    :cherry => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#ff0000", Colors.colorant"#ff9999", length=5))),
)

component_color_order = Dict{Int,Symbol}(
    1 => :blues,
    2 => :greens,
    3 => :oranges,
    4 => :reds,
    5 => :purples,
    6 => :browns,
    7 => :pinks,
    8 => :yellows,
    9 => :lime,
    10 => :violet,
    11 => :cyan,
    12 => :magenta,
    13 => :indigo,
    14 => :cherry,
    15 => :teal,
    16 => :grays,
)


default_plot_attributes = Dict{Symbol,Any}(
    :width => 500,
    :height => 500,
    :parallel_edge_offset => 0.05,
    :node_components => supported_node_types,
    :edge_components => supported_edge_types,
    :connected_components => supported_connected_types,
)

default_edge_attributes = Dict{Symbol,Any}(
    :color => nothing,
    :size => 5,
    :data => "ComponentType",
    :data_type => "nominal",
    :flow_color => :black,
    :flow_arrow_size_range => [500, 3000],
    :show_flow => false,
    :show_flow_legend => false,
    :hover => nothing
)

default_connector_attributes = Dict{Symbol,Any}(
    :color => [:gray],
    :size => 3,
    :dash => [4, 4],
    :data => "ComponentType",
    :data_type => "nominal",
    :hover => nothing
)

default_node_attributes = Dict{Symbol,Any}(
    :color => nothing,
    :size => 5e2,
    :data => "ComponentType",
    :data_type => "nominal",
    :hover => nothing
)

default_layout_attributes = Dict{Symbol,Any}(
    :fixed => false,
    :layout_algorithm => "spring",
    :connector_weight => 0.5,
    :edge_weight => 1.0,
    :node_weight => 1.0,
    :tol => 0.01,
    :iterations => 500,
    :K => 1.0,
    :C => 0.2,
    :initialtemp=>2.0,
    :nlist => [[1]],
    :abstols => 0.0,
    :reltols => 10e-6,
    :abstolx => 10e-6,
    :weights => Array{Float64}(undef, 0, 0),
    :uncon_dist=>1,
    :nodeweights => Float64[],
    :cols=>:auto,
    :dx=>1.0,
    :dy=>-1.0,
    :skip => Tuple{Int,Int}[],
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

