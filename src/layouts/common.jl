
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
    G,ids,node_comp_map,edge_comp_map,connector_map = create_pm_graph(data,node_types,edge_types)

    positions = layout_graph_kamada_kawai!(G, ids)  #TODO add way to select layout algorithm

    apply_node_positions!(data,positions, edge_comp_map, connector_map)

    return data
end


"Apply positions to the data, using the mapping in edge_comp_map and connector_map"
function apply_node_positions!(data,positions, edge_comp_map, connector_map)
    # Set Node Positions
    for (node, (x, y)) in positions
        (comp_type,comp_id) = split(node, "_")
        data[comp_type][comp_id]["xcoord_1"] = x
        data[comp_type][comp_id]["ycoord_1"] = y
    end
    # Set Edge positions
    for (edge, val) in (edge_comp_map)
        (x,y) = positions[val["src"]]
        (x2,y2) = positions[val["dst"]]
        (comp_type,comp_id) = split(edge, "_")
        data[comp_type][comp_id]["xcoord_1"] = x
        data[comp_type][comp_id]["ycoord_1"] = y
        data[comp_type][comp_id]["xcoord_2"] = x2
        data[comp_type][comp_id]["ycoord_2"] = y2
    end

    # Create connector dictionary
    data["connector"] = Dict{String,Any}()
    for (edge, con) in connector_map
        _,id = split(edge, "_")
        data["connector"][id] =  Dict{String,Any}(
            "src" => con["src"],
            "dst" => con["dst"],
        )
    end
    # Set Connector positions
    for (connector, val) in (connector_map)
        (x,y) = positions[val["src"]]
        (x2,y2) = positions[val["dst"]]
        (comp_type,comp_id) = split(connector, "_")
        data[comp_type][comp_id]["xcoord_1"] = x
        data[comp_type][comp_id]["ycoord_1"] = y
        data[comp_type][comp_id]["xcoord_2"] = x2
        data[comp_type][comp_id]["ycoord_2"] = y2
    end

    return data
end
