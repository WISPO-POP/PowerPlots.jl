

# Which symbols to exclude from the export
const _EXCLUDE_SYMBOLS = []
function _hide_function(f::Function) # adds the given function to the excluded symbols
    push!(_EXCLUDE_SYMBOLS, Symbol(f))
end


# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

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
