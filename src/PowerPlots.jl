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

import VegaLite
import DataFrames
import Memento

#imports for kamada kawai layout
import GeometryBasics
import NLopt
import OMEinsum
import RecursiveArrayTools


# import PyCall

_PM = PowerModels
_IM = InfrastructureModels


# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

# Which symbols to exclude from the export
const _EXCLUDE_SYMBOLS = []
function _hide_function(f::Function) # adds the given function to the excluded symbols
    push!(_EXCLUDE_SYMBOLS, Symbol(f))
end


"Suppresses information and warning messages output for PowerPlots, for fine grained control use the Memento package"
function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.  Use the Memento package for more fine-grained control of logging.")
    Memento.setlevel!(Memento.getlogger(PowerPlots), "error")
end
_hide_function(silence) # do not export, potential conflict of PowerModels.silence()

"allows the user to set the logging level without the need to add Memento"
function logger_config!(level)
    Memento.config!(Memento.getlogger("PowerPlots"), level)
end
_hide_function(logger_config!) # do not export, potential conflict of PowerModels.logger_config!()


function __init__()
    # Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerPlots)`
    # NOTE: If this line is not included then the precompiled `PowerPlots._LOGGER` won't be registered at runtime.
    Memento.register(_LOGGER)
end



include("core/types.jl")  # must be first to properly define new types
include("core/data.jl")
include("core/options.jl")
include("core/utils.jl")

include("plots/power_vega.jl")

include("layouts/common.jl")
include("layouts/layout_engines.jl")

include("graph/common.jl")

include("core/export.jl")  # must be last to properly export all functions


end # module
