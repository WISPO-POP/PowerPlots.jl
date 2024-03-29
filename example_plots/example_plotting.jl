
using PowerModels, PGLib, PowerPlots, Ipopt
using Colors:  @colorant_str


## Plot Network Status
mp = Dict{String,Any}(
    "active_line" => Dict(:color => :darkgreen, :size => 6),
    "inactive_line" => Dict(:color => :red, :size => 6),
    "active_bus" => Dict(:color => :green, :size => 15),
    "active_bus_load_shed" => Dict(:color => :orange, :size => 10),
    "inactive_bus" => Dict(:color => :red, :size => 15),
    "active_gen" => Dict(:color => :green, :size => 15),
    "inactive_gen" => Dict(:color => :red, :size => 15),
    "connector" => Dict(:color => colorant"lightgrey", :size => 2, :style => :dash)
)
case = pglib("case14_ieee")

inactive_devices = Dict("bus" =>  1:5, "gen" => 1:3, "branch" => 1:9)
for (item_type, ids) in inactive_devices
    for id in ids
        case[item_type]["$(id)"][pm_component_status[item_type]] = pm_component_status_inactive[item_type]
    end
end

plot_network_status(case; filename="network_status.png", plot_size=(800,800), membership_properties=mp)


## Plot Power Flow
mp=Dict{String,Any}(
            "max_power" => Dict(:color => colorant"red3", :size => 6),
            "min_power" => Dict(:color => colorant"black", :size => 6),
            "bus" => Dict(:color => colorant"green", :size => 12),
            "gen" => Dict(:color => colorant"blue", :size => 12),
            "connector" => Dict(:color => colorant"lightgrey", :size => 4, :style => :dash),
            "label" => Dict(:color => colorant"black", :size => 16, :fontfamily=>"Arial", :textalign=>:center, :offset => 0.1)
            )

case = pglib("case5_pjm")
result = run_opf(case, DCPPowerModel, Ipopt.Optimizer)
PowerModels.update_data!(case, result["solution"])

plot_power_flow(case; filename="power_flow.png", plot_size=(800,800), membership_properties=mp)



## Plot System Voltage
mp = Dict{String, Any}(
    "base_kv" => Dict(:palette => :Accent, :size=>[1,3]),
)

case = pglib("case118_ieee")
plot_system_voltage(case; filename="system_voltage.png", plot_size=(800,800), exclude_sources=true, membership_properties=mp)


## Pegase 1354
mp = Dict{String, Any}(
    "base_kv" => Dict(:palette => :Accent, :size=>[1,3]),
)

case = pglib("case1354_pegase")
plot_system_voltage(case; filename="pegase_1354.png", plot_size=(800,800), exclude_sources=true, membership_properties=mp)


## RTE 1888
mp = Dict{String, Any}(
    "base_kv" => Dict(:palette => :Accent, :size=>[1,3]),
)

case = pglib("case1888_rte")
plot_system_voltage(case; filename="rte_1888.png", plot_size=(800,800), exclude_sources=true, membership_properties=mp)
