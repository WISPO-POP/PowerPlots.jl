using PowerPlots
using Test

using PowerModels
import Ipopt

PowerModels.silence()
data = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

@testset "PowerPlots.jl" begin
    # Write your own tests here.
     graph = build_graph_network(data; exclude_sources=true)
     plot_network(data)
     plot_network!(data)


     plot_network_status!(graph)
     plot_system_voltage(data)

     result = run_opf(data, DCPPowerModel, Ipopt.Optimizer)
     PowerModels.update_data!(data, result["solution"])
     plot_power_flow(data)

     # these functions work if we got this far
     @test true

end
