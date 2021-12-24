#!/bin/bash

# -----------------------------------------------------------------------------
# Setup directories for the project.
# data
# |
# +-- sst
# +-- prec
# +-- wind
# +-- index
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
ruta="/work/uo1075/b381534/data/masks"
cp $ruta/india_mask_GPCP.nc data/mask/
cp $ruta/india_mask_MR30.nc data/mask/

# Precipitation time series
./prec_ts.sh obs month
./prec_ts.sh asm month
./prec_ts.sh ens month

# Sea surface data for indexes calculation
./sst_spt.sh obs month
./sst_spt.sh asm month
./sst_spt.sh ens month
mv *.nc data/sst/

# Winds for the calculation of Webster Yang Index
./wind.sh era5
./wind.sh asmmon
./wind.sh ens
