
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


pmg = PowerModelsGraph(data,[:bus],[:branch],[:gen,:load])

data = layout_network(data; node_components=[:bus], edge_components=[:branch], connected_components=[:gen, :load])

pmd= PowerModelsDataFrame(data)

powerplot(data, connected_components=[:gen,:load,:storage])

p = powerplot(data,
bus_data=:index, bus_data_type=:quantitative,
branch_data=:index, branch_data_type=:quantitative,
gen_data=:index, gen_data_type=:quantitative,
height=250, width=250, bus_size=100, gen_size=50, load_size=50,
)


powerplot(data; bus=(:color=>"orange"),
                gen=(:color=>:purple),
                branch=(:color=>"#AFAFAF"),
                load=(:color=>:black),
                width=500, height=300)


p = powerplot(data,
    # gen=[:data=>"pmax", :size=>200, :data_type=>"quantitative", :color=>["#232323","#AAFAFA"]],
    # load=[:data=>"pd", :size=>500, :data_type=>"quantitative", :color=>["red","orange"]],
    branch=[:show_flow=>true, :show_flow_legend=>true, :data=>"rate_a", :size=>3, :data_type=>"quantitative", :color=>["black","blue"]],
    # bus=[:data=>"vmax", :size=>1000, :data_type=>"quantitative", :color=>["yellow","green"]],
    width=300, height=300, parallel_edge_offset=0.05
)



typeof([:a=>1,:b=>2])::Type{<:Vector{T}} where {T<:Pair}

################################################