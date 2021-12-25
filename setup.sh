#!/bin/bash

# -----------------------------------------------------------------------------
# Setup directories for the project.
# This script requires 'cdo' and 'ncks' (by doing `conda activate py39`)
#
# data
# |
# +-- sst
# +-- prec
# +-- wind
# +-- index
#
# NOTE: For the processing of wind data you need to activate
#
# Author: Dante T. Castro Garro
# Date: 2021-12-23
# -----------------------------------------------------------------------------

# Creating directories
mkdir data
mkdir data/sst data/prec data/wind data/index
mkdir data/mask

# Changing directory
cd proc/

# Download data that is not available in the server
ruta="/work/uo1075/b381534/data"
cp $ruta"/masks/india_mask_GPCP.nc" "../data/mask/"
cp $ruta"/masks/india_mask_MR30.nc" "../data/mask/"
cp $ruta"/GPCP/GPCP__V2_3__PRECIP__2.5x2.5_sel.nc" "../data/prec/"
cp $ruta"/SST/noaa-oisst_sst_1982-2021-mon.nc" "../data/sst/"
cp $ruta"/wind/era5_uwind_1981-2016_lev-200-850.nc" "../data/wind/"

# Precipitation time series
./prec_ts.sh obs month
./prec_ts.sh asm month
./prec_ts.sh ens month

# Sea surface data for indexes calculation
./sst_spt.sh obs month
./sst_spt.sh asm month
./sst_spt.sh ens month

# Winds for the calculation of Webster Yang Index
./wind.sh era5
./wind.sh asmmon
./wind.sh ens

# Calculate indexes
cd ../
julia --project=. proc/data_index.jl oni
julia --project=. proc/data_index.jl dmi
julia --project=. proc/data_index.jl wio
julia --project=. proc/data_index.jl wyi
