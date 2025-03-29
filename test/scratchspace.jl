
# Scratch space for testing development features
using TestEnv; TestEnv.activate()

using PowerPlots
using PowerModels
using PowerPlots, PowerModels
data = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
data = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5_strg.m")

################################################
## No code should be commited in this section ##
################################################


# pmg = PowerModelsGraph(data,[:bus],[:branch],[:gen,:load])

# data = layout_network(data; node_components=[:bus], edge_components=[:branch], connected_components=[:gen, :load])

# pmd= PowerModelsDataFrame(data)

# powerplot(data, connected_components=[:gen,:load,:storage])

# p = powerplot(data,
# bus_data=:index, bus_data_type=:quantitative,
# branch_data=:index, branch_data_type=:quantitative,
# gen_data=:index, gen_data_type=:quantitative,
# height=250, width=250, bus_size=100, gen_size=50, load_size=50,
# )


# powerplot(data; bus=(:color=>"orange"),
#                 gen=(:color=>:purple),
#                 branch=(:color=>"#AFAFAF"),
#                 load=(:color=>:black),
#                 width=500, height=300)


# p = powerplot(data,
#     # gen=[:data=>"pmax", :size=>200, :data_type=>"quantitative", :color=>["#232323","#AAFAFA"]],
#     # load=[:data=>"pd", :size=>500, :data_type=>"quantitative", :color=>["red","orange"]],
#     branch=[:show_flow=>true, :show_flow_legend=>true, :data=>"rate_a", :size=>3, :data_type=>"quantitative", :color=>["black","blue"]],
#     # bus=[:data=>"vmax", :size=>1000, :data_type=>"quantitative", :color=>["yellow","green"]],
#     width=300, height=300, parallel_edge_offset=0.05
# )

# powerplot(data)
# powerplot(data; bus=[:color=>:red], branch=[:color=>["blue", :green]])

# powerplot(data; show_flow_legend=true)
# powerplot(data; bus=[:data=>:ComponentType, :data_type=>:ordinal],
#         gen=[:data=>"ComponentType", :data_type=>"nominal"])
# # typeof([:a=>1,:b=>2])::Type{<:Vector{T}} where {T<:Pair}

# distribution networks
using PowerModelsDistribution
eng = PowerModelsDistribution.parse_file("$(joinpath(dirname(pathof(PowerModelsDistribution)), ".."))/test/data/opendss/trans_3w_center_tap.dss")

# ERROR parent component is always "bus", not "gen_bus" or "load_bus"

PMD = PowerModelsDataFrame(data);
powerplot(data)
PMD.components
powerplot(eng)


#### IS THE SOLUTION TO PROCESS THE FILES INTO A COMMON FORMAT FOR
# node names, (s,d) names, etc?
# now the parallel edges doesn't work for transformers...



using Plots
test_color_schemes=Dict{Symbol,Any}(
    :blues =>   colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#3182BD", Colors.colorant"#C6DBEF", length=5))),#["#$(Colors.hex(c))" for c in ColorSchemes.ColorScheme(range(Colors.colorant"#3182BD", Colors.colorant"#C6DBEF", length=5))],
    :greens =>  colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#31A354", Colors.colorant"#C7E9C0", length=5))),
    :oranges => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#E6550D", Colors.colorant"#FDD0A2", length=5))),
    :reds =>    colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#CB181D", Colors.colorant"#FCBBA1", length=5))),
    :purples => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#756BB1", Colors.colorant"#DADAEB", length=5))),
    :grays =>   colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#555555", Colors.colorant"#FFFFFF", length=5))),
    :browns =>  colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8C6D31", Colors.colorant"#E7CB94", length=5))),
    :pinks =>   colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#e7298a", Colors.colorant"#fbb3cc", length=5))),
    :yellows => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#ffc108", Colors.colorant"#ffef79", length=5))),
    :teal =>    colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#2a8482", Colors.colorant"#46e1d1", length=5))),
    :lime =>    colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8df33c", Colors.colorant"#c8ff87", length=5))),
    :violet =>  colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#8f3f8f", Colors.colorant"#d6a0d6", length=5))),
    :cyan =>    colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#00ffff", Colors.colorant"#99ffff", length=5))),
    :magenta => colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#ff00ff", Colors.colorant"#ff99ff", length=5))),
    :indigo =>  colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#4b0082", Colors.colorant"#9b59b6", length=5))),
    :cherry =>  colorscheme2array(ColorSchemes.ColorScheme(range(Colors.colorant"#ff0000", Colors.colorant"#ff9999", length=5))),
)


# investigate new color schemes
# using ColorSchemes, Colors
# ColorSchemes.ColorScheme([parse(Colorant, x) for x in test_color_schemes[:pinks]])
# ColorSchemes.ColorScheme([parse(Colorant, x) for x in test_color_schemes[:blues]])


begin
  p=plot()
  for (i,k) in enumerate(keys(test_color_schemes))
    scatter!(1:5, ones(5)*i, color=test_color_schemes[k], label="$k", ms=30, legend=false)

  end
  xlims!(0,6)
  ylims!(0,length(test_color_schemes)+1)
  p
end

################################################
