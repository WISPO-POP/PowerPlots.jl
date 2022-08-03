
"""
    `powerplot(
        case::Dict{String,<:Any};
        layout_algorithm=kamada_kawai,
        fixed=false,
        invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
        "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
        "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
        kwargs...)`

Create a plower plot. Check github repo for documentation on kwarg options.
"""
function powerplot(
    case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    fixed=false,
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
    "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
    "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
    kwargs...)

    if InfrastructureModels.ismultinetwork(case)
        return _powerplot_mn(case; layout_algorithm=layout_algorithm, fixed=fixed, invalid_keys=invalid_keys, kwargs...)
    end

    # modify case dictionary for distribution grid data
    if haskey(case, "is_kron_reduced")
        case = distr_data(case)
    end

    @prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    data = layout_network(case; layout_algorithm=layout_algorithm, fixed=fixed, kwargs...)

    # fix parallel branch coordinates
    offset_parallel_edges!(data,plot_attributes[:parallel_edge_offset])

    remove_information!(data, invalid_keys)
    PMD = PowerModelsDataFrame(data)

    # validate data-related attributes
    _validate_data_type(plot_attributes, :gen_data_type)
    _validate_data(PMD.gen, plot_attributes[:gen_data], "generator")
    _validate_data_type(plot_attributes, :bus_data_type)
    _validate_data(PMD.bus, plot_attributes[:bus_data], "bus")
    _validate_data_type(plot_attributes, :branch_data_type)
    _validate_data(PMD.branch, plot_attributes[:branch_data], "branch")
    _validate_data_type(plot_attributes, :dcline_data_type)
    _validate_data(PMD.dcline, plot_attributes[:dcline_data], "DC line")

    # make the plots
    p = plot_base(data, plot_attributes)
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
    if !(isempty(PMD.load))
        p = p+plot_load(PMD, plot_attributes)
    end
    return p
end

"""
    `powerplot!(
        plt_layer::VegaLite.VLSpec, case::Dict{String,<:Any};
        layout_algorithm=kamada_kawai,
        fixed=false,
        invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
        "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
        "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
        kwargs...)`

Create a plower plot, with a different VegaLite plot as the bottom layer of the plot.  Primarily
used to plot geographic map data underneath a power grid.
"""
function powerplot!(plt_layer::VegaLite.VLSpec, case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    fixed=false,
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
    "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
    "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
    kwargs...)

    if InfrastructureModels.ismultinetwork(case)
        return _powerplot_mn!(plt_layer, case; layout_algorithm=layout_algorithm, fixed=fixed, invalid_keys=invalid_keys, kwargs...)
    end

    # modify case dictionary for distribution grid data
    if haskey(case, "is_kron_reduced")
        case = distr_data(case)
    end

    @prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    data = layout_network(case; layout_algorithm=layout_algorithm, fixed=fixed, kwargs...)

    # fix parallel branch coordinates
    offset_parallel_edges!(data,plot_attributes[:parallel_edge_offset])

    remove_information!(data, invalid_keys)
    PMD = PowerModelsDataFrame(data)

    # validate data-related attributes
    _validate_data_type(plot_attributes, :gen_data_type)
    _validate_data(PMD.gen, plot_attributes[:gen_data], "generator")
    _validate_data_type(plot_attributes, :bus_data_type)
    _validate_data(PMD.bus, plot_attributes[:bus_data], "bus")
    _validate_data_type(plot_attributes, :branch_data_type)
    _validate_data(PMD.branch, plot_attributes[:branch_data], "branch")
    _validate_data_type(plot_attributes, :dcline_data_type)
    _validate_data(PMD.dcline, plot_attributes[:dcline_data], "DC line")

    # make the plots
    p = plot_base(data, plot_attributes)

    # add layer
    p = p+plt_layer

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
    if !(isempty(PMD.load))
        p = p+plot_load(PMD, plot_attributes)
    end
    return p
end


