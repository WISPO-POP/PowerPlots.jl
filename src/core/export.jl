# PowerModelsAnalytics exports everything except internal symbols, which are defined as
# those whose name starts with an underscore. If you don't want all of these
# symbols in your environment, then use `import PowerModelsAnalytics` instead of
# `using PowerModelsAnalytics`.

# Do not add PowerModelsAnalytics-defined symbols to this exclude list. Instead, rename
# them with an underscore.

# add the module name, :eval, :include to the excluded symbols list (empty list if it does not exist), and changes it to const
union!((isdefined(@__MODULE__, :_EXCLUDE_SYMBOLS) ? _EXCLUDE_SYMBOLS : const _EXCLUDE_SYMBOLS = []),
    [Symbol(@__MODULE__), :eval, :include])
for sym in names(@__MODULE__, all=true)
    sym_string = string(sym)
    if sym in _EXCLUDE_SYMBOLS || startswith(sym_string, "_")
        continue
    end
    if !(Base.isidentifier(sym) || (startswith(sym_string, "@") &&
         Base.isidentifier(sym_string[2:end])))
       continue
    end
    @eval export $sym
end

# the follow items are also exported for user-friendlyness when calling
# `using PowerPlots`

# so that users do not need to import Vegalite to use a save a figure
import VegaLite: save
export save
