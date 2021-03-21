using PowerPlots
using Test

using PowerModels
import Ipopt

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
        plot_vega(case)
        @test true # these functions didn't error
    end

    @testset "PowerModelsDataFrame" begin
        case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")
        df = PowerModelsDataFrame(data)

        data_mn = PowerModels.replicate(data,2)
        df_mn = PowerModelsDataFrame(data_mn)
        @test true # these functions didn't error
    end
end
