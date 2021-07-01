
"""
Create a layout for a powermodels data dictionary.  This function creates a graph according to the specified keyword arguments `node_types`
and `edge_types`.  A layout function is then applied, by default `layout_graph_kamada_kawai!`.  A new case dictionary with the positions of the
components is returned.
"""
function layout_network!(case::Dict{String,<:Any};
    spring_const=1e-2,
    node_types::Array{String,1}=["bus","gen","storage"],
    edge_types::Array{String,1}=["switch","branch","dcline","transformer"],
    )

    data = deepcopy(case)
    PMG = PowerModelsGraph(data,node_types,edge_types)
    positions = layout_graph_kamada_kawai!(PMG)  #TODO add way to select layout algorithm
    apply_node_positions!(data,positions, PMG)

    return data
end


"Apply positions to the data, using the mapping in edge_comp_map and connector_map"
function apply_node_positions!(data,positions, PMG)
    # Set Node Positions
    for (node,(comp_type,comp_id)) in PMG.node_comp_map
        data[comp_type][comp_id]["xcoord_1"] = positions[node][1]
        data[comp_type][comp_id]["ycoord_1"] = positions[node][2]
    end
    # Set Edge positions
    for ((s,d),(comp_type,comp_id)) in PMG.edge_comp_map
        data[comp_type][comp_id]["xcoord_1"] = positions[s][1]
        data[comp_type][comp_id]["ycoord_1"] = positions[s][2]
        data[comp_type][comp_id]["xcoord_2"] = positions[d][1]
        data[comp_type][comp_id]["ycoord_2"] = positions[d][2]
    end


    # Create connector dictionary
    data["connector"] = Dict{String,Any}()
    id = 1
    for ((s,d),(comp_type,comp_id)) in PMG.edge_connector_map
        data["connector"][string(id)] =  Dict{String,Any}(
            "src" => PMG.node_comp_map[s],
            "dst" => PMG.node_comp_map[d],
            "xcoord_1" => positions[s][1],
            "ycoord_1" => positions[s][2],
            "xcoord_2" => positions[d][1],
            "ycoord_2" => positions[d][2],
            "source_id"=> (comp_type,comp_id)
        )
        id+=1
    end

    return data
end
