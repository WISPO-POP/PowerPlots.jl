using Documenter, PowerPlots, VegaLite, UUIDs, PowerModels, PowerModelsDistribution

function Base.show(io::IO, m::MIME"text/html", v::VegaLite.VLSpec)
    divid = string("vl", replace(string(uuid4()), "-"=>""))
    print(io, "<div id='$divid' style=\"width:100%;height:100%;\"></div>")
    print(io, "<script type='text/javascript'>requirejs.config({paths:{'vg-embed': 'https://cdn.jsdelivr.net/npm/vega-embed@6?noext','vega-lib': 'https://cdn.jsdelivr.net/npm/vega-lib?noext','vega-lite': 'https://cdn.jsdelivr.net/npm/vega-lite@4?noext','vega': 'https://cdn.jsdelivr.net/npm/vega@5?noext'}}); require(['vg-embed'],function(vegaEmbed){vegaEmbed('#$divid',")
    VegaLite.our_json_print(io, v)
    print(io, ",{mode:'vega-lite'}).catch(console.warn);})</script>")
end

makedocs(
    modules = [PowerPlots],
    format = Documenter.HTML(mathengine = Documenter.MathJax()),
    sitename = "PowerPlots",
    authors = "Noah Rhodes",
    pages = [
        "Home" => "index.md",
        "Examples" => Any[
            "examples/basic examples.md",
            "examples/advanced examples.md",
        ],
        "Parameters" => "parameters.md",
        "Data Transformations" => Any[
            "data_transformations/powermodelsdataframes.md",
            "data_transformations/powermodelsgraphs.md",
            "data_transformations/layouts.md",
        ],
        "Experimental Features" => "experimental.md",
    ]
)


deploydocs(
    repo = "github.com/WISPO-POP/PowerPlots.jl.git",
)
