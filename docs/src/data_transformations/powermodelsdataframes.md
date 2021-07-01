# PowerModels Dictionary to DataFrame Conversion
VegaLite uses tabular data when creating a plot, and this requires converting the PowerModels dictionary data into a DataFrame.  A struct is used for all of the supported components of the base power plot, where each component type is a DataFrame.  This struct is created when  `powerplot()` is called.  Multi-network dictionaries are supported.

```julia
mutable struct PowerModelsDataFrame
    metadata::DataFrames.DataFrame
    bus::DataFrames.DataFrame
    gen::DataFrames.DataFrame
    branch::DataFrames.DataFrame
    dcline::DataFrames.DataFrame
    load::DataFrames.DataFrame
    connector::DataFrames.DataFrame
```


Using tabular data can be convenient for a statistical analysis of the components. To create this data struct, call the constructor on a powermodels dictionary.
```@example
using PowerModels
using PowerPlots
case = parse_file("case14.m")

case_PMDF = PowerModelsDataFrame(case)
```


To create an individual component dictionary, use the `comp_dict_to_dataframe` function.
```@example
using PowerModels
using PowerPlots
case = parse_file("case14.m")

case_PMDF = comp_dict_to_dataframe(case["bus"])
```
