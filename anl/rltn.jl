# --------------------------------------------------------------------------- #
# Precipitation climatology
#
# Author: Dante T. Castro Garro
# Date: 2022-01-18
# --------------------------------------------------------------------------- #

# =========================================================================== #
# LIBRARIES
# =========================================================================== #

using NCDatasets
using Plots
using ColorSchemes
using Shapefile
using DataFrames
using Statistics
using CSV
using StatsPlots
using Dates
using HypothesisTests
using Distributions

# =========================================================================== #
# FUNCTIONS
# =========================================================================== #

include("../src/funcs_plot.jl")
include("../src/funcs_stat.jl")
include("../src/funcs_nc.jl")

# --------------------------------------------------------------------------- #
# Data analysis

# Load the indexes creating a specific output that only works in this notebook/script
# Only for indexes: DMI, WIO, WYI and AMM
function loadIndex(idx)
    # Observed
    idx_obs = CSV.File(datapath * "index/" * idx * "-obs_1981-2016-mon.csv")
    idx_obs = DataFrame(
        year = idx_obs.year,
        month = idx_obs.month,
        idx = vcat(NaN, runMean(idx_obs.idx, 3), NaN)
    )
    idx_obs = subset(idx_obs, :month => ByRow(>=(2)), :month => ByRow(<=(7)))
    idx_obs = reshape(idx_obs.idx, 6, 36)'

    # Assimilarion
    idx_asm = CSV.File(datapath * "index/" * idx * "-asm_1981-2016-mon.csv")
    idx_asm = DataFrame(
        year = idx_asm.year,
        month = idx_asm.month,
        idx = vcat(NaN, runMean(idx_asm.idx, 3), NaN)
    )
    idx_asm = subset(idx_asm, :month => ByRow(>=(2)), :month => ByRow(<=(7)))
    idx_asm = reshape(idx_asm.idx, 6, 36)'

    # Normalizing
    for i in 1:6
        idx_obs[:,i] = normalize(idx_obs[:,i])
        idx_asm[:,i] = normalize(idx_asm[:,i])
    end

    return idx_obs, idx_asm
end

# Phased corrleation
function phaCor(; obs_ts, obs_idx, asm_ts, asm_idx, n = 6)
    obs_pha_cor = zeros(n)
    asm_pha_cor = zeros(n)

    for i in 1:n
        obs_pha_cor[i] = cor(obs_ts, obs_idx[:,i])
        asm_pha_cor[i] = cor(asm_ts, asm_idx[:,i])
    end

    pha_corr = zeros(n,2)
    pha_corr[:,1] = obs_pha_cor
    pha_corr[:,2] = asm_pha_cor

    return pha_corr
end

# --------------------------------------------------------------------------- #
# Plot functions

# Plot for spatial correlation
function sptCorrPlot(;x, y, z, shp, tit)
    g_spt_cor = contourf(
        x, y, z, 
        linewidth = 0,
        c = cgrad(:bluesreds),
        clims = (-1,1))
    plot!(
        shp, 
        fillalpha = 0, 
        legend = false, 
        linecolor = "black")
    title!(tit)
    xlims!((50.0, 110.0))
    ylims!((0.0, 40.0))

    return g_spt_cor
end

