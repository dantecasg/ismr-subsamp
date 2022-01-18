# --------------------------------------------------------------------------- #
# Images for SST analysis
#
# Author: Dante T. Castro Garro
# Date: 2022-01-16
# --------------------------------------------------------------------------- #

# =========================================================================== #
# LIBRARIES
# =========================================================================== #

using NCDatasets
using Statistics
using DataFrames
using CSV
using Plots
using ColorSchemes
using Shapefile
using Distributions

# =========================================================================== #
# FUNCTIONS
# =========================================================================== #

include("../src/funcs_plot.jl")
include("../src/funcs_nc.jl")
include("../src/funcs_stat.jl")

# Plot correlation map with significant regions
function plotSpt(x, y, z, shp; cb, clims, xlims, ylims, pval = missing)
    g = contourf(
        x, y, z,
        linewidth = 0,
        #levels = 9,
        #colorbar_ticks = [-1:0.2:1],
        c = cb,
        clims = clims,
        colorbartitle = "Correlation")

    plot!(
        shp.shapes, 
        fillcolor = "grey",
        legend = false, 
        linecolor = "black")

    if !ismissing(pval)
        px = []
        py = []
        for i in 1:size(x,1), j in 1:size(y,1)
            if !ismissing(pval[i,j])
                push!(px, x[i])
                push!(py, y[j])
            end
        end
        scatter!(
            px, py,
            markersize = 2,
            markerstrokewidth = 0,
            markeralpha = 0.3,
            markercolor = "black")
    end

    plot!(
        shp.ishapes, 
        fillcolor = "grey",
        legend = false, 
        linecolor = "black")
    xlims!(xlims)
    ylims!(ylims)

    return g
end

# =========================================================================== #
# PROCESS
# =========================================================================== #

# General parameters
datapath = "../data/"
coast_df = shp4plot(datapath * "shp/ne_110m_land.shp")
area = (30, 330, -30, 40)

# Loading SST data
sst_obs_fl = Dataset(datapath * "sst/hadisst-obs_sst_1981-2016-JJA-cli.nc")
sst_asm_fl = Dataset(datapath * "sst/mpi-om-asm_sst_1981-2016-JJA-cli.nc")
sst_mem_fl = Dataset(datapath * "sst/mpi-om-ens_sst_1981-2016-JJA-cli.nc")

lon, lat = ncVarGet(sst_obs_fl, var = "lonlat", coord = area)
sst_obs = ncVarGet(sst_obs_fl, var = "sst", coord = area)
sst_asm = ncVarGet(sst_asm_fl, var = "sst", coord = area)
sst_mem = ncVarGet(sst_mem_fl, var = "sst", coord = area)
sst_mem = mean(sst_mem, dims = 3)[:,:,1,:]

# Loading precipitation data
gpcp_fl = Dataset(datapath * "prec/gpcp-obs_pre_1981-2016-JJAS_ts.nc")
prec_obs = gpcp_fl["precip"]
prec_obs_anom = prec_obs .- mean(prec_obs[1:30])

asm_fl = Dataset(datapath * "prec/mpi-echam-asm_pre_1981-2016-JJAS_ts.nc")
prec_asm = asm_fl["precip"]
prec_asm_anom = prec_asm .- mean(prec_asm[1:30])

# --------------------------------------------------------------------------- #

# SST Spatial correlation
sst_obs_asm_cor, sst_obs_asm_pvl = sptCor(
    sst_obs,
    sst_asm,
    pval = true,
    autocor = true
)

sst_obs_ens_cor, sst_obs_ens_pvl = sptCor(
    sst_obs,
    sst_mem,
    pval = true,
    autocor = true
)

# Graph of observed vs (assimilation & ensemble mean) spatial correlation
g_sst_cor_asm = plotSpt(
    lon, lat, sst_obs_asm_cor',
    coast_df,
    pval = sst_obs_asm_pvl,
    cb = cgrad(:Reds_9, rev = false),
    clims = (0,1),
    xlims = (30.0, 330.0),
    ylims = (-30.0, 40.0)
)
title!("Obs. vs Assim (JJA) | SST data")
plot!(rectangle(50, 10, 190, -5), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 20, 50, -10), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 10, 90, -10), fillalpha = 0, linecolor = "black", lw = 2)

