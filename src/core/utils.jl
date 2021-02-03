#===
Below are functions copied from `utils.jl` in GraphRecipes
See: https://github.com/JuliaPlots/GraphRecipes.jl/blob/master/src/utils.jl
===#

# gets the alias replacement name to replace the attribute sym in plot_attributes
function replacement_kwarg(sym, name, plot_attributes, attribute_aliases)
  replacement = name
  for alias in attribute_aliases[sym]
      if haskey(plot_attributes, alias)
          replacement = plot_attributes[alias]
      end
  end
  replacement
end

# adds the original keyword of all aliases into plot_attributes
# and sets it to the alias value
macro process_aliases(plot_attributes, attribute_aliases)
  ex = Expr(:block)
  attributes = getfield(__module__, attribute_aliases) |> keys
  ex.args = [Expr(:(=), :($(esc(plot_attributes))[$(Meta.quot(sym))]),
                  :($(esc(replacement_kwarg))($(QuoteNode(sym)), $(esc(sym)),
                    $(esc(plot_attributes)), $(esc(attribute_aliases))))) for sym in attributes]
  ex
end

# called after aliases are processed via @process_aliases
# removes any alias keys from plot_attributes
function remove_aliases!(sym, plot_attributes, attribute_aliases)
  for alias in attribute_aliases[sym]
      if haskey(plot_attributes, alias)
          delete!(plot_attributes, alias)
      end
  end
end

#===
New PowerPlots code below
===#

# Adds the given keyword args as entries into plot_attributes
function convert_to_attributes!(plot_attributes, kwargs)
  for (var, val) in kwargs
    plot_attributes[var] = val
  end
end

function attributes_as_variables(plot_attributes, kwargs)
  ex = Expr(:block)
  ex.args = [(haskey(kwargs, var) ? Expr(:(=), var, Meta.quot(kwargs[var]))
     : Expr(:(=), var, Meta.quot(val))) for (var, val) in plot_attributes]
  return ex
end

macro prepare_plot_attributes(kwargs)
  ex = quote
    _kwargs = $(esc(kwargs));
    plot_attributes = copy_default_attributes(); # get a copy of the default attributes
    attributes_as_variables(plot_attributes, _kwargs) |> eval; # create variables from the default attributes
    convert_to_attributes!(plot_attributes, _kwargs); # add kwargs into plot_attributes
    @process_aliases plot_attributes attribute_aliases; # process the aliases and add original attributes
    # remove alias names from plot_attributes
    for arg in keys(attribute_aliases)
      remove_aliases!(arg, plot_attributes, attribute_aliases)
    end;
  end;
  push!(ex.args, Expr(:(=), esc(:plot_attributes), :plot_attributes)); # create external plot_attributes dict
  ex
end

# #=== Example Usage ===#
# function plot_vega(case; spring_constant=1e-3, kwargs...)
#   # Copy the line below at the start of the plot method
#   @prepare_plot_attributes(kwargs); # creates the plot_attributes dictionary

#   println(plot_attributes) # TODO remove this in real code (it's just for debug)

#   # Rest of plotting code...
# end