# Layouts
The default layout algorithm for `powerplot()` is the [Kamada Kawai](https://doi.org/10.1016/0020-0190(89)90102-6) network layout algorithm.  This algorithm generally creates very nice looking graphs, but requires minimining a non-linear function and does not scale well to very large networks.

| Network     | Layout Time |
| ----------- | ----------- |
| `IEEE 14 Bus`     | `0.025939 seconds` |
| `IEEE 118 Bus`    | `0.406463 seconds` |
| `pegase 1354`     | `41.793255 seconds` |
| `RTE  1888 Bus`   | `87.669819 seconds` |

If using a large network, it may be beneficial to create a layout and add this to the data dictionary.  This will add the neccessary coordinates to the components for plotting.
```julia
network_layout!(case)
```

Then, when plotting use the fixed positions arguments to use the component coordinates instead of creating a new layout.
```julia
powerplot(case, apply_layout=false)
```


## Selecting layouts
Several layout algorithms are supported. The default is Kamada Kawai, but others have better performance on larger networks like the PEGASE 1354 bus network.

| Layout Algorithm  | Layout Time |
| ----------- | ----------- |
| `:kamada_kawai`    | `41.793255 seconds` |
| `:spring`          | `?? seconds` |

A layout algorithm can be selected using a keyword argument.

```julia
network_layout!(case; algorithm=:spring)
```

The keyword arugments for each algorithm are slightly different.

### `:kamada_kawai`

*There are no currently supported arguments for this algorithm*.



### `:spring`
| Keyword Arguemnts  | Description |
| ----------- | ----------- |
| `iterations`      | Number of iterations to run the spring force |
| `C`               | Constant to fiddle with density of resulting layout |
| `initialtemp`     | Initial "temperature", controls movement per iteration |
| `fixed_nodes`     | Boolean if true, do not move nodes that already have a position |

