var documenterSearchIndex = {"docs":
[{"location":"examples/advanced examples/#Advanced-Examples","page":"Advanced Examples","title":"Advanced Examples","text":"","category":"section"},{"location":"examples/advanced examples/","page":"Advanced Examples","title":"Advanced Examples","text":"These examples can be used as a basis for creating more complicated vizualizations.","category":"page"},{"location":"examples/advanced examples/#Powerflow","page":"Advanced Examples","title":"Powerflow","text":"","category":"section"},{"location":"examples/advanced examples/","page":"Advanced Examples","title":"Advanced Examples","text":"using PowerModels\nusing PowerModelsAnalytics\nusing PowerPlots\nusing ColorSchemes\nusing Setfield\nusing JuMP, Ipopt\ncase = parse_file(\"case14.m\")\nresult = solve_ac_opf(case, optimizer_with_attributes(Ipopt.Optimizer, \"print_level\"=>0))\nupdate_data!(case,result[\"solution\"])\n\nplot1 = powerplot(case,\n                # bus_data=:vm,\n                # bus_data_type=:quantitative,\n                gen_data=:pg,\n                gen_data_type=:quantitative,\n                branch_data=:pt,\n                branch_data_type=:quantitative,\n                branch_color=[\"DimGray\",\"red\"],\n                gen_color=[\"DimGray\",\"red\"]\n)\n\nplot1.layer[1][\"transform\"] = Dict{String, Any}[\n    Dict(\"calculate\"=>\"abs(datum.pt)/datum.rate_a*100\", \"as\"=>\"branch_Percent_Loading\"),\n    Dict(\"calculate\"=>\"abs(datum.pt)\", \"as\"=>\"BranchPower\")\n]\nplot1.layer[1][\"layer\"][1][\"encoding\"][\"color\"][\"field\"]=\"branch_Percent_Loading\"\nplot1.layer[1][\"layer\"][1][\"encoding\"][\"color\"][\"title\"]=\"Branch Utilization %\"\nplot1.layer[1][\"layer\"][1][\"encoding\"][\"color\"][\"scale\"][\"domain\"]=[0,100]\n#plot1.layer[1][\"layer\"][1][\"encoding\"][\"size\"]=Dict(\"field\"=>\"BranchPower\", \"title\"=>\"Branch BaseMW\", \"type\"=>\"quantitative\", \"scale\"=>Dict(\"range\"=>[3,10]))\n\n\nplot1.layer[4][\"transform\"] = Dict{String, Any}[\n    Dict(\"calculate\"=>\"datum.pg/datum.pmax*100\", \"as\"=>\"gen_Percent_Loading\"),\n    Dict(\"calculate\"=>\"datum.pg\", \"as\"=>\"GenPower\")\n]\nplot1.layer[4][\"encoding\"][\"color\"][\"field\"]=\"gen_Percent_Loading\"\nplot1.layer[4][\"encoding\"][\"color\"][\"scale\"][\"domain\"]=[0,100]\nplot1.layer[4][\"encoding\"][\"color\"][\"title\"]=\"Gen Utilization %\"\nplot1.layer[4][\"encoding\"][\"size\"]=Dict(\"field\"=>\"GenPower\", \"title\"=>\"Gen BaseMW\", \"type\"=>\"quantitative\", \"scale\"=>Dict(\"range\"=>[300,1000]))\n\nplot1.layer[1][\"layer\"][1][\"encoding\"][\"color\"][\"legend\"]=Dict(\"orient\"=>\"bottom-right\", \"offset\"=>-30)\nplot1.layer[4][\"encoding\"][\"color\"][\"legend\"]=Dict(\"orient\"=>\"bottom-right\")\n\n@set! plot1.resolve.scale.size=:independent\n@set! plot1.resolve.scale.color=:shared\n\nplot1","category":"page"},{"location":"examples/advanced examples/#Load-Blocks","page":"Advanced Examples","title":"Load Blocks","text":"","category":"section"},{"location":"examples/advanced examples/","page":"Advanced Examples","title":"Advanced Examples","text":"using PowerModels\nusing PowerModelsAnalytics\nusing PowerPlots\nusing ColorSchemes\nusing Setfield\n\ncase = parse_file(\"case14.m\")\ncase[\"branch\"][\"10\"][\"br_status\"] = 0\ncase[\"branch\"][\"16\"][\"br_status\"] = 0\ncase[\"branch\"][\"17\"][\"br_status\"] = 0\n\n# Identify loadk blocks for all components\nfor (block_id, bus_ids) in identify_blocks(case)\n    for bus_id in bus_ids\n        case[\"bus\"][bus_id][\"block\"]=block_id\n    end\nend\nfor (gen_id,gen) in case[\"gen\"]\n    gen[\"block\"] = case[\"bus\"][string(gen[\"gen_bus\"])][\"block\"]\nend\nfor (branch_id,branch) in case[\"branch\"]\n    f_bus = branch[\"f_bus\"]\n    t_bus = branch[\"t_bus\"]\n    if case[\"bus\"][\"$(f_bus)\"][\"block\"] == case[\"bus\"][\"$(t_bus)\"][\"block\"]\n        branch[\"block\"] =  case[\"bus\"][\"$(f_bus)\"][\"block\"]\n    else\n        branch[\"block\"] = \"damaged\"\n    end\nend\n\ncolor_range = colorscheme2array(ColorSchemes.colorschemes[:tableau_10])\ncolor_range = [color_range[i] for i in[1,2,4,3]]\nplot1 = powerplot(case; bus_data=:block, gen_data=:block, branch_data=:block, node_color=color_range, branch_color=color_range, show_flow=false)\n\n@set! plot1.resolve.scale.color=:shared # share color scale for all components\nplot1.layer[1][\"layer\"][1][\"encoding\"][\"color\"][\"title\"]=\"Load Blocks\"\nplot1.layer[2][\"encoding\"][\"color\"][\"title\"]=\"Load Blocks\"\nplot1.layer[3][\"encoding\"][\"color\"][\"title\"]=\"Load Blocks\"\nplot1.layer[4][\"encoding\"][\"color\"][\"title\"]=\"Load Blocks\"\n\n\nplot1","category":"page"},{"location":"examples/advanced examples/#Restoration-Sequence","page":"Advanced Examples","title":"Restoration Sequence","text":"","category":"section"},{"location":"data_transformations/powermodelsdataframes/#PowerModels-Dictionary-to-DataFrame-Conversion","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"","category":"section"},{"location":"data_transformations/powermodelsdataframes/","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"VegaLite uses tabular data when creating a plot, and this requires converting the PowerModels dictionary data into a DataFrame.  A struct is used for all of the supported components of the base power plot, where each component type is a DataFrame.  This struct is created when  powerplot() is called.  Multi-network dictionaries are supported.","category":"page"},{"location":"data_transformations/powermodelsdataframes/","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"mutable struct PowerModelsDataFrame\n    metadata::DataFrames.DataFrame\n    bus::DataFrames.DataFrame\n    gen::DataFrames.DataFrame\n    branch::DataFrames.DataFrame\n    dcline::DataFrames.DataFrame\n    load::DataFrames.DataFrame\n    connector::DataFrames.DataFrame","category":"page"},{"location":"data_transformations/powermodelsdataframes/","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"Using tabular data can be convenient for a statistical analysis of the components. To create this data struct, call the constructor on a powermodels dictionary.","category":"page"},{"location":"data_transformations/powermodelsdataframes/","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"using PowerModels\nusing PowerPlots\ncase = parse_file(\"case14.m\")\n\ncase_PMDF = PowerModelsDataFrame(case)","category":"page"},{"location":"data_transformations/powermodelsdataframes/","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"To create an individual component dictionary, use the comp_dict_to_dataframe function.","category":"page"},{"location":"data_transformations/powermodelsdataframes/","page":"PowerModels Dictionary to DataFrame Conversion","title":"PowerModels Dictionary to DataFrame Conversion","text":"using PowerModels\nusing PowerPlots\ncase = parse_file(\"case14.m\")\n\ncase_PMDF = comp_dict_to_dataframe(case[\"bus\"])","category":"page"},{"location":"experimental/#Experimental","page":"Experimental Features","title":"Experimental","text":"","category":"section"},{"location":"experimental/","page":"Experimental Features","title":"Experimental Features","text":"The following are experimental features in PowerPlots.  They may change or dissapear. To use the experimental features, the experimental module must be imported.","category":"page"},{"location":"experimental/","page":"Experimental Features","title":"Experimental Features","text":"julia> using PowerPlots\njulia> using PowerPlots.Experimental","category":"page"},{"location":"experimental/#Apply-geographic-coordinates","page":"Experimental Features","title":"Apply geographic coordinates","text":"","category":"section"},{"location":"experimental/","page":"Experimental Features","title":"Experimental Features","text":"Change the coordinates from cartesian to a geographic projection. This is experimental because it is not well tested. VegaLite does not support geographic projections and zooming/panning yet, so combining with add_zoom! will not work.","category":"page"},{"location":"experimental/","page":"Experimental Features","title":"Experimental Features","text":"using PowerPlots\nusing PowerPlots.Experimental\nusing PowerModels\nusing Setfield\n\n#TODO use a case with actual geo coordinates to show the difference.\ncase = parse_file(\"case14.m\")\np1 = powerplot(case; width=300, height=300)\np2 = deepcopy(p1)\nPowerPlots.Experimental.cartesian2geo!(p2)\n\n@set! p1.title = \"Cartesian\"\n@set! p2.title = \"Geo Projection\"\n\np = [p1 p2]\n","category":"page"},{"location":"experimental/#Add-Zoom","page":"Experimental Features","title":"Add Zoom","text":"","category":"section"},{"location":"experimental/","page":"Experimental Features","title":"Experimental Features","text":"To enable zoom and pan on a plot use add_zoom!(plot).  This is experimental because hover will only work on the first layer (branches) when zoom is enabled.","category":"page"},{"location":"experimental/","page":"Experimental Features","title":"Experimental Features","text":"using PowerPlots\nusing PowerModels\ncase = parse_file(\"case14.m\")\nplot1 = powerplot(case)\nPowerPlots.Experimental.add_zoom!(plot1)\n\nplot1","category":"page"},{"location":"data_transformations/layouts/#Layouts","page":"Layouts","title":"Layouts","text":"","category":"section"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"The default layout algorithm for powerplot() is the Kamada Kawai network layout algorithm.  This algorithm generally creates very nice looking graphs with few line crossings, but requires minimining a non-linear function and does not scale well to very large networks.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"Network Layout Time\nIEEE 14 Bus 0.003902 seconds\nIEEE 118 Bus 0.101225 seconds\npegase 1354 22.459203 seconds\nRTE  1888 Bus 46.854940 seconds","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"If using a large network, it may be beneficial to create a layout and add this to the data dictionary.  This will assign coordinates xcoord_1,ycoord_1 for each component in the powermodels data dictionary.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"case = layout_network(case)\nprintln(case[\"bus\"][\"1\"][\"xcoord_1\"])\n0.0215938","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"Then, when plotting you can use the fixed arguments to use the component coordinates instead of creating a new layout.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"powerplot(case, fixed=true)","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"Values for the coordinates can also be created manually, for example for geographic coordinates. The simply add a dictionary key for xcoord_1 and ycoord_1 to the powermodels data dictionary for the nodal components (such as buses and generators).  Any nodal components that do not have a value will have a layout calculated, and values for edge components (such as branches) are identified from their endpoints.","category":"page"},{"location":"data_transformations/layouts/#Selecting-layouts","page":"Layouts","title":"Selecting layouts","text":"","category":"section"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"Several layout algorithms are supported. The default is Kamada Kawai, but other algorithms have better performance on larger networks like the PEGASE 1354 bus network.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"Layout Algorithm Layout Time\nkamada_kawai 22.459203 seconds\nShell 0.054517 seconds\nSFDP 1.099188 seconds\nBuchheim N/A on meshed networks\nSpring 3.143862 seconds\nSquareGrid 0.051883 seconds\nSpectral 0.911582 seconds","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"A layout algorithm can be selected using a keyword argument.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"layout_network(case; layout_algorithm=Spring)","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"The keyword arguments for each algorithm are vary.  The kamada_kawai layout has no supported arguments. The following are layout algorithms from the package NetworkLayouts.jl.  The arguments for these functions can be found in the documentation for NetworkLayouts.jl.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"Shell\nSFDP\nBuchheim\nSpring\nSquareGrid\nSpectral","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"The layout algorithm arguments can be passed to the layout_network function.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"case = layout_network(case; layout_algorithm=SFDP, C=0.1, K=0.9)","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"The layout algorithm arguments can be also passed in directly through powerplot.","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"powerplot(case; layout_algorithm=Spring, iterations=50)","category":"page"},{"location":"data_transformations/layouts/","page":"Layouts","title":"Layouts","text":"When using fixed=true, a variation of the SFDP algorithm is sued that does not update corrdinates with prior coordinates set.  The same arguments arguments as the SFDP algorithm can be used to modify the layout.","category":"page"},{"location":"examples/basic examples/#Basic-Examples","page":"Basic Examples","title":"Basic Examples","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"Simple examples for setting the data visualization and changing the color or size of components.","category":"page"},{"location":"examples/basic examples/#Initialize","page":"Basic Examples","title":"Initialize","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"using PowerPlots, PowerModels\ndata = parse_file(\"$(joinpath(dirname(pathof(PowerModels)), \"..\"))/test/data/matpower/case5.m\")","category":"page"},{"location":"examples/basic examples/#Default-Plot","page":"Basic Examples","title":"Default Plot","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot(data)","category":"page"},{"location":"examples/basic examples/#Change-Plot-Size","page":"Basic Examples","title":"Change Plot Size","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot(data; width=300, height=300)","category":"page"},{"location":"examples/basic examples/#Modify-Colors","page":"Basic Examples","title":"Modify Colors","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"The colors of the components can be set, using simple keywords. Any valid CSS color can be used. If a single color is used, the component will not change color based on system data.  See Color Ranges for how to use multiple colors.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot(data; bus_color=\"orange\",\n                gen_color=:purple,\n                branch_color=\"#AFAFAF\",\n                width=300, height=300)","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"The aliases node_color and edge_color can overwrite all nodes and edges respectively.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot(data; node_color=\"red\", edge_color=\"purple\", width=300, height=300)","category":"page"},{"location":"examples/basic examples/#Modify-Component-Size","page":"Basic Examples","title":"Modify Component Size","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"The size of components can be set similarly.  A good size for node devices is typically around 100x larger than edge devices.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot(data, bus_size=1000, gen_size=100, branch_size=2, connector_size=10)","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"Aliases to overide all node and edge sizes.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot(data, node_size=1000, edge_size=10, width=300, height=300)","category":"page"},{"location":"examples/basic examples/#Visualizing-System-Data","page":"Basic Examples","title":"Visualizing System Data","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"Component data values from the PowerModels dictionary can be plotted by specfying the dictionary key. The key can be either a string or a symbol.  The data type can be :ordinal, :nominal, or :quantitative.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"p = powerplot(data, bus_data=\"bus_type\",\n                    bus_data_type=\"nominal\",\n                    branch_data=\"index\",\n                    branch_data_type=\"ordinal\",\n                    gen_data=\"pmax\",\n                    gen_data_type=\"quantitative\",\n                    width=300, height=300\n)","category":"page"},{"location":"examples/basic examples/#Color-Ranges","page":"Basic Examples","title":"Color Ranges","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"Color ranges are automatically interpolated from a range that is provided.  If only a single color is given, the component will not change color based on the data.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"p = powerplot(data,\n                    gen_data=\"pmax\",\n                    gen_data_type=\"quantitative\",\n                    gen_color=[\"#232323\",\"#AAFAFA\"],\n                    width=300, height=300\n)","category":"page"},{"location":"examples/basic examples/#Color-Schemes","page":"Basic Examples","title":"Color Schemes","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"Color schemes from the package ColorSchemes.jl can also be used to specify a color range.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"using ColorSchemes\npowerplot(data;\n            gen_data=:pmax,\n            gen_color=colorscheme2array(ColorSchemes.colorschemes[:summer]),\n            gen_data_type=:quantitative,\n            width=300, height=300\n)","category":"page"},{"location":"examples/basic examples/#Power-Flow","page":"Basic Examples","title":"Power Flow","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"If the variables pf (power from) and pt (power to) exist in the data, power flow directions can be visualized using the show_flow boolean toggle (true by default).","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"# Solve AC power flow and add values to data dictionary\nusing Ipopt, PowerModels, PowerPlots\ndata = parse_file(\"$(joinpath(dirname(pathof(PowerModels)), \"..\"))/test/data/matpower/case5.m\")\nresult = solve_ac_opf(data, Ipopt.Optimizer)\nupdate_data!(data, result[\"solution\"])\n\np = powerplot(data, show_flow=true)","category":"page"},{"location":"examples/basic examples/#Multinetworks","page":"Basic Examples","title":"Multinetworks","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"powerplot detects if a network is a multinetwork and will create a slider to select which network to view.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"data_mn = PowerModels.replicate(data, 5)\n\n# create random data for each time period\nfor (nwid,nw) in data_mn[\"nw\"]\n    for (branchid,branch) in nw[\"branch\"]\n        branch[\"value\"] = rand()\n    end\nend\n\npowerplot(data_mn, branch_data=:value, branch_data_type=:quantitative)","category":"page"},{"location":"examples/basic examples/#Distribution-Grids","page":"Basic Examples","title":"Distribution Grids","text":"","category":"section"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"Open a three-phase distribution system case using PowerModelsDistribution.jl and run the command powerplot on the data.","category":"page"},{"location":"examples/basic examples/","page":"Basic Examples","title":"Basic Examples","text":"using PowerModelsDistribution\nusing PowerPlots\neng = PowerModelsDistribution.parse_file(\"$(joinpath(dirname(pathof(PowerModelsDistribution)), \"..\"))/test/data/opendss/case3_unbalanced.dss\")\nmath = transform_data_model(eng)\npowerplot(math)\n# example works, but fails to run in documentation","category":"page"},{"location":"#PowerPlots.jl-Documentation","page":"Home","title":"PowerPlots.jl Documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = PowerPlots","category":"page"},{"location":"","page":"Home","title":"Home","text":"PowerPlots.jl is a package for visualizing power grids, using the data spec from PowerModels.jl and PowerModelsDistribution.jl. This package uses VegaLite.jl as the plotting backend.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"pkg> add PowerPlots","category":"page"},{"location":"#Basic-Overview","page":"Home","title":"Basic Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Open a power systems case using PowerModels.jl and run the command powerplot on the data.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using PowerModels\nusing PowerPlots\ncase = parse_file(\"case14.m\")\npowerplot(case)","category":"page"},{"location":"","page":"Home","title":"Home","text":"The function creates a layout for the graph and plots the system.  The plot is interactive, and hovering over a component allows you to see the component data. By default, plots are displayed in a browser window but using ElectronDisplay.jl will display plots in its own window.  Using the VSCode extension will display plots in the plot pane.","category":"page"},{"location":"","page":"Home","title":"Home","text":"NOTE: Interactive VegaLite plots are not currently supported by some notebooks, like Jupyter Notebook. If you use Jupyter Notebook, you can using ElectronDisplay.jl to display interactive plots.","category":"page"},{"location":"#Creating-Visualizations","page":"Home","title":"Creating Visualizations","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The primary use for PowerPlots is to visualize data in the PowerModels dictionary.  Each component can specify a data value to visualize, such as the pmax for the generators or the rate_a of the branches.","category":"page"},{"location":"","page":"Home","title":"Home","text":"powerplot(case;\n    gen_data=:pmax,\n    branch_data=:rate_a,\n    branch_color=[:white,:blue],\n    branch_data_type=:quantitative\n)","category":"page"},{"location":"#Altering-Data","page":"Home","title":"Altering Data","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"New data can be added to the dictionary and visualized as well.","category":"page"},{"location":"","page":"Home","title":"Home","text":"case[\"gen\"][\"1\"][\"gen_type\"] = \"PV\"\ncase[\"gen\"][\"2\"][\"gen_type\"] = \"Coal\"\ncase[\"gen\"][\"3\"][\"gen_type\"] = \"Hydro\"\ncase[\"gen\"][\"4\"][\"gen_type\"] = \"CCGT\"\ncase[\"gen\"][\"5\"][\"gen_type\"] = \"Wind\"\n\nusing ColorSchemes\npowerplot(case;\n    gen_data=:gen_type,\n    gen_color = colorscheme2array(ColorSchemes.colorschemes[:seaborn_deep]),\n    bus_color=:black\n)","category":"page"},{"location":"parameters/#Parameter-Arguments","page":"Parameters","title":"Parameter Arguments","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The following parameters can be used to as keyword arguments to modify a plot","category":"page"},{"location":"parameters/#Plot-parameters","page":"Parameters","title":"Plot parameters","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"These paramters modify the entire plot.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"Keyword Description Default\nwidth width of the plot in pixels 500\nheight height of the plot in pixels 500\nlayout_algorithim algorithm for generating network layout (see Layouts) kamada_kawai\nfixed use fixed coordinates from network model false\nparallel_edge_offset offset distance between parallel edges 0.05","category":"page"},{"location":"parameters/#Component-Parameters","page":"Parameters","title":"Component Parameters","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"These parameters modify a specific component.","category":"page"},{"location":"parameters/#Toggles","page":"Parameters","title":"Toggles","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"There are several component 'toggle' parameters that control whether certain display properties of components are on or off. These accept boolean values.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"Keyword Description Default\nshow_flow whether flow arrows are displayed true\nshow_flow_legend whether the legend for the flow arrows is shown false","category":"page"},{"location":"parameters/#Color","page":"Parameters","title":"Color","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The color arguments can accept several inputs.  A single color can be specified using a color name as a symbol or a string.  CSS color names are supported.  In addition, hex color values in a string are supported.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"powerplot(case; branch_color=:yellow)\npowerplot(case; branch_color=\"yellow\")\npowerplot(case; branch_color=\"#FFA71A\")","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"A color range can be created by using several colors in an array. The range is used when component data is specified.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"powerplot(case; branch_color=[:red, \"yellow\", \"#0000FF\"])","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"A color scheme from ColorSchemes.jl can be used, but the ColorScheme must be converted to an array of colors that can be interpreted by VegaLite.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"using ColorSchemes\npowerplot(case; branch_color=colorscheme2array(ColorSchemes.colorschemes[:tableau_10]))","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"Keyword Description Default\nbranch_color set the color of a branch [\"#3182BD\", \"#5798CA\", \"#7CAED6\", \"#A0C5E2\", \"#C6DBEF\"]\ndcline_color set the color of a DC line [\"#756BB1\", \"#8F87C0\", \"#A8A3CE\", \"#C0BEDC\", \"#DADAEB\"]\nconnector_color set the color of a connector [:gray]\ngen_color set the color of a generator [\"#E6550D\", \"#EB7433\", \"#F19358\", \"#F8B17C\", \"#FDD0A2\"]\nbus_color set the color of a bus [\"#31A354\", \"#57B46F\", \"#7CC68A\", \"#A1D8A5\", \"#C7E9C0\"]\nnode_color set the color of all buses and generators N/A\nedge_color set the color of all branches, DC lines, and connectors N/A\nflow_color set the color of flow arrows :black","category":"page"},{"location":"parameters/#Size","page":"Parameters","title":"Size","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The size argument sets the size of a component.  The size does not vary with data in the base plot.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"Keyword Description Default\nbranch_size set the size of a branch 5\ndcline_size set the size of a DC line 5\nconnector_size set the size of a connector 3\ngen_size set the size of a generator 500\nbus_size set the size of a bus 500\nnode_size set the size of all buses and generators N/A\nedge_size set the size of all branches, DC lines, and connectors N/A\nflow_arrow_size_range set size range for power flow arrows [500,3000]","category":"page"},{"location":"parameters/#Data","page":"Parameters","title":"Data","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The data argument selects the data from the component dictionary to use in the visualization.  The data argument can be a string or a symbol.  The data value modifes the color of a component based on the color range.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"powerplot(case; gen_data=:pmax)\npowerplot(case; gen_data=:pmin)","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"Keyword Description Default\nbranch_data set the data of a branch \"ComponentType\"\ndcline_data set the data of a DC line \"ComponentType\"\nconnector_data set the data of a connector \"ComponentType\"\ngen_data set the data of a generator \"ComponentType\"\nbus_data set the data of a bus \"ComponentType\"","category":"page"},{"location":"parameters/#Data-Type","page":"Parameters","title":"Data Type","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The Data Type in VegaLite can be :nominal, :ordinal, or :quantintative.  :nominal and :ordinal are both discrete values, and :quantitative is continuous.  In the context of the simple powerplot, there is no distinction  between :nominal and :ordinal.","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"powerplot(case; gen_data=:pg, gen_data_type=:quantitative) # the pg is continous, so use a continous scale\npowerplot(case; gen_data=:index, gen_data_type=:nominal) # the index is a discrete value, so use a discrete scale","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"Keyword Description Default\nbranch_data_type set the data type of a branch :nominal\ndcline_data_type set the data type of a DC line :nominal\nconnector_data_type set the data type of a connector :nominal\ngen_data_type set the data type of a generator :nominal\nbus_data_type set the data type of a bus :nominal","category":"page"},{"location":"data_transformations/powermodelsgraphs/#PowerModelsGraph","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"","category":"section"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"The PowerModels data dictionary is useful for storing and accessing data about a grid, but a graph structure can be useful to analyse metrics like node degree or eigenvector centrality.  It is used in this pacakge to create Layouts for plotting networks.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"mutable struct PowerModelsGraph\n    graph::Graphs.SimpleDiGraph\n    node_comp_map::Dict{Int,Tuple{String, String}}\n    edge_comp_map::Dict{Tuple{Int,Int},Tuple{String, String}}\n    edge_connector_map::Dict{Tuple{Int,Int},Tuple{String, String}}","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"The PowerModelsGraph type stores a directed graph of the network, and mapping between the nodes and edges and the components that they refer to.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"The node_comp_map is a Dictionary where the keys are the graph nodes and the values are a tuple of the component type and id, e.g.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"node_comp_map = Dict(\n    1 => (\"bus\",\"2\"),\n    2 => (\"gen\",\"4\")\n)","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"The edge_comp_map is a similar mapping for components that form the edges of the network.  Here, the keys are the endpoints of the directed edge.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"edge_comp_map = Dict(\n    (1,2) => (\"branch\",\"1\"),\n    (2,3) => (\"dcline\",\"4\")\n)","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"Connectors are additional lines that connect non-bus nodes to a bus, for example generators.  The mapping is similar to the edge_comp_map.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"edge_connector_map = Dict(\n    (1,4) => (\"gen\",\"1\"),\n    (1,5) => (\"gen\",\"2\")\n)","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"To create a PowerModelsGraph, the component types for nodes and edges must be specified.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"PowerModelsGraph(data::Dict{String,<:Any},\n                node_types::Vector{String},\n                edge_types::Vector{String}\n)","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"There is also a convinient function with default node and edge types as keyword arguments.","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"PowerModelsGraph(data::Dict{String,<:Any};\n                node_types=[\"bus\",\"gen\",\"storage\"]::Array{String,1},\n                edge_types=[\"branch\",\"dcline\",\"switch\"]::Array{String,1}\n)","category":"page"},{"location":"data_transformations/powermodelsgraphs/#PowerModelsGraph-Example","page":"PowerModelsGraph","title":"PowerModelsGraph Example","text":"","category":"section"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"using PowerModels\nusing PowerPlots\ncase = parse_file(\"case14.m\")\n\n# Specify node and edge types\ncase_PMG = PowerModelsGraph(case, [\"bus\",\"gen\"], [\"branch\",\"dcline\"])\n\n# Use default node and edge types\ncase_PMG = PowerModelsGraph(case)","category":"page"},{"location":"data_transformations/powermodelsgraphs/#Using-PowerModelsGraph","page":"PowerModelsGraph","title":"Using PowerModelsGraph","text":"","category":"section"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"using PowerModels\nusing PowerPlots\nusing Graphs\ncase = parse_file(\"case14.m\")\n\n# Create a graph where buses are nodes and branches are edges\ncase_PMG = PowerModelsGraph(case, [\"bus\"], [\"branch\"]);","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"g = Graphs.SimpleGraph(case_PMG.graph) # Does the graph contain cycles?\nis_cyclic(g)","category":"page"},{"location":"data_transformations/powermodelsgraphs/","page":"PowerModelsGraph","title":"PowerModelsGraph","text":"# Get the adjacency matrix\nadjacency_matrix(case_PMG.graph)","category":"page"}]
}
