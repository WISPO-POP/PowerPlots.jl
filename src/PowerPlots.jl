module PowerPlots

import InfrastructureModels
import PowerModels
import Statistics: mean, std
import LinearAlgebra

import VegaLite
import Colors
import ColorSchemes
import DataFrames
import Memento

import LightGraphs
import NetworkLayout
import NetworkLayout:Spring
import GeometryBasics
import NLopt
import OMEinsum
import RecursiveArrayTools

_PM = PowerModels
_IM = InfrastructureModels


include("core/configuration.jl")
include("core/types.jl")
include("core/data.jl")
include("core/utils.jl")
include("core/options.jl")
include("core/attribute_validation.jl")

include("plots/plot.jl")
include("plots/plot_processing.jl")

include("layouts/common.jl")
include("layouts/layout_engines.jl")

include("graph/common.jl")

include("experimental/experimental.jl")

include("core/export.jl")  # must be last to properly export all functions


end # module
