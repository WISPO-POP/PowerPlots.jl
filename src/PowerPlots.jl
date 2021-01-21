module PowerPlots

import InfrastructureModels
import PowerModels
import Statistics: mean, std
import LinearAlgebra: norm
import LightGraphs

import Colors
import Colors: @colorant_str

import Plots

import VegaLite
import DataFrames
import Memento


# using NetworkLayout

import PyCall

_PM = PowerModels
_IM = InfrastructureModels

const nx = PyCall.PyNULL()
const scipy = PyCall.PyNULL()

function __init__()
    copy!(nx, PyCall.pyimport_conda("networkx", "networkx"))
    copy!(scipy, PyCall.pyimport_conda("scipy", "scipy"))
end



include("core/types.jl")  # must be first to properly define new types
include("core/data.jl")
include("core/options.jl")
include("core/utils.jl")

include("plots/graph.jl")
include("plots/network_status.jl")
include("plots/power_flow.jl")
include("plots/system_voltage.jl")
include("plots/networks.jl")

include("plots/power_vega.jl")

include("layouts/common.jl")
include("layouts/layout_engines.jl")

include("graph/common.jl")

include("core/export.jl")  # must be last to properly export all functions


end # module
