using PowerPlots
using Test

using PowerModels
import Ipopt

using Memento
using Memento.TestUtils

prev_level = getlevel(getlogger(PowerModels))
PowerModels.logger_config!("error") # silence PowerModels logger while testing
data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

@testset "PowerPlots.jl" begin
    # Write your own tests here.

    @testset "Plots Backend" begin
        graph = build_graph_network(data; exclude_sources=true)
        plot_network(data)
        plot_network!(data)

        plot_network_status!(graph)
        plot_system_voltage(data)

        result = run_opf(data, DCPPowerModel, Ipopt.Optimizer)
        PowerModels.update_data!(data, result["solution"])
        plot_power_flow(data)

        # these functions work if we got this far
        @test true # these functions didn't error
    end

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

        @test_nolog(logger, "warn", is_unexpected_warning, plot_vega(case)) # vanilla function call should not cause any unexpected error messages
        @test_nolog(logger, "error", r".+", plot_vega(case)) # vanilla function call should not cause any error messages

        # Color attribute tests
        @test_nolog(logger, "error", r".+", plot_vega(case; bus_color=:red, branch_color=["blue", :green])) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, plot_vega(case; bus_color=:red, branch_color=["blue", :green])) # test valid colors
        @test_warn(logger, r"Ignoring unexpected attribute (.*)$", plot_vega(case; fake_attr=nothing)) # test ignoring of invalid attributes
        @test_warn(logger, r"Color value for (.*) should be given as symbol or string$", plot_vega(case; bus_color=0)) # test invalid color type warning
        @test_warn(logger, r"Invalid color (.*) given for (.*)$", plot_vega(case; bus_color=:goosegray)) # test invalid CSS color warning
        @test_warn(logger, r"Invalid color (.*) given for (.*)$", plot_vega(case; bus_color=[:red, 0])) # test array with invalid CSS colors

        # Numeric attribute tests
        @test_nolog(logger, "error", r".+", plot_vega(case; width=100, height="100")) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, plot_vega(case; width=100, height="100")) # test valid numeric attribute
        @test_warn(logger, r"Invalid number (.*) given for (.*)$", plot_vega(case; width="abcd")) # test invalid numeric string given for numeric attribute
        @test_warn(logger, r"Value for (.*) should be given as a number or numeric String$", plot_vega(case; width=:zero)) # test invalid datatype given for numeric attribute

        # Data label tests
        @test_nolog(logger, "error", r".+", plot_vega(case; bus_data=:ComponentType, gen_data="ComponentType",
            bus_data_type=:ordinal, gen_data_type="nominal")) # valid function call should not cause any error messages
        @test_nolog(logger, "warn", is_unexpected_warning, plot_vega(case; bus_data=:ComponentType,
            gen_data="ComponentType", bus_data_type=:ordinal, gen_data_type="nominal")) # test valid function call
        @test_warn(logger, r"Value for (.*) should be given as a String or Symbol$", plot_vega(case; bus_data=0)) # test invalid datatype passed into data label
        @test_warn(logger, r"Data column :blah does not exist for (.*)$", plot_vega(case; bus_data=:blah)) # test invalid data column
        @test_warn(logger, r"Data type :blah not a valid VegaLite data type$", plot_vega(case; bus_data_type=:blah)) # test invalid data type

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

        data_mn = PowerModels.replicate(data,2)
        df_mn = PowerModelsDataFrame(data_mn)
        @test true # these functions didn't error
    end
end

PowerModels.logger_config!(prev_level); # reset PowerModels logger to previous level
