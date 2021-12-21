# --------------------------------------------------------------------------- #
# Functions to calculate indeces.
# Requires:
# - funcs_nc.jl
# - funcs_stat.jl
# - NCDatasets
# - Statistics
# - DataFrames
# - Dates
#
# Author: Dante T. Castro Garro
# Date: 2021-10-07
# --------------------------------------------------------------------------- #

## getIndex
# Calculates indeces from nc datasets
# ........................................................................... #
# Parameters:
# - nc -> nc dataset
# - var -> name of the variable
# - idx -> name of the index
# - n_mem -> which member (if any) will be used
# - smooth -> window size for smoothing the index (if applies)
# ........................................................................... #

function getIndex(nc, var, idx; n_mem = 0, smooth = 0, lon_name = "lon", lat_name = "lat")
    
    # Procedure by index
    if idx == "oni"
        tab = extractVar(nc, var, (-170,-120,-5,5), n_mem = n_mem, lon_ew = true, anom = true)
        tab[:,"idx"] .= NaN
        tab[2:(end-1),:idx] = runMean(tab.dat, 3)
        
    elseif idx == "wio"
        tab = extractVar(nc, var, (50,70,-10,10), n_mem = n_mem, anom = true)
        
    elseif idx == "eio"
        tab = extractVar(nc, var, (90,110,-10,0), n_mem = n_mem, anom = true)
        
    elseif idx == "atl"
        tab = extractVar(nc, var, (-60,-30,-5,10), n_mem = n_mem, anom = true, lon_ew = true)
        
    elseif idx == "dmi"
        west = getIndex(nc, var, "wio", n_mem = n_mem)
        east = getIndex(nc, var, "eio", n_mem = n_mem)
        rename!(west, :idx => :west)
        rename!(east, :idx => :east)
        tab = leftjoin(west, east, on = [:year, :month])
        transform!(tab, [:west, :east] => (-) => :dat)
        
    elseif idx == "wyi"
        nc850 = nc[1]
        nc200 = nc[2]
        tab_850 = extractVar(nc850, var, (40,100,0,20), n_mem = n_mem, lon_name = lon_name, lat_name = lat_name)
        tab_200 = extractVar(nc200, var, (40,100,0,20), n_mem = n_mem, lon_name = lon_name, lat_name = lat_name)
        rename!(tab_850, :dat => :u850)
        rename!(tab_200, :dat => :u200)
        tab = leftjoin(tab_850, tab_200, on = [:time, :year, :month])
        transform!(tab, [:u850, :u200] => (-) => :dat)

        # tim = nc850["time"] |> collect
        
        # dat_850 = ncVarGet(
        #     nc850,
        #     var = var,
        #     coord = (40,100,0,20),
        #     lon_ew = false,
        #     lon_name = lon_name,
        #     lat_name = lat_name)
        # dat_200 = ncVarGet(
        #     nc200,
        #     var = var,
        #     coord = (40,100,0,20),
        #     lon_ew = false,
        #     lon_name = lon_name,
        #     lat_name = lat_name)
     
        # dat_850 = n_mem > 0 ? dat_850[:,:,n_mem,:] : dat_850
        # dat_200 = n_mem > 0 ? dat_200[:,:,n_mem,:] : dat_200
        # dat = dat_850 - dat_200
        
        # nt = size(dat, 3)
        # aave = [mean(skipmissing(dat[:,:,i])) for i in 1:nt]
        
        # tab = DataFrame(time = tim, dat = aave)
        # tab[:,"year"]  = [year(i)  for i in tab.time]
        # tab[:,"month"] = [month(i) for i in tab.time]
        
    end
    
    # Smoothing index (not applied for "oni" index)
    if (smooth > 0) && (idx != "oni")
        m = Int( (smooth - 1) / 2 )
        tab[:,"idx"] .= NaN
        tab[(1+m):(end-m),:idx] = runMean(tab.dat, smooth)
        
    elseif (smooth == 0) && (idx != "oni")
        transform!(tab, :dat => :idx)
        
    end
    
    res = select(tab, :year, :month, :idx)
    return res
end

## extractVar
# Extract variable and calculate anomaly if needed
# ........................................................................... #
# Parameters:
# - nc -> nc dataset
# - var -> name of the variable
# - coord -> coordinates to crop data
# - n_mem -> which member (if any) will be used
# - lon_ew -> shall convert (0 360) to (-180 180)?
# - anom -> calculate anomaly
# - lon_name -> name of the longitude dimension
# - lat_name -> name of the latitude dimension
# ........................................................................... #

function extractVar(
        nc, var, coord;
        n_mem = 0, 
        lon_ew = false, 
        anom = false, 
        lon_name = "lon", 
        lat_name = "lat")
    
    # Getting variables
    tim = nc["time"] |> collect
    dat = ncVarGet(
        nc,
        var = var,
        coord = coord,
        lon_ew = lon_ew,
        lon_name = lon_name,
        lat_name = lat_name)
    dat = n_mem > 0 ? dat[:,:,n_mem,:] : dat

    # Area average
    # NOTE: missing values has to be avoided
    nt = size(dat, 3)
    aave = [mean(skipmissing(dat[:,:,i])) for i in 1:nt]

    # Creating table
    tab = DataFrame(time = tim, aave = aave)
    tab[:,"year"]  = [year(i)  for i in tab.time]
    tab[:,"month"] = [month(i) for i in tab.time]

    if anom
        # Climatology
        cli = tab[1981 .<= tab.year .<= 2010,:]
        cli = groupby(cli, :month)
        cli = combine(cli, :aave => mean => :cli)
        
        # Anomaly
        res = leftjoin(tab, cli, on = :month)
        transform!(res, [:aave, :cli] => (-) => :dat)
        select!(res, :time, :year, :month, :dat)
    else
        res = rename(tab, :aave => :dat)
    end

    return res
end
