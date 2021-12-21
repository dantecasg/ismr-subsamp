# --------------------------------------------------------------------------- #
# Set of functions for NetCDF data processing
# Author: Dante T. Castro Garro
# Date: 2021-09-17
# --------------------------------------------------------------------------- #

## ncVarGet
# Exrtact a variable for specific coordinates if needed.
# ........................................................................... #
# Required libraries;
# - NCDaatasets
# ........................................................................... #
# Parameters:
# - nc -> NetCDF dataset
# - var -> Variable that will be extracted. If none is passed, lonlat will be used
# - coord -> Coordinates for the cropping
# - invert_lon -> Convert longitudes from 0 360 to -180 180
# - ndim -> Number of dimensions of the file

function ncVarGet(
        nc;
        var = "", 
        coord = (-180, 180, -90, 90),
        lon_ew = false,
        lon_name = "lon",
        lat_name = "lat")

    lon = nc[lon_name] |> collect
    lat = nc[lat_name] |> collect

    # Transform longitudes
    if lon_ew
        lon[lon.> 180] = lon[lon .> 180] .- 360
    end

    lon_sel = coord[1] .<= lon .<= coord[2]
    lat_sel = coord[3] .<= lat .<= coord[4]
	
    # Returning coordinates or variables
    if var == "" || var == "lonlat"
        lon = lon[lon_sel]
        lat = lat[lat_sel]
        return lon, lat
    else
        ndim = nc[var] |> size |> length
        ndim == 2 && return nc[var][lon_sel,lat_sel]
        ndim == 3 && return nc[var][lon_sel,lat_sel,:]
        ndim == 4 && return nc[var][lon_sel,lat_sel,:,:]
        ndim == 5 && return nc[var][lon_sel,lat_sel,:,:,:]
    end
end
