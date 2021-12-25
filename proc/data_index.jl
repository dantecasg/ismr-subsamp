# --------------------------------------------------------------------------- #
# Getting indeces data from different sources
#
# Author: Dante Castro Garro (dante.tcg@gmail.com)
# Date: 2021-10-07
# --------------------------------------------------------------------------- #

# =========================================================================== #
# LIBRARIES
# =========================================================================== #

using NCDatasets
using Statistics
using DataFrames
using Dates
using CSV

# =========================================================================== #
# FUNCIONES
# =========================================================================== #

include("../src/funcs_nc.jl")
include("../src/funcs_stat.jl")
include("../src/funcs_index.jl")

# =========================================================================== #
# PROCESSING
# =========================================================================== #

# General parametersDMI
datapath = "../data/"
idx = ARGS[1]
# idx = "oni"

# Data sources
if idx != "wyi"
    obs_src = idx == "oni" ? "sst/noaa-oisst_sst_1982-2021-mon.nc" : "sst/hadisst-obs_sst_1981-2016-mon.nc"
    fil_obs = Dataset(datapath * obs_src);
    fil_asm = Dataset(datapath * "sst/mpi-om-asm_sst_1981-2016-mon.nc");
    fil_mem = Dataset(datapath * "sst/mpi-om-ens_sst_1981-2016-mon.nc");
    var = "sst"
    lon_name = "lon"
    lat_name = "lat"

else
    fil_obs = (
        Dataset(datapath * "wind/era5_uwind_1981-2016-mon_lev-850.nc"),
        Dataset(datapath * "wind/era5_uwind_1981-2016-mon_lev-200.nc"));
    fil_asm = (
        Dataset(datapath * "wind/echam6-asm_uwind_1981-2016-mon_lev-850.nc"),
        Dataset(datapath * "wind/echam6-asm_uwind_1981-2016-mon_lev-200.nc"));
    fil_mem = (
        Dataset(datapath * "wind/echam6-mem_uwind_1981-2016-mon_lev-850_crop.nc"),
        Dataset(datapath * "wind/echam6-mem_uwind_1981-2016-mon_lev-200_crop.nc"));
    var = "uwind"
    lon_name = "longitude"
    lat_name = "latitude"

end

# ........................................................................... #

# Observed
obs = getIndex(fil_obs, var, idx, lon_name = lon_name, lat_name = lat_name)
if idx == "oni"
    CSV.write(datapath * "index/oni-obs_1982-2021-mon.csv", obs)
else
    CSV.write(datapath * "index/" * idx * "-obs_1981-2016-mon.csv", obs)
end

# Assimilation
asm = getIndex(fil_asm, var, idx, lon_name = "lon", lat_name = "lat")
CSV.write(datapath * "index/" * idx * "-asm_1981-2016-mon.csv", asm)

# Ensemble mean
mem = DataFrame(
    member = Int64[],
    year = Int64[],
    month = Int64[],
    idx = Float64[])

for i in 1:30
    local tmp = getIndex(fil_mem, var, idx, n_mem = i, lon_name = "lon", lat_name = "lat")
    tmp[:,"member"] .= i
    append!(mem, tmp)
end
CSV.write(datapath * "index/" * idx * "-mem_1981-2016-mon.csv", mem)

