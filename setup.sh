#!/bin/bash

# -----------------------------------------------------------------------------
# Setup directories, prepare data and run scripts for the project.
# This script requires 'cdo' and 'ncks' (by doing `conda activate py39`)
#
# Author: Dante T. Castro Garro
# Date: 2022-01-16
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Data processing

# Creating directories
mkdir data
mkdir data/sst data/prec data/wind data/index
mkdir data/mask
mkdir data/shp
mkdir img
mkdir img/subsamp img/corr img/clim img/sst

# Changing directory
cd proc/

# Download data that is not available in the server
ruta="/work/uo1075/b381534/data"
cp $ruta"/masks/india_mask_GPCP.nc" "../data/mask/"
cp $ruta"/masks/india_mask_MR30.nc" "../data/mask/"
cp $ruta"/GPCP/GPCP__V2_3__PRECIP__2.5x2.5_sel.nc" "../data/prec/"
cp $ruta"/SST/noaa-oisst_sst_1982-2021-mon.nc" "../data/sst/"
cp $ruta"/SST/noaa-ersstv5_sst_1854-2021-mon_2p5.nc" "../data/sst/"
cp $ruta"/wind/era5_uwind_1981-2016_lev-200-850.nc" "../data/wind/"
cp $ruta"/wind/ncep-ncar_uwind_1948-2021-mon_10m.nc" "../data/wind/"
cp $ruta"/wind/ncep-ncar_vwind_1948-2021-mon_10m.nc" "../data/wind/"
cp $ruta"/shp/ne_110m_coastline.*" "../data/shp/"
cp $ruta"/shp/ne_110m_land.*" "../data/shp/"

# Precipitation time series
./prec.sh obs monthcli ts
./prec.sh asm monthcli ts
./prec.sh ens monthcli ts
./prec.sh obs jjas ts
./prec.sh asm jjas ts
./prec.sh ens jjas ts
# Precipitation spatial data
./prec.sh obs jjas spt
./prec.sh asm jjas spt
./prec.sh ens jjas spt
# Precipitation monthly climatology
./prec.sh obs monthcli spt
./prec.sh asm monthcli spt
./prec.sh obs monthstd spt
./prec.sh asm monthstd spt

# Sea surface data for indexes calculation
./sst.sh obs month
./sst.sh asm month
./sst.sh ens month
# Seas surface JJA climatology
./sst.sh obs jja
./sst.sh asm jja
./sst.sh ens jja

# Winds for the calculation of Webster Yang Index
./wind.sh era5
./wind.sh asmmon
./wind.sh ens

# Calculate indexes
julia --project=../ data_index.jl oni
julia --project=../ data_index.jl dmi
julia --project=../ data_index.jl wio
julia --project=../ data_index.jl wyi

# Calculate AMM index
# It depends on the version of python, change it if needed
./wind.sh ammasm
python3.9 amm_index_obs.py
python3.9 amm_index_asm.py
python3.9 amm_index_mem.py

# ------------------------------------------------------------------------------
# Analysis
cd ../nb
julia --project=../ nb_subsamp.jl
julia --project=../ nb_rltn.jl
julia --project=../ nb_clim.jl
julia --project=../ nb_sst.jl

# ------------------------------------------------------------------------------
# Notebooks - Pluto
#
# The notebooks have the same content as the Analysis scripts, but they can be 
# interactively run and modified (the same way as it is done with Jupyter).
# 
# For the notebooks follow this steps:
# 1) Access Julia activating the project (this github repo):
# julia --project=.
#
# 2) Install Pluto library (skip to step 3 if already installed):
# using Pkg; Pkg.add("Pluto")
#
# 3) Load Pluto and excecute
# using Pluto
# Pluto.run()
#
# After this, a webpage should open where you can look for the notebooks and 
# load them.
