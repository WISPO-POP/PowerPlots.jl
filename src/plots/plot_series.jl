

function power_param(data::Dict{String,<:Any}, comp_type, param; kwargs...)
    power_param(data, Symbol(comp_type), Symbol(param); kwargs...)
end

function power_param(data::Dict{String,<:Any}, comp_type::Symbol, param::Symbol; plot_type=:point, kwargs...)
    if get(data,"multinetwork", false)
        return _power_param_mn(data, comp_type, param; plot_type, kwargs...)
    end

    PMD = PowerModelsDataFrame(data)
    p = VegaLite.@vlplot(
        data=getfield(PMD,comp_type),
        plot_type,
        x={
            "index:o",
            title="$(comp_type) ID",
            axis={labelAngle=0}
        },
        y={
            param,
            title="$param"
        },
    )
    return p
end


function _power_param_mn(data::Dict{String,<:Any}, comp_type::Symbol, param::Symbol; plot_type=:point, aggregate=nothing)
    PMD = PowerModelsDataFrame(data)
    getfield(PMD,comp_type)[!,:nw_id] = parse.(Int,getfield(PMD,comp_type)[!,:nw_id])

    if aggregate !== nothing
        if !in(aggregate, ["max","min","sum","mean"])
            Memento.error(_LOGGER, "aggregation \"$(aggregate)\" not supported. Choose one of \"min\", \"max\",\"sum\",\"mean\"")
        end
        p=VegaLite.@vlplot(
            data=getfield(PMD,comp_type),
            plot_type,
            x={ "nw_id:o",
                title="Network ID",
                axis={labelAngle=0}
            },
            y={ param,
                aggregate=aggregate,
                title="$param",
            },
        )
    else
        p=VegaLite.@vlplot(
            data=getfield(PMD,comp_type),
            plot_type,
            x={ "nw_id:o",
                title="Network ID",
                axis={labelAngle=0}
            },
            y={ param,
                title="$param",
            },
            color="index:o"
        )
    end
    return p
end


function power_param(data::Dict{String,<:Any}, comp_type, comp_id::String, param; kwargs...)
    power_param(data, Symbol(comp_type), parse(Int,comp_id), Symbol(param); kwargs...)
end

function power_param(data::Dict{String,<:Any}, comp_type, comp_id::Int, param; kwargs...)
    power_param(data, Symbol(comp_type), comp_id, Symbol(param); kwargs...)
end

function power_param(data::Dict{String,<:Any}, comp_type::Symbol, comp_id::Int, param::Symbol; plot_type=:point)
    PMD = PowerModelsDataFrame(data)
    getfield(PMD,comp_type)[!,:nw_id] = parse.(Int,getfield(PMD,comp_type)[!,:nw_id])

    p = VegaLite.@vlplot(
        data=getfield(PMD,comp_type),
        plot_type,
        transform=[{filter="datum.index == $comp_id"}],
        x={
            "nw_id:o",
            title="Network ID",
            axis={labelAngle=0}
        },
        y={
            param,
            title="$param"
        },
    )
    return p
end


function power_heatmap(data::Dict{String,<:Any}, comp::Any, param::Any; kwargs...)
    power_heatmap(data, Symbol(comp), Symbol(param), title=""; kwargs...)
end

"Plot a heatmap of component parameters across network ids."
function power_heatmap(data::Dict{String,<:Any}, comp::Symbol, param::Symbol; title=""::String)
    PMD = PowerModelsDataFrame(data)
    getfield(PMD,comp)[!,:nw_id] = parse.(Int,getfield(PMD,comp)[!,:nw_id])

    p = VegaLite.@vlplot(
        data=getproperty(PMD,comp),
        title=title,
        :rect,
        x={
            "nw_id:o",
            title="Network ID",
            axis={labelAngle=0}
        },
        y={
            "index:o",
            title="Component ID"
        },
        color={
            # "pf:q",
            param,
            legend={title=nothing}
        },
        config={
            view={
                strokeWidth=0,
                step=13
            },
            axis={
                domain=false
            }
        }
    )
    return p
end