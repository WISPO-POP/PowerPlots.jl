"Modify distribution grid data dictionary"
function distr_data(case::Dict{String,<:Any})
    # create new dict
    case_dist = Dict{String, Any}("bus"=>Dict{String, Any}(),
        "gen"=>Dict{String, Any}(),
        "branch"=>Dict{String, Any}(),
        "switch"=>Dict{String, Any}(),
        "transformer"=>Dict{String, Any}()
        )
    
    # add bus parameters
    for (idx,bus) in enumerate(case["bus"])
        phases = phase_nodes(bus, "terminals")
        case_dist["bus"]["$idx"] = Dict{String, Any}("source_id"=> bus[2]["source_id"],
            "bus_i"=> bus[2]["bus_i"], "name"=> bus[2]["name"],
            "baseKV"=> bus[2]["vbase"], "index"=> bus[2]["index"],
            "vmin"=> bus[2]["vmin"][1] == 0 ? 0.9 : bus[2]["vmin"][1],
            "vmax"=> bus[2]["vmax"][1] == Inf ? 1.1 : bus[2]["vmax"][1],
            "phases"=> phases, "bus_type"=> bus[2]["bus_type"]
            )
    end

    # add gen parameters
    for (idx,gen) in enumerate(case["gen"])
        phases = phase_nodes(gen, "connections")
        case_dist["gen"]["$idx"] = Dict{String, Any}("phases"=> phases,
            "pg"=> gen[2]["pg"], "qg"=> gen[2]["qg"],
            "index"=> gen[2]["index"], "name"=> gen[2]["name"],
            "gen_status"=> gen[2]["gen_status"], "configuration"=> gen[2]["configuration"],
            "model"=> gen[2]["model"], "gen_bus"=> gen[2]["gen_bus"],
            "vm"=>case["bus"]["$(gen[2]["gen_bus"])"]["vm"],
            "va"=>case["bus"]["$(gen[2]["gen_bus"])"]["va"]*180/pi
            )
    end

    # add branch parameters
    for (idx,branch) in enumerate(case["branch"])
        phases = phase_connectors(branch)
        case_dist["branch"]["$idx"] = Dict{String, Any}("phases"=> phases, 
            "br_status"=> branch[2]["br_status"], "index"=> branch[2]["index"],
            "transformer"=> "false", "name"=> branch[2]["name"],
            "from"=>case["bus"]["$(branch[2]["f_bus"])"]["name"],
            "to"=>case["bus"]["$(branch[2]["t_bus"])"]["name"],
            "f_bus"=> branch[2]["f_bus"], "t_bus"=> branch[2]["t_bus"]
            )
    end

    # add switch parameters
    for (idx,switch) in enumerate(case["switch"])
        phases = phase_connectors(switch)
        case_dist["switch"]["$idx"] = Dict{String, Any}("phases"=> phases, "index"=> switch[2]["index"],
            "from"=>case["bus"]["$(switch[2]["f_bus"])"]["name"],
            "to"=>case["bus"]["$(switch[2]["t_bus"])"]["name"],
            "f_bus"=> switch[2]["f_bus"], "t_bus"=> switch[2]["t_bus"],
            "status"=> switch[2]["state"] == 1 ? "closed" : "open"
            )
    end

    # add transformer parameters
    for (idx,transformer) in enumerate(case["transformer"])
        phases = phase_connectors(transformer)
        case_dist["transformer"]["$idx"] = Dict{String, Any}("phases"=> phases, 
            "index"=> transformer[2]["index"], "polarity"=> transformer[2]["polarity"],
            "from"=>case["bus"]["$(transformer[2]["f_bus"])"]["name"],
            "to"=>case["bus"]["$(transformer[2]["t_bus"])"]["name"],
            "f_bus"=> transformer[2]["f_bus"], "t_bus"=> transformer[2]["t_bus"],
            "transformer"=> "false", "index"=> transformer[2]["index"],
            "status"=> transformer[2]["status"], "configuration"=> transformer[2]["configuration"]
            )
    end

    return case_dist
end


"determine phases for buses and generators"
function phase_nodes(data::Pair{String, Any}, key::String)
    phases = []
    if 1 in data[2][key] 
        push!(phases,"A")
    end
    if 2 in data[2][key] 
        push!(phases,"B")
    end
    if 3 in data[2][key] 
        push!(phases,"C")
    end
    phases = join(phases)
    
    return phases
end


"determine phases for branches, switches and transformers"
function phase_connectors(data::Pair{String, Any})
    phases = []
    if 1 in data[2]["f_connections"] && 1 in data[2]["t_connections"]
        push!(phases,"A")
    end
    if 2 in data[2]["f_connections"] && 2 in data[2]["t_connections"]
        push!(phases,"B")
    end
    if 3 in data[2]["f_connections"] && 3 in data[2]["t_connections"]
        push!(phases,"C")
    end
    phases = join(phases)

    return phases
end

