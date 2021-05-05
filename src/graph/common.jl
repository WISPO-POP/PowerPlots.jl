
"Create a PowerModelsGraph where node_types specifs component types that are nodes in the graph, and edge_type specifices components that are edges."
function create_pm_graph(data::Dict{String,<:Any}, node_types::Array{String,1}, edge_types::Array{String,1})

    node_comp_map = get_node_comp_map(data,node_types)
    edge_comp_map = get_edge_comp_map(data,edge_types)
    connector_map = get_connector_map(data,node_types)


    G = PowerModelsGraph(0) # construct empty powermodels graph
    ids = []
    idmap = Dict()
    i = 1 # set up iterator, need to associate LG generated indices with the 'id' field, can use metagraph to add 'id' field to
    for (id, node) in node_comp_map
        add_vertex!(G) # add vertex to graph
        set_property!(G, i, :id, id) # set :id property to be equal to id.
        push!(ids, id) # add node id (a string "compType_idNo") to list
        push!(idmap, id => i) # push map from id to lg index to dictionary
        i = i + 1 # increment i
    end

    for (id,edge) in edge_comp_map
        add_edge!(G, idmap[edge["src"]], idmap[edge["dst"]])
    end

    for (id,edge) in connector_map
        add_edge!(G, idmap[edge["src"]], idmap[edge["dst"]])
    end
    return (G,ids,node_comp_map,edge_comp_map,connector_map)
end


"""
    Create a dictionary map for nodes from components. This is used to create a PowerModelsGraph structure. `node_types` is a string
    array for of all the components that are considered nodes in the graph.
    ```Dict("gen_1"=>case["gen"]["1"])```
"""
function get_node_comp_map(data::Dict{String,<:Any},node_types::Array{String,1})
    node_comp_map = Dict{String,Any}()
    for node_type in node_types
        temp_node = get(data, node_type, Dict{String,Any}())
        temp_map = Dict(string(comp["source_id"][1], "_", comp["source_id"][2]) => comp  for (comp_id, comp) in temp_node)
        merge!(node_comp_map, temp_map)
    end
    return node_comp_map
end


"""
    Create a dictionary map for edges from components. This is used to create a PowerModelsGraph structure. `edge_types` is a string
    array for of all the components that are considered edges in the graph, like branches and dclines.
    ```Dict("branch_1"=>case["branch"]["1"])```
    A dictionary entry is added to specify the from and to buses in node mapping form `bus_1`.
"""
function get_edge_comp_map(data::Dict{String,<:Any},edge_types::Array{String,1})
    edge_comp_map = Dict{String,Any}()
    for edge_type in edge_types
        temp_edge = get(data, edge_type, Dict{String,Any}())
        for (id,edge) in temp_edge
            edge["src"] = "bus_$(edge["f_bus"])"
            edge["dst"] = "bus_$(edge["t_bus"])"
        end
        temp_map = Dict(string(comp["source_id"][1],"_",comp["source_id"][2]) => comp for (comp_id, comp) in temp_edge)
        merge!(edge_comp_map,temp_map)
    end
    return edge_comp_map
end


"""
    Create a dictionary map for edges that connect nodes to buses. This is used to create a PowerModelsGraph structure. `node_types` is a string
    array for of all the components that are considered nodes in the graph, and a connector branch is created for each non-bus node between the
    node and the parent bus.
    ```Dict("connector_1"=>Dict("src"=>"gen_1","dst"=>"bus_1"))```
"""
function get_connector_map(data::Dict{String,<:Any},node_types::Array{String,1})
    connector_map = Dict{String,Any}()
    for node_type in node_types
        if node_type!="bus"
            nodes = get(data, node_type, Dict{String,Any}())
            for (id,node) in nodes
                temp_connector = Dict{String,Any}()
                temp_connector["src"] = "$(node_type)_$(id)"
                temp_connector["dst"] = "bus_$(node["$(node_type)_bus"])"

                temp_map = Dict(string("connector_",(length(connector_map) + 1)) => temp_connector)
                merge!(connector_map,temp_map)
            end
        end
    end
    return connector_map
end
