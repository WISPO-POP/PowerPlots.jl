module PowerPlots

import InfrastructureModels
import PowerModels
import Statistics: mean, std
import LinearAlgebra: norm
import LightGraphs

import Colors
import Colors: @colorant_str

import Plots

# using NetworkLayout
import PyCall
const nx = PyCall.PyNULL()

function __init__()
    copy!(nx, PyCall.pyimport_conda("networkx", "networkx"))
end


include("core/types.jl")  # must be first to properly define new types
include("core/data.jl")
include("core/options.jl")

include("plots/graph.jl")
include("plots/network_status.jl")
include("plots/branch_flow.jl")
include("plots/system_voltage.jl")
include("plots/networks.jl")

include("layouts/common.jl")
include("layouts/layout_engines.jl")

include("graph/common.jl")

include("core/export.jl")  # must be last to properly export all functions


end # module
