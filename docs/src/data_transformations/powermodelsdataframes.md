# PowerModels Dictionary to DataFrame Conversion
VegaLite uses tabular data when creating a plot, and this requires converting the PowerModels dictionary data into a DataFrame.  A struct is used for all of the supported components of the base power plot, where each component type is a DataFrame.  This struct is created when  `powerplot()` is called.  Multi-network dictionaries are supported.

```julia
mutable struct PowerModelsDataFrame
    metadata::DataFrames.DataFrame
    components::Dict{Symbol, DataFrames.DataFrame}
```


Top level data (non-components) is stored in a the meta data field.  The components are stored as DataFrames in a dictionary, where the keys are the component types.  By default any components that are in the supported components list are added.

Using tabular data can be convenient for a statistical analysis of the components. To create this data struct, call the constructor on a powermodels dictionary.


```@example pmd
using PowerModels
using PowerPlots
case = parse_file("case14.m")
case_PMDF = PowerModelsDataFrame(case)
```

You can specify a subset of the default components, or new components not in the default list by passing in an argument.

```@example pmd
case_PMDF = PowerModelsDataFrame(case, components=["bus", "branch"])
```


To create an individual component dictionary, use the `comp_dict_to_dataframe` function.
```@example pmd
case_PMDF = comp_dict_to_dataframe(case["bus"])
```
