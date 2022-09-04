
# Code to create logo, using PowerPlots

using Pkg
using PowerPlots
using PowerModels
using PGLib
using Ipopt
using Setfield
using VegaLite
using OrderedCollections

case = pglib("case3_lmbd")

result = solve_ac_opf(case, Ipopt.Optimizer)
update_data!(case, result["solution"])
delete!(case["load"],"1")
# delete!(case["load"],"2")
delete!(case["gen"],"3")


case["bus"]["1"]["xcoord_1"] = 0.0
case["bus"]["1"]["ycoord_1"] = 0.0
case["bus"]["2"]["xcoord_1"] = 0.5
case["bus"]["2"]["ycoord_1"] = 1.0
case["bus"]["3"]["xcoord_1"] = 1.0
case["bus"]["3"]["ycoord_1"] = 0.0

case["gen"]["1"]["xcoord_1"] = -0.4
case["gen"]["1"]["ycoord_1"] = -0.2
case["gen"]["2"]["xcoord_1"] = 1.0
case["gen"]["2"]["ycoord_1"] = 0.7
case["load"]["2"]["xcoord_1"] = 0.1
case["load"]["2"]["ycoord_1"] = 1.1
case["load"]["3"]["xcoord_1"] = 1.4
case["load"]["3"]["ycoord_1"] = 0.1

p = powerplot(case, components=["bus","branch"], fixed=true, #,"gen","load"
    bus_color=["#9558B2","#389826","#CB3C33"],
    gen_color=["#389826","#CB3C33","#9558B2"],
    load_color=["#CB3C33","#9558B2","#389826"],
    branch_color="gray", bus_data=:index, gen_data=:index, load_data=:index,
    bus_size=10000,
    load_size=4000,
    gen_size=4000,
    edge_size=20,
    connector_dash=[10,10],
    flow_arrow_size_range=[0,50000],
    # flow_color=""
)

@set! p.config.legend=OrderedCollections.OrderedDict{String, Any}("disable"=>true)
# @set! p.background=OrderedCollections.OrderedDict{String, Any}("fillOpacity"=>0.1)
# when saving, this creates a solid black background.  Edit the figure in Inkscape to remove the white background.

save(joinpath(@__DIR__,"src","assets","logo.svg"),p)
