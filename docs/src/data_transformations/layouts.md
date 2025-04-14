# Layouts
The default layout algorithm for `powerplot()` is the [Kamada Kawai](https://doi.org/10.1016/0020-0190(89)90102-6) network layout algorithm.  This algorithm generally creates very nice looking graphs with few line crossings, but requires minimining a non-linear function and does not scale well to very large networks.

| Network     | Layout Time |
| ----------- | ----------- |
| `IEEE 14 Bus`     | `0.003902 seconds` |
| `IEEE 118 Bus`    | `0.101225 seconds` |
| `pegase 1354`     | `22.459203 seconds` |
| `RTE  1888 Bus`   | `46.854940 seconds` |

If using a large network, it may be beneficial to create a layout and add this to the data dictionary.  This will assign coordinates `xcoord_1,ycoord_1` for each component in the powermodels data dictionary.

```julia
case = layout_network(case)
println(case["bus"]["1"]["xcoord_1"])
0.0215938
```

Then, when plotting you can use the fixed arguments to use the component coordinates instead of creating a new layout.
```julia
powerplot(case, fixed=true)
```

Values for the coordinates can also be created manually, for example for geographic coordinates. Simply add a dictionary key for `xcoord_1` and `ycoord_1` to the powermodels data dictionary for the nodal components (such as buses and generators).  Any nodal components that do not have a value will have a layout calculated, and values for edge components (such as branches) are identified from their endpoints.


## Selecting layouts
Several layout algorithms are supported. The default is Kamada Kawai, but other algorithms have better performance on larger networks like the PEGASE 1354 bus network.

| Layout Algorithm  | Layout Time |
| ----------- | ----------- |
| `kamada_kawai`    | `22.459203 seconds` |
| `Shell`          | `0.054517 seconds` |
| `SFDP`          | `1.099188 seconds` |
| `Buchheim`          | `N/A on meshed networks` |
| `Spring`          | `3.143862 seconds` |
| `SquareGrid`          | `0.051883 seconds` |
| `Spectral`          | `0.911582 seconds` |


A layout algorithm can be selected using a keyword argument.

```julia
layout_network(case; layout_algorithm=Spring)
```

The keyword arguments for each algorithm are vary.  The `kamada_kawai` layout has no supported arguments. The following are layout algorithms from the package [NetworkLayouts.jl](https://juliagraphs.org/NetworkLayout.jl/stable/).  The arguments for these functions can be found in the documentation for `NetworkLayouts.jl`.

- [Shell](https://juliagraphs.org/NetworkLayout.jl/stable/#Shell/Circular-Layout)
- [SFDP](https://juliagraphs.org/NetworkLayout.jl/stable/#Scalable-Force-Directed-Placement)
- [Buchheim](https://juliagraphs.org/NetworkLayout.jl/stable/#Buchheim-Tree-Drawing)
- [Spring](https://juliagraphs.org/NetworkLayout.jl/stable/#Spring/Repulsion-Model)
- [SquareGrid](https://juliagraphs.org/NetworkLayout.jl/stable/#SquareGrid-Layout)
- [Spectral](https://juliagraphs.org/NetworkLayout.jl/stable/#Spectral-Layout)


The layout algorithm arguments can be passed to the `layout_network` function.
```julia
case = layout_network(case; layout_algorithm=SFDP, C=0.1, K=0.9)
```

The layout algorithm arguments can be also passed in directly through `powerplot`.
```julia
powerplot(case; layout_algorithm=Spring, iterations=50)
```

When using `fixed=true`, a variation of the `SFDP` algorithm is used that does not update corrdinates with prior coordinates set.  The same arguments arguments as the `SFDP` algorithm can be used to modify the layout.


The default weights for edge-type components (branches, dc lines, etc.) are `1.0`.  The default weight for connectors (links from  e.g. generators to buses) is 0.5.  They can be modified by passing the argument `edge_weight` or `connector_weight` to the layout function.  If a component has a `weight` entry in its data dictionary, such as `data["branch"]["1"]["weight"]`, this weight will be used instead.