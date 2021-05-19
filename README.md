# PowerPlots.jl

![CI](https://github.com/WISPO-POP/PowerPlots.jl/workflows/CI/badge.svg)
[![Codecov](https://codecov.io/gh/WISPO-POP/PowerPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/WISPO-POP/PowerPlots.jl)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://wispo-pop.github.io/PowerPlots.jl/dev/)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://wispo-pop.github.io/PowerPlots.jl/stable/)

Tools for the analysis and visualization of PowerModels data and results.

***BETA / IN ACTIVE DEVELOPMENT**: Features will change quickly and without warning*


## Installation
`PowerPlots.jl` is a registered julia package and can be added with the following command.

```julia
Pkg> add PowerPlots
```

To add the lastest development version of `PowerPlots.jl` use the command:
```julia
Pkg> add https://github.com/WISPO-POP/PowerPlots.jl.git
```

## Documentation
The Documentation is available [here](https://wispo-pop.github.io/PowerPlots.jl/stable/).


## Acknowledgements
This code has been primarily developed by Noah Rhodes at the University of Wisconsin-Madison with the help of the following contributors,
 - Bryan Luu, University of Wisconsin-Madison, plot attribute processing
 - Joe Gorka, University of Wisconsin-Madison, modifying network layout algorithms

## License


## PowerPlots v0.1
The package formerly used the Plots backend, but a major rewrite for v0.2 replaced the backend with VegaLite. To use the previous version with the Plots backend, use:

```julia
Pkg> add PowerPlots@0.1
```
The former documentation is available [here](https://github.com/WISPO-POP/PowerPlots.jl/blob/master/example_plots/)




