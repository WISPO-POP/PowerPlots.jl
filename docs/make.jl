using Documenter, PowerPlots

makedocs(
    modules = [PowerPlots],
    format = Documenter.HTML(mathengine = Documenter.MathJax()),
    sitename = "PowerPlots",
    authors = "Noah Rhodes",
    pages = [
        "Home" => "index.md",
        "Examples" => "examples.md",
        "Plot Attributes" => "plot_attributes.md",
    ]
)

deploydocs(
    repo = "github.com/WISPO-POP/PowerPlots.jl.git",
)
