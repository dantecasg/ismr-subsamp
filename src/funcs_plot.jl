# --------------------------------------------------------------------------- #
# Set of functions that are used for plotting
# Author: Dante T. Castro Garro
# Date: 2021-07-24
# --------------------------------------------------------------------------- #

## shp4plot
# Prepares shape file to be plotted.
# ........................................................................... #
# Required libraries;
# - DataFrames
# - Shapefile
# ........................................................................... #
# Parameters:
# - shp -> path of the shape file

function shp4plot(shp)
    shp_tb = Shapefile.Table(shp)
    shp_df = DataFrame(shp_tb)
    shp_pl = []
    shp_ipl = []

    for poly in shp_df.geometry
        verty = [point.y for point in poly.points]
        vertx = Float64[]
        xp = 0
        
        for point in poly.points
            com = point.x - xp
            if com < -180
                push!(vertx, point.x + 360.0)
            elseif com > 180
                push!(vertx, point.x - 360.0)
            else
                push!(vertx, point.x)
            end
            xp = point.x
        end

        push!(shp_pl, Shape(vertx, verty))
        push!(shp_ipl, Shape(vertx .+ 360.0, verty))
    end

    shp_df[:,"shapes"] .= shp_pl
    shp_df[:,"ishapes"] .= shp_ipl

    return shp_df
end;

## rectanlge 
# Draws a rectangle in a plot
# ........................................................................... #
# Required libraries;
# - Plots
# ........................................................................... #
# Parameters:
# - w -> width 
# - h -> height 
# - x -> x-axis initial position
# - y -> y-axis initial position

rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h]);

## plotSpt
# Spatial plot of a 2D variable
# ........................................................................... #
# Required libraries;
# - Plots
# ........................................................................... #
# Parameters:

# function plotSpt(x, y, z; cb, rev = false, clims)
#     g = contourf(
#         x, y, z,
#         linewidth = 0,
#         c = cgrad(cb, rev = rev),
#         clims = clims)
#     plot!(shp, fillcolor = "grey", )
# end
