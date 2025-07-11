using PowerPlots
using Test

using PowerModels
# import Ipopt

using Memento
using Memento.TestUtils

prev_level = getlevel(getlogger(PowerModels))
PowerModels.logger_config!("error") # silence PowerModels logger while testing
data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

@testset "PowerPlots.jl" begin



    @testset "VegaLite Backend" begin
        ## Test vegalite plotting
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

        # get the logger of PowerPlots
        logger = getlogger(PowerPlots)
        start_level = getlevel(logger)
        PowerPlots.logger_config!("info") # show everything

        # case5.m should not cause any warning messages besides this one
        function is_unexpected_warning(output::String)
            !isnothing(output)
        end

        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case)) # vanilla function call should not cause any unexpected error messages
        @test_nolog(logger, "error", r".+", powerplot(case)) # vanilla function call should not cause any error messages

        # Color attribute tests
        @test_nolog(logger, "error", r".+", powerplot(case; bus=(:color=>:red), branch=(:color=>["blue", :green]))) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; bus=(:color=>:red), branch=(:color=>["blue", :green]))) # test valid colors
        @test_warn(logger, r"Ignoring unexpected attribute (.*)$", powerplot(case; fake_attr=nothing)) # test ignoring of invalid attributes
        @test_warn(logger, r"Color value for (.*) should be given as symbol or string$", powerplot(case; bus=(:color=>0))) # test invalid color type warning
        @test_warn(logger, r"Invalid color (.*) given for (.*)$", powerplot(case; bus=(:color=>:goosegray))) # test invalid CSS color warning
        @test_warn(logger, r"Invalid color (.*) given for (.*)$", powerplot(case; bus=(:color=>[:red,0]))) # test array with invalid CSS colors

        # Numeric attribute tests
        @test_nolog(logger, "error", r".+", powerplot(case; width=100, height="100")) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; width=100, height="100")) # test valid numeric attribute
        @test_warn(logger, r"Invalid number (.*) given for (.*)$", powerplot(case; width="abcd")) # test invalid numeric string given for numeric attribute
        @test_warn(logger, r"Value for (.*) should be given as a number or numeric String$", powerplot(case; width=:zero)) # test invalid datatype given for numeric attribute

        # Boolean attribute tests
        @test_nolog(logger, "error", r".+", powerplot(case; branch=(:show_flow_legend=>false))) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; branch=(:show_flow_legend=>true))) # test valid boolean attribute
        @test_warn(logger, r"Value for (.*) should be given as a Bool$", powerplot(case; branch=(:show_flow_legend=>"true"))) # test invalid datatype

        # Data label tests
        @test_nolog(logger, "error", r".+", powerplot(case; bus=(:data=>"ComponentType", :data_type=>:ordinal), gen=(:data=>"ComponentType", :data_type=>"nominal"))) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; bus=(:data=>:ComponentType, :data_type=>:ordinal),
        gen=(:data=>:ComponentType, :data_type=>:nominal))) # test valid function call
        @test_warn(logger, r"Value for (.*) should be given as a String or Symbol$", powerplot(case; bus=(:data=>0))) # test invalid datatype passed into data label
        @test_warn(logger, r"Data column :blah does not exist for (.*)$", powerplot(case; bus=(:data=>:blah))) # test invalid data column
        @test_warn(logger, r"Data type :blah not a valid VegaLite data type$", powerplot(case; bus=(:data_type=>:blah))) # test invalid data type

        # Layout algorithm tests
        @test_nolog(logger, "warn", r".+", powerplot(case, layout_algorithm=Shell, nlist=[1:3,4:7]))
        @test_nolog(logger, "warn", r".+", powerplot(case, layout_algorithm=SFDP, tol=0.01, C=0.2, K=1.0, iterations=100))
        @test_nolog(logger, "warn", r".+", powerplot(case, layout_algorithm=Spring, C=2.0, iterations=100, initialtemp=2.0, ))
        @test_nolog(logger, "warn", r".+", powerplot(case, layout_algorithm=Stress, iterations=100, abstols=0.0, reltols=10e-6, abstolx=10e-6, uncon_dist=(max_d,N)->maxd*N^(1/3), weights=Array{Float64}(undef, 0, 0)))
        @test_nolog(logger, "warn", r".+", powerplot(case, layout_algorithm=SquareGrid, cols=:auto, dx=1.0, dy=-1.0, skip=[(1,2),(2,3)], ))
        @test_nolog(logger, "warn", r".+", powerplot(case, layout_algorithm=Spectral, nodeweights=[1.0, 2.0, 3.0, 4.0, 5.0, 6.0]))

        PowerPlots.logger_config!(start_level) # restore logger to initial level
    end

    @testset "PowerPlotsLogger" begin
        # get the logger of PowerPlots
        logger = getlogger(PowerPlots)

        start_level = getlevel(logger) # get initial log level
        # test logger configuration functions
        PowerPlots.logger_config!("info")
        @test getlevel(logger) == "info"
        PowerPlots.logger_config!("warn")
        @test getlevel(logger) == "warn"
        PowerPlots.silence()
        @test getlevel(logger) == "error"

        PowerPlots.logger_config!(start_level) # restore logger to initial level
    end

    @testset "PowerModelsDataFrame" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        df = PowerModelsDataFrame(data)
        @test typeof(df) <:PowerModelsDataFrame
        @test size(df.components[:branch]) == (7,20)

        data_mn = PowerModels.replicate(data,2)
        df_mn = PowerModelsDataFrame(data_mn)
        @test typeof(df_mn) <:PowerModelsDataFrame # these functions didn't error
        @test size(df_mn.components[:branch]) == (14,21)

        comp_df = comp_dict_to_dataframe(data["branch"])
        @test size(comp_df) == (7,19)
    end

    @testset "PowerModelsGraph and Layouts" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        PMG = PowerModelsGraph(case)

        layout_network(case, layout_algorithm=Shell)
        layout_network(case, layout_algorithm=SFDP)
        layout_network(case, layout_algorithm=Spring)
        layout_network(case, layout_algorithm=Stress)
        layout_network(case, layout_algorithm=SquareGrid)
        layout_network(case, layout_algorithm=Spectral)
        layout_network(case, layout_algorithm=kamada_kawai)


        case["bus"]["1"]["xcoord_1"] = 1.0
        case["bus"]["1"]["ycoord_1"] = 2.0
        case = layout_network(case, fixed=true)
        @test case["bus"]["1"]["xcoord_1"] == 1.0
        @test case["bus"]["1"]["ycoord_1"] == 2.0

        # check functionality when nodes exceeds branches
        case["gen"]["6"] = deepcopy(case["gen"]["1"])
        case["gen"]["7"] = deepcopy(case["gen"]["1"])
        case["gen"]["8"] = deepcopy(case["gen"]["1"])
        case["gen"]["9"] = deepcopy(case["gen"]["1"])
        case["gen"]["11"] = deepcopy(case["gen"]["1"])
        case["gen"]["12"] = deepcopy(case["gen"]["1"])
        case["gen"]["13"] = deepcopy(case["gen"]["1"])
        case["gen"]["14"] = deepcopy(case["gen"]["1"])
        case["gen"]["15"] = deepcopy(case["gen"]["1"])
        PMG = PowerModelsGraph(case)

        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        powerplot(case)
        case = layout_network(case)
        powerplot(case, fixed=true)

    end

    @testset "Multinetwork plots" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        case_mn = replicate(case, 2)

        @testset "Basic multinetwork plot" begin
            p = powerplot(case_mn)
            @test true # above line does not error
        end

        @testset "Layered multinetwork plot" begin
            p = powerplot(case_mn)
            pp = powerplot!(p, case_mn)
            @test length(keys(pp.layer))==6 # 1 layer first plot, 5 component layers from second plot
        end
    end

    @testset "filter plot components" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        p=powerplot(case, node_components=[:bus], edge_components=[:branch], connected_components=Symbol[])
        @test length(keys(p.layer))==2

        # check if all plot functions support this feature
        powerplot!(p, case, node_components=[:bus], edge_components=[:branch], connected_components=Symbol[])
        @test length(keys(p.layer))==2
        case_mn = PowerModels.replicate(case, 2)
        p=powerplot(case, node_components=[:bus], edge_components=[:branch], connected_components=Symbol[])
        @test length(keys(p.layer))==2
        powerplot!(p, case, node_components=[:bus], edge_components=[:branch], connected_components=Symbol[])
        @test length(keys(p.layer))==2
    end

    @testset "Experimental" begin
        using PowerPlots.Experimental
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        plot1 = powerplot(case)
        PowerPlots.Experimental.add_zoom!(plot1)
        @test true # what do I test here?


        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        plot1 = powerplot(case)
        PowerPlots.Experimental.cartesian2geo!(plot1)
        @test true # what do I test here?

    end

    @testset "Distribution Grids" begin
        using PowerModelsDistribution
        PowerModelsDistribution.silence!()
        eng = PowerModelsDistribution.parse_file("$(joinpath(dirname(pathof(PowerModelsDistribution)), ".."))/test/data/opendss/case3_unbalanced.dss")
        math = transform_data_model(eng)
        p = powerplot(math)
        @test true # what do I test here?
        p = powerplot!(p,math)
        @test true

        eng = PowerModelsDistribution.parse_file("$(joinpath(dirname(pathof(PowerModelsDistribution)), ".."))/test/data/opendss/test2_master.dss")
        math = transform_data_model(eng)
        p = powerplot(math)
        @test length(p.layer)==9 # branch, switch, transformer, connector bus, gen, load in figure


        @testset "Multinetwork Distribution Grids" begin
            eng = PowerModelsDistribution.parse_file("$(joinpath(dirname(pathof(PowerModelsDistribution)), ".."))/test/data/opendss/case3_unbalanced.dss")
            eng_mn = PowerModelsDistribution.make_multinetwork(eng)
            math_mn = transform_data_model(eng_mn)
            p = powerplot(math_mn)
            @test true
            pp = powerplot!(p,math_mn)
            @test true
        end

    end

    @testset "Parameter Settings" begin
        @testset "parallel_edge_offset" begin
            data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
            data["dcline"]["1"]=Dict{String,Any}("index"=>1, "f_bus"=>1, "t_bus"=>2)

            data = layout_network(data)
            offset_parallel_edges!(data,0.0) # no offset, ensures coordinates values are set for both edges
            @test data["dcline"]["1"]["xcoord_1"] == data["branch"]["1"]["xcoord_1"]
            @test data["dcline"]["1"]["xcoord_2"] == data["branch"]["1"]["xcoord_2"]

            offset_parallel_edges!(data,0.05) # offset, ensures coordinates values are different
            dist = sqrt((data["dcline"]["1"]["xcoord_1"] - data["branch"]["1"]["xcoord_1"])^2+
                (data["dcline"]["1"]["ycoord_1"] - data["branch"]["1"]["ycoord_1"])^2
            )
            @test isapprox(dist, 0.05*2; atol=1e-8)

            # test edge types in offset
            data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
            data["dcline"]["1"]=Dict{String,Any}("index"=>1, "f_bus"=>1, "t_bus"=>2)
            data = layout_network(data)
            offset_parallel_edges!(data,0.0, edge_types=[:branch]) # do not offset dc lines
            @test haskey(data["branch"]["1"], "xcoord_1")==false
            @test haskey(data["branch"]["1"], "xcoord_2")==false

        end
    end

    @testset "Output" begin
        p = powerplot(data)
        Base.Filesystem.mktempdir() do folder
            save(joinpath(folder, "test1.svg"), p)
            @test isfile(joinpath(folder, "test1.svg"))

            save(joinpath(folder, "test1.png"), p)
            @test isfile(joinpath(folder, "test1.png"))

            save(joinpath(folder, "test1.pdf"), p)
            @test isfile(joinpath(folder, "test1.pdf"))

            save(joinpath(folder, "test1.html"), p)
            @test isfile(joinpath(folder, "test1.html"))
        end
    end

    @testset "Filter hover" begin
        p = powerplot(data,
            load=(:hover=>["pd"]),
            gen=(:hover=>["pg", "pmin", "pmax"]),
            bus=(:hover=>[:vmin, :vmax]),
            branch=(:hover=>["br_r", "br_x"]),
        )

        @test length(p.layer[1]["layer"][1]["encoding"]["tooltip"]) == 2
        @test length(p.layer[2]["encoding"]["tooltip"]) == 8 # all values in the component data
        @test length(p.layer[3]["encoding"]["tooltip"]) == 2
        @test length(p.layer[4]["encoding"]["tooltip"]) == 3
        @test length(p.layer[5]["encoding"]["tooltip"]) == 1
    end

end

PowerModels.logger_config!(prev_level); # reset PowerModels logger to previous level

