module PowerPlots

import InfrastructureModels
import PowerModels
import Statistics: mean, std
import LinearAlgebra
import LightGraphs

import NetworkLayout
import NetworkLayout:Spring

import Colors
import Colors: @colorant_str

import Plots

import VegaLite
import DataFrames
import Memento
import JSON

#imports for kamada kawai layout
import GeometryBasics
import NLopt
import OMEinsum
import RecursiveArrayTools


# using NetworkLayout

import PyCall

_PM = PowerModels
_IM = InfrastructureModels

const nx = PyCall.PyNULL()
const scipy = PyCall.PyNULL()

# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

"Suppresses information and warning messages output for PowerPlots, for fine grained control use the Memento package"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.  Use the Memento package for more fine-grained control of logging.")
    Memento.setlevel!(Memento.getlogger(PowerPlots), "error")
end

"allows the user to set the logging level without the need to add Memento"
function logger_config!(level)
    Memento.config!(Memento.getlogger("PowerPlots"), level)
end



function __init__()
    copy!(nx, PyCall.pyimport_conda("networkx", "networkx"))
    copy!(scipy, PyCall.pyimport_conda("scipy", "scipy"))

    # Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerPlots)`
    # NOTE: If this line is not included then the precompiled `PowerPlots._LOGGER` won't be registered at runtime.
    Memento.register(_LOGGER)
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

include("plots/kamada_kawai.jl")
include("plots/power_vega.jl")

include("layouts/common.jl")
include("layouts/layout_engines.jl")

include("graph/common.jl")

include("core/export.jl")  # must be last to properly export all functions


end # module
