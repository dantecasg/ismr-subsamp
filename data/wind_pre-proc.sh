#!/bin/bash

# -----------------------------------------------------------------------------
# Pre-procesing of wind data for the use in different indeces.
# TODO: Merge the other scripts with this (WYI for example).
#
# This scripts works with:
# - MPI ECHAM:
#   - /work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_uv_1980_2017.nc
#   - /work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_uv10_dm_1980_2017.nc
# - MPI ECHAM MR30:
#   - /work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/echam_uwind_mm_hcassimbt_r1-30_r1i1p1-MR_1980_2017.nc
# 
# IMPORTANT: remember to activate conda environment for ncks:
# - conda activate py39
# This is done to avoid 5-dimension problem with cdo for ensemble data
# Check: https://code.mpimet.mpg.de/boards/1/topics/7434
#
# Author: Dante T. Castro Garro
# Date: 2021-11-29
# -----------------------------------------------------------------------------

# General parameters
ruta="../../../data/wind"

# Cases
case $1 in
    ammasm) # Assimilated winds for Atlantic Meridinal Mode
        data="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_uv10_dm_1980_2017.nc"
        area="-75,15,-21,32"
        out="mpi-echam-asm_uv10m_1981-2016_amm-reg-1p0.nc"
        
        cdo -sellonlatbox,${area} -remapbil,r180x90 -monmean -selyear,1981/2016 -chname,var165,uwind -chname,var166,vwind ${data} ${ruta}/${out}
        ;;

    *) # Default
        echo "Nothing selected"
        ;;

esac
