# PowerModelsAnalytics exports everything except internal symbols, which are defined as
# those whose name starts with an underscore. If you don't want all of these
# symbols in your environment, then use `import PowerModelsAnalytics` instead of
# `using PowerModelsAnalytics`.

# Do not add PowerModelsAnalytics-defined symbols to this exclude list. Instead, rename
# them with an underscore.

# Which symbols to exclude from the export
const _EXCLUDE_SYMBOLS = [Symbol(@__MODULE__), :eval, :include]
function _hide_function(f::Function) # adds the given function to the excluded symbols
    push!(_EXCLUDE_SYMBOLS, Symbol(f))
end

_hide_function(silence) # do not export, potential conflict of PowerModels.silence()
_hide_function(logger_config!)  # do not export, potential conflict of PowerModels.logger_config!()

# do not export macros used for aliases
push!(_EXCLUDE_SYMBOLS, Symbol("@process_aliases"))
push!(_EXCLUDE_SYMBOLS, Symbol("@prepare_plot_attributes"))


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