# Bar plot of phase correlation
function phaBarPlot(tbl)
    nam = repeat(["Obs.", "Assim."], outer = 6)
    ctg_lab = ["2-JFM", "3-FMA", "4-MAM", "5-AMJ", "6-MJJ", "7-JJA"]
    ctg = repeat(ctg_lab, inner = 2)

    g_lag = groupedbar(nam, tbl', stack = :dodge, group = ctg)
    hline!([0], linecolor = "gray", label = "")
    plot!(legend = :outerright)
    ylims!((-1,1))
    ylabel!("Correlation")
    title!("JJAS precipitation vs lagged index")

    return g_lag
end

# Line correlation plot
function lineCorPlot(;
        x, y1, y2, corr,
        label1, label2,
        col1 = "royalblue", col2 = "brown",
        ylab, tit)

    g = plot(x, y1, label = label1, linecolor = col1, lw = 2)
    plot!(x, y2, label = label2, linecolor = col2, lw = 2)
    hline!([0], linecolor = "gray", label = "")
    ylims!((-3, 3))
    ylabel!(ylab)
    title!(tit)
    annotate!(1982, -2.5, text("Correlation: " * string(corr), :left, 10))

    return g
end

# Combining plots
function combPlot(p1, p2, p3, p4)
    l = @layout[a b; c d]
    g = plot(p1, p2, p3, p4, layout = l)
    plot!(dpi = 300, size = (1000,650))
    plot!(margin = 5Plots.mm)

    return g
end

# One function for all the analysis
function anlTot(;
        obs_ts , asm_ts,
        obs_idx, asm_idx,
        obs_spt, asm_spt,
        obs_lon, asm_lon,
        obs_lat, asm_lat,
        shp,
        tit_spt_obs,
        tit_spt_asm,
        tit_lag,
        tit_ts)

    obs_idx_jja = obs_idx[:,6]
    asm_idx_jja = asm_idx[:,6]

    obs_spt_cor = sptCor(obs_spt, obs_idx_jja)
    asm_spt_cor = sptCor(asm_spt, asm_idx_jja)

    # Observed
    g_spt_obs_cor = sptCorrPlot(
        x = obs_lon,
        y = obs_lat,
        z = obs_spt_cor',
        shp = shp, 
        tit = tit_spt_obs)

    # Assimilation
    g_spt_ass_cor = sptCorrPlot(
        x = asm_lon,
        y = asm_lat,
        z = asm_spt_cor', 
        shp = shp, 
        tit = tit_spt_asm)

    # Lagged correlation
    pha_cor = phaCor(
        obs_ts  = obs_ts,
        obs_idx = obs_idx,
        asm_ts  = asm_ts,
        asm_idx = asm_idx)
    g_lag = phaBarPlot(pha_cor)

    # Time series correlation
    cor_obs_asm = cor(obs_idx_jja, asm_idx_jja)
    cor_obs_asm = round(cor_obs_asm, digits = 2)

    g_ts = lineCorPlot( 
        x = 1981:2016, y1 = obs_idx_jja, y2 = asm_idx_jja,
        corr = cor_obs_asm,
        label1 = "Obs.", label2 = "Assim.", 
        ylab = "", 
        tit = tit_ts)

    # Combining figures
    g = combPlot(g_spt_obs_cor, g_spt_ass_cor, g_lag, g_ts)

    return g
end

# =========================================================================== #
# PROCESS
# =========================================================================== #

datapath = "../data/"
coast_df = shp4plot(datapath * "shp/ne_110m_coastline.shp")
area = (20,120,-20,50)

# --------------------------------------------------------------------------- #
# Loading data

# Precipitation - spatial
gpcp_spt_nc = Dataset(datapath * "prec/gpcp-obs_pre_1981-2016-JJAS_spt.nc")
pre_obs = ncVarGet(gpcp_spt_nc, var = "precip", coord = area)
lon_obs, lat_obs = ncVarGet(gpcp_spt_nc, var = "lonlat", coord = area)

asm_spt_nc = Dataset(datapath * "prec/mpi-echam-asm_pre_1981-2016-JJAS_spt.nc")
pre_asm = ncVarGet(asm_spt_nc, var = "precip", coord = area)
lon_asm, lat_asm = ncVarGet(asm_spt_nc, var = "lonlat", coord = area)

mem_pre_nc = Dataset(datapath * "prec/mpi-echam-ens_pre_1981-2016-JJAS_spt.nc")
pre_mem = ncVarGet(mem_pre_nc, var = "precip", coord = area)
pre_ens = mean(pre_mem, dims = 3)[:,:,1,:]

# Precipitation - time series
gpcp_ts_nc = Dataset(datapath * "prec/gpcp-obs_pre_1981-2016-JJAS_ts.nc")
pre_obs_ts = gpcp_ts_nc["precip"]
pre_obs_ts_anom = pre_obs_ts .- mean(pre_obs_ts[1:30])

assim_ts_nc = Dataset(datapath * "prec/mpi-echam-asm_pre_1981-2016-JJAS_ts.nc")
pre_asm_ts = assim_ts_nc["precip"]
pre_asm_ts_anom = pre_asm_ts .- mean(pre_asm_ts[1:30])

# ONI
oni_obs = DataFrame(CSV.File(datapath * "index/oni-obs_1982-2021-mon.csv"))
oni_obs = oni_obs[(oni_obs.year .<= 2016),:]
oni_obs = subset(oni_obs, :month => ByRow( >=(2) ), :month => ByRow( <=(7) ))
oni_obs = reshape(oni_obs.idx, 6, 35)'

oni_asm = DataFrame(CSV.File(datapath * "index/oni-asm_1981-2016-mon.csv"))
oni_asm = subset(oni_asm, :month => ByRow( >=(2) ), :month => ByRow( <=(7) ))
oni_asm = reshape(oni_asm.idx, 6, 36)'

for i in 1:6
    oni_obs[:,i] = normalize(oni_obs[:,i])
    oni_asm[:,i] = normalize(oni_asm[:,i])
end

# DMI, WIO and WYO
dmi_obs, dmi_asm = loadIndex("dmi")
wio_obs, wio_asm = loadIndex("wio")
wyi_obs, wyi_asm = loadIndex("wyi")

# AMM
amm_obs_tmp = CSV.File(datapath * "index/amm-obs_1981-2016-mon.csv")
amm_obs_mov = runMean(amm_obs_tmp.amm, 3)
amm_obs_dfr = DataFrame(
    time = amm_obs_tmp.time[1:end-1], 
    amm = vcat(NaN, amm_obs_mov))
amm_obs_dfr = transform(amm_obs_dfr, :time => (x -> month.(x)) => :month)
amm_obs_dfr = subset(amm_obs_dfr, :month => ByRow(>=(2)), :month => ByRow(<=(7)))
amm_obs = reshape(amm_obs_dfr.amm, 6, 36)'

amm_asm_tmp = CSV.File(datapath * "index/amm-asm_1981-2016-mon.csv")
amm_asm_dfr = DataFrame(
    time = DateTime.(amm_asm_tmp.time[1:end-1], dateformat"y-m-d H:M:s"),
    amm = vcat(NaN, runMean(amm_asm_tmp.amm, 3)))
amm_asm_dfr = transform(amm_asm_dfr, :time => (x -> month.(x)) => :month)
amm_asm_dfr = subset(
    amm_asm_dfr, 
    :month => ByRow( >=(2) ), 
    :month => ByRow( <=(7) ))
amm_asm = reshape(amm_asm_dfr.amm, 6, 36)'

for i in 1:6
    amm_obs[:,i] = normalize(amm_obs[:,i])
    amm_asm[:,i] = normalize(amm_asm[:,i])
end

# --------------------------------------------------------------------------- #
# Correlations

# Spatial correlation with ONI
oni_obs_spt_cor = sptCor(pre_obs[:,:,2:36], oni_obs[:,6])
oni_asm_spt_cor = sptCor(pre_asm, oni_asm[:,6])

# Plots
# Observed
g_oni_obs_spt_cor = sptCorrPlot(
    x = lon_obs,
    y = lat_obs,
    z = oni_obs_spt_cor',
    shp = coast_df.shapes, 
    tit = "Obs. Corr. Precip. (JJAS) vs ONI (JJA)")

# Assimilation
g_oni_asm_spt_cor = sptCorrPlot(
    x = lon_asm,
    y = lat_asm,
    z = oni_asm_spt_cor', 
    shp = coast_df.shapes, 
    tit = "Assim. Corr. Precip. (JJAS) vs ONI (JJA)")

# Lagged correlation
pha_cor_oni = phaCor(
    obs_ts  = pre_obs_ts_anom[2:36],
    obs_idx = oni_obs,
    asm_ts  = pre_asm_ts_anom,
    asm_idx = oni_asm)
g_lag_oni = phaBarPlot(pha_cor_oni)

# Obs vs Assim
oni_obs_asm_cor = cor(oni_obs[:,6], oni_asm[2:36,6])
oni_obs_asm_cor = round(oni_obs_asm_cor, digits = 2)

g_oni_obs_asm_cor = lineCorPlot(
    x = 1981:2016,
    y1 = vcat(NaN, oni_obs[:,6]),
    y2 = oni_asm[:,6],
    corr = oni_obs_asm_cor,
    label1 = "CPC", label2 = "Assim.",
    ylab = "°C",
    tit = "ONI-CPC vs ONI-Assimilation (JJA)")

# Combining plots
g_oni_cor = combPlot(
    g_oni_obs_spt_cor,
    g_oni_asm_spt_cor,
    g_lag_oni,
    g_oni_obs_asm_cor)
savefig(g_oni_cor, "../img/corr/oni_cor.png")

# Correlation with DMI
g_dmi_cor = anlTot(
    obs_ts  = pre_obs_ts_anom,
    asm_ts  = pre_asm_ts_anom,
    obs_idx = dmi_obs,
    asm_idx = dmi_asm,
    obs_spt = pre_obs,
    asm_spt = pre_asm,
    obs_lon = lon_obs,
    obs_lat = lat_obs,
    asm_lon = lon_asm,
    asm_lat = lat_asm,
    shp = coast_df.shapes,
    tit_spt_obs = "Obs. Corr. Precip. (JJAS) vs DMI (JJA)",
    tit_spt_asm = "Assim. Corr. Precip. (JJAS) vs DMI (JJA)",
    tit_lag = "Lagged correlation",
    tit_ts = "DMI-Obs vs DMI-Assimilation (JJA)")
savefig(g_dmi_cor, "../img/dmi_cor.png")

# Correlation with WIO
g_wio_cor = anlTot(
    obs_ts  = pre_obs_ts_anom,
    asm_ts  = pre_asm_ts_anom,
    obs_idx = wio_obs,
    asm_idx = wio_asm,
    obs_spt = pre_obs,
    asm_spt = pre_asm,
    obs_lon = lon_obs,
    obs_lat = lat_obs,
    asm_lon = lon_asm,
    asm_lat = lat_asm,
    shp = coast_df.shapes,
    tit_spt_obs = "Obs. Corr. Precip. (JJAS) vs WIO (JJA)",
    tit_spt_asm = "Assim. Corr. Precip. (JJAS) vs WIO (JJA)",
    tit_lag = "Lagged correlation",
    tit_ts = "WIO-Obs vs WIO-Assimilation (JJA)")
savefig(g_wio_cor, "../img/corr/wio_cor.png")

# Correlation with WYI
g_wyi_cor = anlTot(
    obs_ts  = pre_obs_ts_anom,
    asm_ts  = pre_asm_ts_anom,
    obs_idx = wyi_obs,
    asm_idx = wyi_asm,
    obs_spt = pre_obs,
    asm_spt = pre_asm,
    obs_lon = lon_obs,
    obs_lat = lat_obs,
    asm_lon = lon_asm,
    asm_lat = lat_asm,
    shp = coast_df.shapes,
    tit_spt_obs = "Obs. Corr. Precip. (JJAS) vs WYI (JJA)",
    tit_spt_asm = "Assim. Corr. Precip. (JJAS) vs WYI (JJA)",
    tit_lag = "Lagged correlation",
    tit_ts = "WYI-ERA5 vs WYI-Assimilation (JJA)")
savefig(g_wyi_cor, "../img/corr/wyi_cor.png")

# Correlation with AMM
g_amm_cor = anlTot(
    obs_ts  = pre_obs_ts_anom,
    asm_ts  = pre_asm_ts_anom,
    obs_idx = amm_obs,
    asm_idx = amm_asm,
    obs_spt = pre_obs,
    asm_spt = pre_asm,
    obs_lon = lon_obs,
    obs_lat = lat_obs,
    asm_lon = lon_asm,
    asm_lat = lat_asm,
    shp = coast_df.shapes,
    tit_spt_obs = "Obs. Corr. Precip. (JJAS) vs AMM (JJA)",
    tit_spt_asm = "Assim. Corr. Precip. (JJAS) vs AMM (JJA)",
    tit_lag = "Lagged correlation",
    tit_ts = "AMM-Obs vs AMM-Assim. (JJA)")
savefig(g_amm_cor, "../img/corr/amm_cor.png")

# --------------------------------------------------------------------------- #
# Spatial correlation between observed and ensemble mean precipitation

cor_pre_obs_ens = sptCor(pre_obs, pre_ens)
g_cor_pre_obs_ens = sptCorrPlot(
    x = lon_obs,
    y = lat_obs,
    z = cor_pre_obs_ens',
    shp = coast_df.shapes,
    tit = "Spatial corr. GPCP and Ensemble mean (JJAS)")