g_sst_cor_mem = plotSpt(
    lon, lat, sst_obs_ens_cor',
    coast_df,
    pval = sst_obs_ens_pvl,
    cb = cgrad(:Reds_9, rev = false),
    clims = (0,1),
    xlims = (30.0, 330.0),
    ylims = (-30.0, 40.0)
)
title!("Obs. vs Ensemble mean (JJA) | SST data")
plot!(rectangle(50, 10, 190, -5), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 20, 50, -10), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 10, 90, -10), fillalpha = 0, linecolor = "black", lw = 2)

l_sst_cor = @layout[a; b]
g_sst_cor = plot(
    g_sst_cor_asm,
    g_sst_cor_mem,
    layout = l_sst_cor)
plot!(dpi = 300, size = (900,600))

savefig(g_sst_cor, "../img/sst/sst_obs_asm.png")

# --------------------------------------------------------------------------- #

# Precipitation spatial correlation
obs_pre_sst_cor, obs_pre_sst_pvl = sptCor(
    sst_obs,
    prec_obs_anom,
    pval = true,
    autocor = true
)

asm_pre_sst_cor, asm_pre_sst_pvl = sptCor(
    sst_asm,
    prec_asm_anom,
    pval = true,
    autocor = true
)

# Graph of observed vs (assimilation & ensemble mean) spatial correlation
g_sst_prec_obs = plotSpt(
    lon, lat, obs_pre_sst_cor',
    coast_df,
    pval = obs_pre_sst_pvl,
    cb = cgrad(:RdBu_11, rev = true), 
    clims = (-1,1),
    xlims = (30.0, 330.0),
    ylims = (-30.0, 40.0)
)
title!("Precip. (JJAS) vs SST (JJA) | Observed data")
plot!(rectangle(50, 10, 190, -5), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 20, 50, -10), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 10, 90, -10), fillalpha = 0, linecolor = "black", lw = 2)

g_sst_prec_asm = plotSpt(
    lon, lat, asm_pre_sst_cor',
    coast_df,
    cb = cgrad(:RdBu_11, rev = true),
    pval = asm_pre_sst_pvl,
    clims = (-1,1),
    xlims = (30.0, 330.0),
    ylims = (-30.0, 40.0)
)
title!("Precip. (JJAS) vs SST (JJA) | Assimilated data")
plot!(rectangle(50, 10, 190, -5), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 20, 50, -10), fillalpha = 0, linecolor = "black", lw = 2)
plot!(rectangle(20, 10, 90, -10), fillalpha = 0, linecolor = "black", lw = 2)

l_sst_prec = @layout[a; b]
g_sst_prec = plot(
    g_sst_prec_obs,
    g_sst_prec_asm,
    layout = l_sst_prec)
plot!(dpi = 300, size = (900,600))

savefig(g_sst_prec, "../img/sst/sst_prec.png")

# --------------------------------------------------------------------------- #

# Exporting the significant regions as a mask

sig_msk_nc = NCDataset(datapath * "mask/sst_sig_msk.nc", "c")
# Dimensions
defDim(sig_msk_nc, "lon", length(lon))
defDim(sig_msk_nc, "lat", length(lat))
# Global attributes
sig_msk_nc.attrib["title"] = "Mask for significant regions for SST"
# Define variables
asm_pre_sst_pvl_msk = .!ismissing.(asm_pre_sst_pvl)
sig_msk_var = defVar(sig_msk_nc, "mask", Int64, ("lon", "lat"))
sig_msk_var[:,:] = asm_pre_sst_pvl_msk
# Writting attributes
sig_msk_var.attrib["comments"] = "Only grids with p-value lower than 0.05"
close(sig_msk_nc)

