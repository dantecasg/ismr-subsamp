# using DataFrames
# using CSV
using Statistics
using HypothesisTests
using StatsBase
using Distributions
using NCDatasets

include("funcs_nc.jl")
include("funcs_stat.jl")
# include("funcs_index.jl")

datapath = "../../data/"

sst_obs_fl = Dataset(datapath * "SST/hadisst_sst_1981-2016-JJA.nc");
lon, lat = ncVarGet(sst_obs_fl, var = "lonlat", coord = (30,330,-30,40));
sst_obs = ncVarGet(sst_obs_fl, var = "sst", coord = (30,330,-30,40));

gpcp_fl = Dataset(datapath * "prec/gpcp_pre_1981-2016-JJAS_ts.nc");
prec_obs = gpcp_fl["precip"];
prec_obs_anom = prec_obs .- mean(prec_obs[1:30]);
