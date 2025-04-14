The aliases `node_color` and `edge_color` can overwrite all nodes and edges respectively.

```@example power_data
powerplot(data; node_color="red", edge_color="purple", width=300, height=300)
```

Aliases to override all node and edge sizes.
```@example power_data
powerplot(data, node_size=1000, edge_size=10, width=300, height=300)
```