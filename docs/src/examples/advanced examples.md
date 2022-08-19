# Advanced Examples
These examples can be used as a basis for creating more complicated vizualizations.


## Powerflow
```@example
using PowerModels
using PowerModelsAnalytics
using PowerPlots
using ColorSchemes
using Setfield
using JuMP, Ipopt
case = parse_file("case14.m")
result = solve_ac_opf(case, optimizer_with_attributes(Ipopt.Optimizer, "print_level"=>0))
update_data!(case,result["solution"])

plot1 = powerplot(case,
                # bus_data=:vm,
                # bus_data_type=:quantitative,
                gen_data=:pg,
                gen_data_type=:quantitative,
                branch_data=:pt,
                branch_data_type=:quantitative,
                branch_color=["DimGray","red"],
                gen_color=["DimGray","red"]
)

plot1.layer[1]["transform"] = Dict{String, Any}[
    Dict("calculate"=>"abs(datum.pt)/datum.rate_a*100", "as"=>"branch_Percent_Loading"),
    Dict("calculate"=>"abs(datum.pt)", "as"=>"BranchPower")
]
plot1.layer[1]["layer"][1]["encoding"]["color"]["field"]="branch_Percent_Loading"
plot1.layer[1]["layer"][1]["encoding"]["color"]["title"]="Branch Utilization %"
plot1.layer[1]["layer"][1]["encoding"]["color"]["scale"]["domain"]=[0,100]
#plot1.layer[1]["layer"][1]["encoding"]["size"]=Dict("field"=>"BranchPower", "title"=>"Branch BaseMW", "type"=>"quantitative", "scale"=>Dict("range"=>[3,10]))


plot1.layer[4]["transform"] = Dict{String, Any}[
    Dict("calculate"=>"datum.pg/datum.pmax*100", "as"=>"gen_Percent_Loading"),
    Dict("calculate"=>"datum.pg", "as"=>"GenPower")
]
plot1.layer[4]["encoding"]["color"]["field"]="gen_Percent_Loading"
plot1.layer[4]["encoding"]["color"]["scale"]["domain"]=[0,100]
plot1.layer[4]["encoding"]["color"]["title"]="Gen Utilization %"
plot1.layer[4]["encoding"]["size"]=Dict("field"=>"GenPower", "title"=>"Gen BaseMW", "type"=>"quantitative", "scale"=>Dict("range"=>[300,1000]))

plot1.layer[1]["layer"][1]["encoding"]["color"]["legend"]=Dict("orient"=>"bottom-right", "offset"=>-30)
plot1.layer[4]["encoding"]["color"]["legend"]=Dict("orient"=>"bottom-right")

@set! plot1.resolve.scale.size=:independent
@set! plot1.resolve.scale.color=:shared

plot1
```

## Load Blocks
```@example
using PowerModels
using PowerModelsAnalytics
using PowerPlots
using ColorSchemes
using Setfield

case = parse_file("case14.m")
case["branch"]["10"]["br_status"] = 0
case["branch"]["16"]["br_status"] = 0
case["branch"]["17"]["br_status"] = 0

# Identify loadk blocks for all components
for (block_id, bus_ids) in identify_blocks(case)
    for bus_id in bus_ids
        case["bus"][bus_id]["block"]=block_id
    end
end
for (gen_id,gen) in case["gen"]
    gen["block"] = case["bus"][string(gen["gen_bus"])]["block"]
end
for (branch_id,branch) in case["branch"]
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    if case["bus"]["$(f_bus)"]["block"] == case["bus"]["$(t_bus)"]["block"]
        branch["block"] =  case["bus"]["$(f_bus)"]["block"]
    else
        branch["block"] = "damaged"
    end
end

color_range = colorscheme2array(ColorSchemes.colorschemes[:tableau_10])
color_range = [color_range[i] for i in[1,2,4,3]]
plot1 = powerplot(case; bus_data=:block, gen_data=:block, branch_data=:block, node_color=color_range, branch_color=color_range, show_flow=false)

@set! plot1.resolve.scale.color=:shared # share color scale for all components
plot1.layer[1]["layer"][1]["encoding"]["color"]["title"]="Load Blocks"
plot1.layer[2]["encoding"]["color"]["title"]="Load Blocks"
plot1.layer[3]["encoding"]["color"]["title"]="Load Blocks"
plot1.layer[4]["encoding"]["color"]["title"]="Load Blocks"


plot1
```
## Restoration Sequence