function _powerplot_mn(case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    fixed=false,
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
    "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
    "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
    kwargs... )

    data = deepcopy(case)

    PowerPlots.@prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
    PowerPlots._validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    for (nwid,net) in data["nw"]
        if haskey(first(case["nw"])[2],"is_kron_reduced")
            net = distr_data(net)
        end
        data["nw"][nwid] = layout_network(net; layout_algorithm=layout_algorithm, fixed=fixed, kwargs...)

        # fix parallel branch coordinates
        offset_parallel_edges!(data["nw"][nwid],plot_attributes[:parallel_edge_offset])
    end

    for (nwid,nw) in data["nw"]
      remove_information!(nw, invalid_keys)
    end

    PMD = PowerModelsDataFrame(data)


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
    p = plot_base_mn(data,plot_attributes)
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
    if !(isempty(PMD.load))
        p = p+plot_load(PMD, plot_attributes)
    end

    for i in keys(p.layer)  # add filter for nwid on each layer
        p.layer[i]["transform"] = OrderedCollections.OrderedDict{String, Any}[OrderedCollections.OrderedDict("filter"=>"datum.nw_id == nwid")]
    end

    return p
end


function _powerplot_mn!(plt_layer::VegaLite.VLSpec, case::Dict{String,<:Any};
    layout_algorithm=kamada_kawai,
    fixed=false,
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
    "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id","lam_p"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
    "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",]),#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]),
    kwargs... )

    PowerPlots.@prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
    PowerPlots._validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    data = deepcopy(case)
    for (nwid,net) in data["nw"]
        if haskey(first(case["nw"])[2],"is_kron_reduced")
            net = distr_data(net)
        end
        data["nw"][nwid] = layout_network(net; layout_algorithm=layout_algorithm, fixed=fixed, kwargs...)

        # fix parallel branch coordinates
        offset_parallel_edges!(data["nw"][nwid],plot_attributes[:parallel_edge_offset])
    end

    for (nwid,nw) in data["nw"]
      remove_information!(nw, invalid_keys)
    end

    PMD = PowerModelsDataFrame(data)

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
    p = plot_base_mn(data,plot_attributes)

    # add layers
    old_layer_count = 1 # used to only reference new powerplot layers in logic below
    if hasproperty(plt_layer,:layer)
        old_layer_count=length(keys(plt_layer.layer))
    end
    p = p+plt_layer

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
    if !(isempty(PMD.load))
        p = p+plot_load(PMD, plot_attributes)
    end

    for i in keys(p.layer)  # add filter for nwid on each powerplot layer
        if i > old_layer_count
            p.layer[i]["transform"] = OrderedCollections.OrderedDict{String, Any}[OrderedCollections.OrderedDict("filter"=>"datum.nw_id == nwid")]
        end
    end

    return p
end


function plot_base(data::Dict{String, <:Any}, plot_attributes::Dict{Symbol,Any})
    min_x = data["layout_extent"]["min_x"]
    max_x = data["layout_extent"]["max_x"]
    min_y = data["layout_extent"]["min_y"]
    max_y = data["layout_extent"]["max_y"]

    # Set axes to same size to match a uniform Cartesian space
    min_coord = min(min_x, min_y)
    max_coord = max(max_x, max_y)

    return p = VegaLite.@vlplot(
        width=plot_attributes[:width],
        height=plot_attributes[:height],
        config={view={stroke=nothing}},
        x={axis=nothing,scale={domain=[min_coord,max_coord]}},
        y={axis=nothing,scale={domain=[min_coord,max_coord]}},
        resolve={
            scale={
                color=:independent
            }
        },
    )
end


function plot_base_mn(case::Dict{String,Any},plot_attributes::Dict{Symbol,Any})
    return p = VegaLite.@vlplot(
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
        bind={
            input="range",
            min=minimum(parse.(Int,collect(keys(case["nw"])))),
            max=maximum((parse.(Int,collect(keys(case["nw"]))))),
            step=1}
        }],
    )
end


