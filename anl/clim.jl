# --------------------------------------------------------------------------- #
# Precipitation climatology
#
# Author: Dante T. Castro Garro
# Date: 2022-01-16
# --------------------------------------------------------------------------- #

# =========================================================================== #
# LIBRARIES
# =========================================================================== #

using NCDatasets
using Plots
using Shapefile
using DataFrames
using Statistics
# using StatsPlots

# =========================================================================== #
# FUNCTIONS
# =========================================================================== #

include("../src/funcs_plot.jl")

# --------------------------------------------------------------------------- #

# Plot spatial correlation (which should be already calculated)
function plotStatSpatial(; x, y, z, shp, leg, range, title, ylabel)
    p = contourf(x, y, z, linewidth = 0, c = :YlGnBu_9, legendtitle = "mm/day")
    plot!(colorbar = leg, clims = range, colorbartitle = "mm/day")
    plot!(shp, fillalpha = 0, legend = false, linecolor = "black")
    xlims!((50.0, 110.0))
    ylims!((0.0, 40.0))
    title!(title)
    ylabel!(ylabel)
    return p
end

# Plot 2 spatial variables for 2 data sources
function plotCompSpatial(; data1, data2, coord1, coord2, xtit, ytit)
    g_11 = plotStatSpatial(
        x = coord1[1],
        y = coord1[2],
        z = data1[1]',
        shp = coast_df.shapes,
        leg = false,
        range = (0,25),
        title = xtit[1],
        ylabel = ytit[1]
    )

    g_21 = plotStatSpatial(
        x = coord1[1],
        y = coord1[2],
        z = data1[2]',
        shp = coast_df.shapes,
        leg = false,
        range = (0,10),
        title = "",
        ylabel = ytit[2]
    )

    g_12 = plotStatSpatial(
        x = coord2[1],
        y = coord2[2],
        z = data2[1]',
        shp = coast_df.shapes,
        leg = true,
        range = (0,25),
        title = xtit[2],
        ylabel = ""
    )

    g_22 = plotStatSpatial(
        x = coord2[1],
        y = coord2[2],
        z = data2[2]',
        shp = coast_df.shapes,
        leg = true,
        range = (0,10),
        title = "",
        ylabel = ""
    )

    # Combining plots
    lay = @layout[a{0.46w} b; c{0.46w} d]
    g = plot(g_11, g_12, g_21, g_22, layout = lay)
    plot!(dpi = 300, size = (1000,650))
    plot!(margin = 5Plots.mm)

    return g
end

# Bar plot for monthly climatology
function plotBarClim(data; label, color)
    mon = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    if data isa Tuple
        g = plot(
            mon,
            data[1],
            seriestype = :bar,
            label = label[1],
            alpha = 0.5,
            color = color[1]
        )

        for i in 2:length(data)
            plot!(
                mon,
                data[i],
                seriestype = :bar,
                label = label[i],
                alpha = 0.5,
                color = color[i]
            )
        end
    else
        g = plot(
            mon,
            data,
            seriestype = :bar,
            label = label,
            alpha = 0.5,
            color = color
        )
    end

    return g
end

# --------------------------------------------------------------------------- #

# Read data from nc file and crop it with specific dimensions
function getVar(nc; var = "", coord = (-180, 180, -90, 90))
    lon = nc["lon"]
    lat = nc["lat"]
    lon_c = collect(lon)
    lon_c[lon_c .> 180] = lon_c[lon_c .> 180] .- 360
    lon_sel = coord[1] .<= lon .<= coord[2]
    lat_sel = coord[3] .<= lat .<= coord[4]

    if var == "" || var == "lonlat"
        lon = lon[lon_sel]
        lat = lat[lat_sel]
        return lon, lat
    else
        res = nc[var][lon_sel,lat_sel,:]
        return res
    end
end

# =========================================================================== #
# PROCESS
# =========================================================================== #

datapath = "../data/"
area = (20, 120, -20, 50)
years = 1981:2016
coast_df = shp4plot(datapath * "shp/ne_110m_coastline.shp")

# --------------------------------------------------------------------------- #
# Spatial analysis

