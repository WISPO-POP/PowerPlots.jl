# Example for aliases

# Dictionary of aliases of properties
# Aliases are replaced by their key in plotattributes
# for example, nodecolor/markercolor/marker_color, edgecolor/edge_color/ec can be used to
# set nodecolor and edgecolor respectively
const graph_aliases = Dict(:nodecolor => [:marker_color, :markercolor],
                           :edgecolor => [:edge_color, :ec]
)

#===
Below are functions copied from `utils.jl` in GraphRecipes
See: https://github.com/JuliaPlots/GraphRecipes.jl/blob/master/src/utils.jl
===#

# gets the alias replacement name to replace the attribute sym in plotattributes
function replacement_kwarg(sym, name, plotattributes, graph_aliases)
  replacement = name
  for alias in graph_aliases[sym]
      if haskey(plotattributes, alias)
          replacement = plotattributes[alias]
      end
  end
  replacement
end

# adds the original keyword of all aliases into plotattributes
# and sets it to the alias value
macro process_aliases(plotattributes, graph_aliases)
  ex = Expr(:block)
  attributes = getfield(__module__, graph_aliases) |> keys
  ex.args = [Expr(:(=), :($(esc(plotattributes))[$(Meta.quot(sym))]),
                  :($(esc(replacement_kwarg))($(QuoteNode(sym)), $(esc(sym)),
                    $(esc(plotattributes)), $(esc(graph_aliases))))) for sym in attributes]
  ex
end

# called after aliases are processed via @process_aliases
# removes any alias keys from plotattributes
function remove_aliases!(sym, plotattributes, graph_aliases)
  for alias in graph_aliases[sym]
      if haskey(plotattributes, alias)
          delete!(plotattributes, alias)
      end
  end
end

#===
Test code below
===#

using PowerPlots
using PowerModels

case = PowerModels.parse_file("$(joinpath(dirname(pathof(PowerModels)), ".."))/test/data/matpower/case5.m")

# Adds the given keyword args as entries into plotattributes
function convert_to_attributes!(plotattributes, kwargs)
  for (var, val) in kwargs
    plotattributes[var] = val
  end
end

function test(case, spring_constant=1e-3; nodecolor=:blue, edgecolor=:black, kwargs...)
  plotattributes = Dict{Symbol, Any}(); # create empty plotattributes dictionary
  println("Initial plot attributes:") # TODO remove
  println(plotattributes) # TODO remove

  println("Kwargs:") # TODO remove
  println(kwargs) # TODO remove

  convert_to_attributes!(plotattributes, kwargs) # add kwargs into plotattributes

  println("After conversion of kwargs:") # TODO remove
  println(plotattributes) # TODO remove

  @process_aliases plotattributes graph_aliases # process the aliases and add original attributes

  println("After processing plot attributes:") # TODO remove
  println(plotattributes) # TODO remove

  # remove alias names from plotattributes
  for arg in keys(graph_aliases)
    remove_aliases!(arg, plotattributes, graph_aliases)
  end

  println("New plot attributes (after removal of aliases):") # TODO remove
  println(plotattributes) # TODO remove

  # data = layout_graph_vega(case, spring_constant)
  # remove_information!(data)
  # df = form_df(data)
end