function plot_branch(PMD::PowerModelsDataFrame, plot_attributes::Dict{Symbol,Any})
    flow_legend = true
    if plot_attributes[:show_flow_legend] in [nothing, false, :false, "false", :no, "no"]
        flow_legend = nothing
    end
    flow_opacity = 1.0
    if plot_attributes[:show_flow] in [nothing, false, :false, "false", :no, "no"]
        flow_opacity = 0.0
    end

    return VegaLite.@vlplot(
        data=PMD.branch,
        layer=[
            {
                mark ={
                    :rule,
                    tooltip=("content" => "data"),
                    opacity =  1.0,
                },
                x={:xcoord_1,type="quantitative"},
                x2={:xcoord_2,type="quantitative"},
                y={:ycoord_1,type="quantitative"},
                y2={:ycoord_2,type="quantitative"},
                size={value=plot_attributes[:branch_size]},
                color={
                    field=plot_attributes[:branch_data],
                    type=plot_attributes[:branch_data_type],
                    title="Branch",
                    scale={
                        range=plot_attributes[:branch_color]
                    },
                    # legend={orient="bottom-right"}
                },
            },
            {
                transform=[
                    {
                        calculate="(datum.xcoord_1 + datum.xcoord_2)/2",
                        as="mid_x"
                    },
                    {
                        calculate="(datum.ycoord_1 + datum.ycoord_2)/2",
                        as="mid_y"
                    },
                    {
                        calculate="180*(if(datum.pf >= 0,
                            atan2(datum.xcoord_2 - datum.xcoord_1, datum.ycoord_2 - datum.ycoord_1),
                            atan2(datum.xcoord_1 - datum.xcoord_2, datum.ycoord_1 - datum.ycoord_2)
                        ))/PI",
                        as="angle"
                    },
                    {
                        calculate="abs(datum.pt)",
                        as="power"
                    }
                ],
                mark={
                    :point,
                    shape=:wedge,
                    filled=true,
                    opacity=flow_opacity,
                    color=plot_attributes[:flow_color],
                },
                x={:mid_x,type="quantitative"},
                y={:mid_y,type="quantitative"},
                size={:power, scale={range=plot_attributes[:flow_arrow_size_range]}, type="quantitative", legend=flow_legend},
                angle={:angle, scale={domain=[0,360], range=[0,360]}, type="quantitative"}
            }
        ]
    )
end

function plot_dcline(PMD::PowerModelsDataFrame, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        mark ={
            :rule,
            tooltip=("content" => "data"),
            opacity =  1.0,
        },
        data=PMD.dcline,
        x={:xcoord_1,type="quantitative"},
        x2={:xcoord_2,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        y2={:ycoord_2,type="quantitative"},
        size={value=plot_attributes[:dcline_size]},
        color={
            field=plot_attributes[:dcline_data],
            type=plot_attributes[:dcline_data_type],
            title="DCLine",
            scale={
                range=plot_attributes[:dcline_color]
            },
            # legend={orient="bottom-right"}
        },
    )
end

function plot_connector(PMD::PowerModelsDataFrame, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        mark ={
            :rule,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        data=PMD.connector,
        x={:xcoord_1,type="quantitative"},
        x2={:xcoord_2,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        y2={:ycoord_2,type="quantitative"},
        size={value=plot_attributes[:connector_size]},
        strokeDash={value=[4,4]},
        color={
            field="ComponentType",
            type="nominal",
            title="Connector",
            scale={
                range=plot_attributes[:connector_color]
            },
            # legend={orient="bottom-right"}
        },
    )
end

function plot_bus(PMD::PowerModelsDataFrame, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        data = PMD.bus,
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        x={:xcoord_1,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        size={value=plot_attributes[:bus_size]},
        color={
            field=plot_attributes[:bus_data],
            type=plot_attributes[:bus_data_type],
            title="Bus",
            scale={
                range=plot_attributes[:bus_color]
            },
            # legend={orient="bottom-right"}
        },
    )
end

function plot_gen(PMD::PowerModelsDataFrame, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        data = PMD.gen,
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        x={:xcoord_1,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        size={value=plot_attributes[:gen_size]},
        color={
            field=plot_attributes[:gen_data],
            type=plot_attributes[:gen_data_type],
            title="Gen",
            scale={
                range=plot_attributes[:gen_color]
            }
            # legend={orient="bottom-right"}
        },
    )
end


function plot_load(PMD::PowerModelsDataFrame, plot_attributes::Dict{Symbol,Any})
    return VegaLite.@vlplot(
        data = PMD.load,
        mark ={
            :circle,
            "tooltip" =("content" => "data"),
            opacity =  1.0,
        },
        x={:xcoord_1,type="quantitative"},
        y={:ycoord_1,type="quantitative"},
        size={value=plot_attributes[:load_size]},
        color={
            field=plot_attributes[:load_data],
            type=plot_attributes[:load_data_type],
            title="Load",
            scale={
                range=plot_attributes[:load_color]
            }
            # legend={orient="bottom-right"}
        },
    )
end

"Remove keys from componet dictionaries based on input invalid keys"
function remove_information!(data::Dict{String,<:Any}, invalid_keys::Dict{String,<:Any})
    for comp_type in ["bus","branch","gen"]
        if haskey(data, comp_type)
            for (id, comp) in data[comp_type]
                for key in keys(comp)
                    if (key in invalid_keys[comp_type])
                        delete!(comp,key)
                    end
                end
            end
        end
    end
end
