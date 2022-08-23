
module Experimental
    using VegaLite, ColorSchemes, Setfield

    ## set branch color scheme after graph is created.  This does not currently function because the layer numbers are may
    # not correlate if a device does not exist (e.g. dclines)
    function set_branch_color_range(plot::VegaLite.VLSpec, cs::ColorSchemes.ColorScheme)
        return set_branch_color_range(plot, colorscheme2array(cs))
    end

    function set_branch_color_range(plot::VegaLite.VLSpec, cr::AbstractVector{String})
        return plot.layer[1]["encoding"]["color"]["scale"]["range"] = cr
    end


    function set_connector_color_range(plot::VegaLite.VLSpec, cs::ColorSchemes.ColorScheme)
        return set_connector_color_range(plot, colorscheme2array(cs))
    end

    function set_connector_color_range(plot::VegaLite.VLSpec, cr::AbstractVector{String})
        return plot.layer[2]["encoding"]["color"]["scale"]["range"] = cr
    end

    # function set_dcline_color_range(plot::VegaLite.VLSpec, cs::ColorSchemes.ColorScheme)
    #   return set_dcline_color_range(plot, colorscheme2array(cs))
    # end

    # function set_dcline_color_range(plot::VegaLite.VLSpec, cr::AbstractVector{String})
    #   return plot.layer[3]["encoding"]["color"]["scale"]["range"] = cr
    # end


    function set_bus_color_range(plot::VegaLite.VLSpec, cs::ColorSchemes.ColorScheme)
        return set_bus_color_range(plot, colorscheme2array(cs))
    end

    function set_bus_color_range(plot::VegaLite.VLSpec, cr::AbstractVector{String})
        return plot.layer[3]["encoding"]["color"]["scale"]["range"] = cr
    end



    function set_gen_color_range(plot::VegaLite.VLSpec, cs::ColorSchemes.ColorScheme)
        return set_gen_color_range(plot, colorscheme2array(cs))
    end

    function set_gen_color_range(plot::VegaLite.VLSpec, cr::AbstractVector{String})
        return plot.layer[4]["encoding"]["color"]["scale"]["range"] = cr
    end

    "Change the cartesian view to a geographic projection. Default is albersUsa"
    function cartesian2geo!(plot::VegaLite.VLSpec; projection_type=:albersUsa)

        # set the plot geo map projection
        @set! plot.projection=Dict{String,Any}("type"=>projection_type)

        return _set_geo_coords!(plot)
    end

    function _set_geo_coords!(plot::VegaLite.VLSpec)
        # create lat/lon channels from x/y channels
        for i in 1:length(plot.layer)
            if haskey(plot.layer[i],"layer")
                _set_geo_coords!(plot.layer[1])
            else
                if haskey(plot.layer[i], "encoding")
                    plot.layer[i]["encoding"]["longitude"] = plot.layer[i]["encoding"]["x"]
                    delete!(plot.layer[i]["encoding"],"x")
                    plot.layer[i]["encoding"]["latitude"] = plot.layer[i]["encoding"]["y"]
                    delete!(plot.layer[i]["encoding"],"y")
                    if haskey(plot.layer[i]["encoding"],"x2")
                        plot.layer[i]["encoding"]["longitude2"] = plot.layer[i]["encoding"]["x2"]
                        delete!(plot.layer[i]["encoding"],"x2")
                    end
                    if haskey(plot.layer[i]["encoding"],"y2")
                        plot.layer[i]["encoding"]["latitude2"] = plot.layer[i]["encoding"]["y2"]
                        delete!(plot.layer[i]["encoding"],"y2")
                    end
                end
            end
        end
        return plot
    end

    function _set_geo_coords!(plot_layer::AbstractDict{<:Any,<:Any})
        # create lat/lon channels from x/y channels
        for i in keys(plot_layer["layer"])
            if haskey(plot_layer["layer"][i],"layer")
                _set_geo_coords!(plot_layer["layer"][i])
            else
                if haskey(plot_layer["layer"][i], "encoding")
                    plot_layer["layer"][i]["encoding"]["longitude"] = plot_layer["layer"][i]["encoding"]["x"]
                    delete!(plot_layer["layer"][i]["encoding"],"x")
                    plot_layer["layer"][i]["encoding"]["latitude"] = plot_layer["layer"][i]["encoding"]["y"]
                    delete!(plot_layer["layer"][i]["encoding"],"y")
                    if haskey(plot_layer["layer"][i]["encoding"],"x2")
                        plot_layer["layer"][i]["encoding"]["longitude2"] = plot_layer["layer"][i]["encoding"]["x2"]
                        delete!(plot_layer["layer"][i]["encoding"],"x2")
                    end
                    if haskey(plot_layer["layer"][i]["encoding"],"y2")
                        plot_layer["layer"][i]["encoding"]["latitude2"] = plot_layer["layer"][i]["encoding"]["y2"]
                        delete!(plot_layer["layer"][i]["encoding"],"y2")
                    end
                end
            end
        end
        return plot_layer
    end

    "Make zoomable my modifying layer 1"
    function add_zoom!(plot::VegaLite.VLSpec)
        return plot.layer[1]["selection"]=Dict{String,Any}(
            "grid"=>Dict{String,Any}(
                "type"=>:interval,
                "resolve"=>:global,
                "bind"=>:scales,
                "translate"=>"[mousedown[!event.shiftKey], window:mouseup] > window:mousemove!",
                "zoom"=>"wheel![!event.shiftKey]"
            )
        )
    end

end