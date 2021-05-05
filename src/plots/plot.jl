## Experimental Feature!

## convert to DataFrames
const node_types = ["bus","gen","storage"]
const edge_types = ["switch","branch","dcline","transformer"]



function powerplot( case::Dict{String,<:Any};
                    spring_constant::Float64=1e-3,
                    color_symbol=:ComponentType,
                    kwargs...
    )
    if InfrastructureModels.ismultinetwork(case)
        Memento.error(_LOGGER, "powerplot does not yet support multinetwork data")
    end

    @prepare_plot_attributes(kwargs) # creates the plot_attributes dictionary
    _validate_plot_attributes!(plot_attributes) # check the attributes for valid input types

    data = layout_graph_vega(case, spring_constant)
    remove_information!(data)
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
    ) +
    VegaLite.@vlplot(
        mark ={
            :rule,
            tooltip=("content" => "data"),
            opacity =  1.0,
        },
        data=PMD.branch,
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
        },    ) +
    VegaLite.@vlplot(
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
    ) +
    VegaLite.@vlplot(
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
    ) +
    VegaLite.@vlplot(
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
    )+
    VegaLite.@vlplot(
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
    return p
end


function remove_information!(data::Dict{String,<:Any})
    invalid_keys = Dict("branch"  => ["mu_angmin", "mu_angmax", "mu_sf", "shift", "rate_b", "rate_c", "g_to", "g_fr", "mu_st", "source_id", "f_bus", "t_bus",  "qf", "angmin", "angmax", "qt", "transformer", "tap"],#["b_fr","b_to", "xcoord_1", "xcoord_2", "ycoord_1", "ycoord_2", "pf", "src","dst","rate_a","br_r","br_x","index","br_status"],
                        "bus"     => ["mu_vmax", "lam_q", "mu_vmin", "source_id", "area","lam_p","zone", "bus_i"],#["xcoord_1", "ycoord_1", "bus_type", "name", "vmax",  "vmin", "index", "va", "vm", "base_kv"],
                        "gen"     => ["vg","gen_bus","cost","ncost", "qc1max","qc2max", "ramp_agc", "qc1min", "qc2min", "pc1", "ramp_q", "mu_qmax", "ramp_30", "mu_qmin","model", "shutdown", "startup","ramp_10","source_id", "mu_pmax", "pc2", "mu_pmin","apf",],#["xcoord_1", "ycoord_1",  "pg", "qg",  "pmax",   "mbase", "index", "cost", "qmax",  "qmin", "pmin", "gen_status"]
    )
    for comp_type in ["bus","branch","gen"]
        for (id, comp) in data[comp_type]
            for key in keys(comp)
                if (key in invalid_keys[comp_type])
                    delete!(comp,key)
                end
            end
        end
    end
end