# Observed climatology
obs_cli_nc = Dataset(datapath * "prec/gpcp-obs_pre_cli-mon_spt.nc")
obs_cli = getVar(obs_cli_nc, var = "precip", coord = area)
obs_cli = mean(obs_cli[:,:,6:9], dims = 3)[:,:,1]

# Observed Standard deviation
obs_std_nc = Dataset(datapath * "prec/gpcp-obs_pre_std-mon_spt.nc")
obs_std = getVar(obs_std_nc, var = "precip", coord = area)
obs_std = mean(obs_std[:,:,6:9], dims = 3)[:,:,1]

# Coordinates
lon, lat = getVar(obs_cli_nc, var = "lonlat", coord = area)

# Assimilation climatology
asm_cli_nc = Dataset(datapath * "prec/mpi-echam-asm_pre_cli-mon_spt.nc");
asm_cli = getVar(asm_cli_nc, var = "precip", coord = area)
asm_cli = mean(asm_cli[:,:,6:9], dims = 3)[:,:,1]

# Assimilation Standard deviation
asm_std_nc = Dataset(datapath * "prec/mpi-echam-asm_pre_std-mon_spt.nc");
asm_std = getVar(asm_std_nc, var = "precip", coord = area)
asm_std = mean(asm_std[:,:,6:9], dims = 3)[:,:,1]

# Plot
g_spt_clim = plotCompSpatial(
    data1 = (obs_cli, obs_std),
    data2 = (asm_cli, asm_std),
    coord1 = (lon, lat),
    coord2 = (lon, lat),
    xtit = ("GPCP", "Assimilation"),
    ytit = ("Climatology", "Std. deviation"))
savefig(g_spt_clim, "../img/clim/spt_clim.png")

# --------------------------------------------------------------------------- #
# Monthly climatology and JJAS anomalies

# Monthly climatology
obs_cli_mon_nc = Dataset(datapath * "prec/gpcp-obs_pre_cli-mon_ts.nc")
obs_cli_mon = obs_cli_mon_nc["precip"]

asm_cli_mon_nc = Dataset(datapath * "prec/mpi-echam-asm_pre_cli-mon_ts.nc")
asm_cli_mon = asm_cli_mon_nc["precip"]

# JJAS anomalies time series
obs_jjas_ts_nc = Dataset(datapath * "prec/gpcp-obs_pre_1981-2016-JJAS_ts.nc")
obs_jjas_ts = obs_jjas_ts_nc["precip"]
obs_jjas_ts_anom = obs_jjas_ts .- mean(obs_jjas_ts[1:30])

asm_jjas_ts_nc = Dataset(datapath * "prec/mpi-echam-asm_pre_1981-2016-JJAS_ts.nc")
asm_jjas_ts = asm_jjas_ts_nc["precip"]
asm_jjas_ts_anom = asm_jjas_ts .- mean(asm_jjas_ts[1:30])

# Correlation between observed and assimilated precipitation
cor_pre_obs_asm = cor(obs_jjas_ts_anom, asm_jjas_ts)
cor_pre_obs_asm = round(cor_pre_obs_asm, digits = 2)

# Plot
g_prec_clim = plot(
    ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"], 
    [obs_cli_mon asm_cli_mon],
    seriestype = :bar, 
    label = ["GPCP" "Assim."],
    alpha = 0.5, 
    color = ["royalblue" "brown"],
    title = "Monthly climatology")

g_prec_anom = plot(
    years,
    [obs_jjas_ts_anom asm_jjas_ts_anom], 
    label = ["GPCP" "Assim."],
    linecolor = ["royalblue" "brown"],
    linewidth = 2,
    ylims = (-3,3),
    ylabel = "mm/day",
    title = "JJAS precipitation anomalies")
hline!([0], color = "gray", label = "")
annotate!(1982, -2.5, text("Correlation: " * string(cor_pre_obs_asm), :left, 10))

lay_clim_anom = @layout[a; b]
g_clim_anom = plot(
    g_prec_clim, 
    g_prec_anom,
    layout = lay_clim_anom)
plot!(dpi = 300, size = (800,650))

savefig(g_clim_anom, "../img/clim/clim_anom.png")
