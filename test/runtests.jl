using PowerPlots
using Test

using PowerModels

data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

@testset "PowerPlots.jl" begin
    # Write your own tests here.
    @test graph = build_graph_network(case; exclude_sources=true)
    @test plot_network(data)
    @test plot_network!(data)

    @test plot_power_flow(data)
    @test plot_network_status!(graph)
    @test plot_system_voltage(data)
end
