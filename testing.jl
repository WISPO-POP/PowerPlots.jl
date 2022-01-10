

using Pkg; Pkg.activate(".")

using VegaLite


## data
using PowerModels
using PowerPlots
using PGLIB
using Setfield
using OrderedCollections

function powerplot_mn( case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    fixed=false,
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
    "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
    "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
    kwargs...
)
# if InfrastructureModels.ismultinetwork(case)
#     Memento.error(_LOGGER, "powerplot does not yet support multinetwork data")
#     data = layout_network(case; layout_algorithm=layout_algorithm, fixed=fixed, kwargs...)
# end
# data = layout_network(case; layout_algorithm=layout_algorithm, fixed=fixed, kwargs...)

PowerPlots.@prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
PowerPlots._validate_plot_attributes!(plot_attributes) # check the attributes for valid input types
# for (nwid,nw) in case["nw"]
#   remove_information!(nw, invalid_keys)
# end

PMD = PowerModelsDataFrame(case)


# validate data-related attributes
PowerPlots._validate_data_type(plot_attributes, :gen_data_type)
PowerPlots._validate_data(PMD.gen, plot_attributes[:gen_data], "generator")
PowerPlots._validate_data_type(plot_attributes, :bus_data_type)
PowerPlots._validate_data(PMD.bus, plot_attributes[:bus_data], "bus")
PowerPlots._validate_data_type(plot_attributes, :branch_data_type)
PowerPlots._validate_data(PMD.branch, plot_attributes[:branch_data], "branch")
PowerPlots._validate_data_type(plot_attributes, :dcline_data_type)
PowerPlots._validate_data(PMD.dcline, plot_attributes[:dcline_data], "DC line")

# make the plots
# p = plot_base(plot_attributes)
p = VegaLite.@vlplot(
  width=plot_attributes[:width],
  height=plot_attributes[:height],
  config={view={stroke=nothing}},
  x={axis=nothing},
  y={axis=nothing},
  resolve={
      scale={
          color=:independent
      }
  },
  params=[{
    name="nwid",
    select={type="point"},
    value=minimum(parse.(Int,collect(keys(case["nw"])))),
    bind={input="range",  min=minimum(parse.(Int,collect(keys(case["nw"])))), max=maximum((parse.(Int,collect(keys(case["nw"]))))), step=1}
  }],
)

if !(isempty(PMD.branch))
p = p+plot_branch(PMD, plot_attributes)
end
if !(isempty(PMD.dcline))
p = p+plot_dcline(PMD, plot_attributes)
end
if !(isempty(PMD.connector))
p = p+plot_connector(PMD, plot_attributes)
end
if !(isempty(PMD.bus))
  p = p+plot_bus(PMD, plot_attributes)
end
if !(isempty(PMD.gen))
p = p+plot_gen(PMD, plot_attributes)
end

for i in keys(p.layer)
  p.layer[i]["transform"] = OrderedCollections.OrderedDict{String, Any}[OrderedCollections.OrderedDict("filter"=>"datum.nw_id == nwid")]
end

return p
end

## Testing

case = pglib("case5_pjm")

case = layout_network(case; layout_algorithm=kamada_kawai, fixed=false)

case_mn = replicate(case, 30)

for (nwid,nw) in case_mn["nw"]
    for comp_type in ["bus","gen","branch"]
        for (id,comp) in nw[comp_type]
          comp["status"] = round(Int,rand())
        end
    end
end

pp = powerplot_mn(case_mn, bus_data="status",gen_data="status",branch_data="status", width=500, height=500, node_color=["red","black"], edge_color=["blue","green"])

