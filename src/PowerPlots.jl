module PowerPlots

import InfrastructureModels
import PowerModels
import PowerModelsDistribution
import Statistics: mean, std
import LinearAlgebra
import LinearAlgebra: norm
import Random:MersenneTwister

import VegaLite
import Colors
import ColorSchemes
import DataFrames
import OrderedCollections
import Memento

import Graphs
import NetworkLayout
import GeometryBasics
import NLopt
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
include("layouts/kamada_kawaii_layout.jl")
include("layouts/SFDP_fixed_layout.jl")

include("graph/common.jl")

include("experimental/experimental.jl")

include("core/export.jl")  # must be last to properly export all functions


end # module
