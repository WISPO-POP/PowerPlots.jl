
# Scratch space for testing development features
Pkg.activate("./")
using PowerPlots
using PowerModels
data = parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

################################################
## No code should be commited in this section ##
################################################
using Gurobi
using VegaLite
using PowerModelsRestoration


data_mn = replicate(data, 20)
for (nwid,nw) in data_mn["nw"]
    for (id,load) in nw["load"]
        load["pd"] = load["pd"]*(0.5+0.5*rand())
    end
end
opf_sol = run_mn_opf(data_mn, DCPPowerModel, Gurobi.Optimizer)
update_data!(data_mn, opf_sol["solution"])



for (id,branch) in data["branch"]
    branch["damaged"] = 1
end

data_mn = PowerModelsRestoration.replicate_restoration_network(data, count=count_damaged_items(data))
sol_rop = run_rop(data_mn, DCPPowerModel, Gurobi.Optimizer)
update_data!(data_mn, sol_rop["solution"])

power_heatmap(data_mn, :branch, :br_status; title="Branch Status")


sol_opf = run_opf(data, DCPPowerModel, Gurobi.Optimizer)
update_data!(data,sol_opf["solution"])

power_param(data, :gen, "pg")
power_param(data_mn, :gen, 2, "pg")
power_param(data_mn, :gen, "pg", plot_type=:line)
power_param(data_mn, :gen, "pg"; plot_type=:line, aggregate="mean")
power_param(data_mn, :gen, "pg", plot_type=:line, aggregate="sum")
power_param(data_mn, :gen, "pg", plot_type=:line, aggregate="max")
power_param(data_mn, :gen, "pg", plot_type=:line, aggregate="min")
power_param(data_mn, :gen, "pg", plot_type=:line, aggregate="mi")
################################################