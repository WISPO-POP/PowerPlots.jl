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
            output != nothing && output != """Data column "ComponentType" does not exist for DC line"""
        end

        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case)) # vanilla function call should not cause any unexpected error messages
        @test_nolog(logger, "error", r".+", powerplot(case)) # vanilla function call should not cause any error messages

        # Color attribute tests
        @test_nolog(logger, "error", r".+", powerplot(case; bus_color=:red, branch_color=["blue", :green])) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; bus_color=:red, branch_color=["blue", :green])) # test valid colors
        @test_warn(logger, r"Ignoring unexpected attribute (.*)$", powerplot(case; fake_attr=nothing)) # test ignoring of invalid attributes
        @test_warn(logger, r"Color value for (.*) should be given as symbol or string$", powerplot(case; bus_color=0)) # test invalid color type warning
        @test_warn(logger, r"Invalid color (.*) given for (.*)$", powerplot(case; bus_color=:goosegray)) # test invalid CSS color warning
        @test_warn(logger, r"Invalid color (.*) given for (.*)$", powerplot(case; bus_color=[:red, 0])) # test array with invalid CSS colors

        # Numeric attribute tests
        @test_nolog(logger, "error", r".+", powerplot(case; width=100, height="100")) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; width=100, height="100")) # test valid numeric attribute
        @test_warn(logger, r"Invalid number (.*) given for (.*)$", powerplot(case; width="abcd")) # test invalid numeric string given for numeric attribute
        @test_warn(logger, r"Value for (.*) should be given as a number or numeric String$", powerplot(case; width=:zero)) # test invalid datatype given for numeric attribute

        # Data label tests
        @test_nolog(logger, "error", r".+", powerplot(case; bus_data=:ComponentType, gen_data="ComponentType",
            bus_data_type=:ordinal, gen_data_type="nominal")) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, powerplot(case; bus_data=:ComponentType,
            gen_data="ComponentType", bus_data_type=:ordinal, gen_data_type="nominal")) # test valid function call
        @test_warn(logger, r"Value for (.*) should be given as a String or Symbol$", powerplot(case; bus_data=0)) # test invalid datatype passed into data label
        @test_warn(logger, r"Data column :blah does not exist for (.*)$", powerplot(case; bus_data=:blah)) # test invalid data column
        @test_warn(logger, r"Data type :blah not a valid VegaLite data type$", powerplot(case; bus_data_type=:blah)) # test invalid data type

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
        @test size(df.branch) == (7,20)

        data_mn = PowerModels.replicate(data,2)
        df_mn = PowerModelsDataFrame(data_mn)
        @test typeof(df_mn) <:PowerModelsDataFrame # these functions didn't error
        @test size(df_mn.branch) == (14,21)

        comp_df = comp_dict_to_dataframe(data["branch"])
        @test size(comp_df) == (7,19)
    end

    @testset "PowerModelsGraph and Layouts" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        PMG = PowerModelsGraph(case)
        # positions = layout_graph_kamada_kawai!(PMG)
        # @test size(positions) == (10,)
        # @test typeof(positions) == Vector{Vector{Float64}}

        layout_network(case, layout_algorithm=Shell)
        layout_network(case, layout_algorithm=SFDP)
        # layout_network(case, layout_algorithm=Buchheim) # requires a tree-network
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
    end

    @testset "Multinetwork plots" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        case_mn = replicate(case, 2)

        @testset "Basic multinetwork plot" begin
            p = powerplot(case)
            @test true # above line does not error
        end

        @testset "Layered multinetwork plot" begin
            p = powerplot(case)
            pp = powerplot!(p, case)
            @test length(keys(pp.layer))==5 # 1 layer first plot, 4 component layers from second plot
        end
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

end

PowerModels.logger_config!(prev_level); # reset PowerModels logger to previous level
