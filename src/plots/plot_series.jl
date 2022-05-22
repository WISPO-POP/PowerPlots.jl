

ts_plot(data, comp_type, param)  # plot the param for each component of type comp

ts_plot(data, comp_type, comp_id, param) # plot the param for comp comp_id over time in mn_data

ts_plot(data, comp_type, param, aggregate=true) # plot param for comptype over time, aggrgated over all comp_ids


tsplot(data, :load, :pd)

tsplot(data, :load, :pd)


function tsplot(data<:Dict{String,Any}, comp_type<:String, param<:String; kwargs...)
    tsplot(data, Symbol(comp_type), Symbol(param); kwargs...)
end

function tsplot(data<:Dict{String,Any}, comp_type::Symbol, param::Symbol; plot_type=:scatter)
    PMD = PowerModelsDataFrame(data)

    p = @vlplot(
        data=getfield(PMD,comp_type)
    )
    return p
end