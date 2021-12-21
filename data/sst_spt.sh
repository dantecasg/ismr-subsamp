#!/bin/bash

# -----------------------------------------------------------------------------
# Spatial values for SST.
# Period: 1981-2016
# Season: JJA / monthly
# Region: ---
# Source:
# - Observed: HadISST /pool/data/ICDC/ocean/hadisst1/DATA/HadISST_sst.nc
# - Assimilation: MPI-OM ../../../data/MR30/asOEffESIP_r1i1p1-MR_mpiom_data_2d_mm_sst_1980_2017.nc
# - Ensemble: MPI-OM /work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/hcassimbt_r1-30_i1p1-MR_mpiom_data_2d_sst_1980_2016.nc
# 
# Author: Dante T. Castro Garro
# Date: 2021-10-05
# -----------------------------------------------------------------------------

# General parameters
ruta="../../../data"

# Data source selection
case $1 in
    obs)
        data="/pool/data/ICDC/ocean/hadisst1/DATA/HadISST_sst.nc"
        out="${ruta}/SST/hadisst_sst_1981-2016"
        ;;

    asm)
        data="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_mpiom_data_2d_mm_sst_1980_2017.nc"
        out="${ruta}/SST/mpi-om-asm_sst_1981-2016"
        ;;

    ens)
        data="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/hcassimbt_r1-30_i1p1-MR_mpiom_data_2d_sst_1980_2016.nc"
        out="${ruta}/SST/mpi-om-ens_sst_1981-2016"
        ;;

    *) # Default
        echo "No data source was selected" 
        exit 
        ;;
esac

# Method
case $2 in
    mon)
        cdo --reduce_dim -remapbil,r180x90 -monmean -selyear,1981/2016 -selname,sst ${data} ${out}-mon.nc
        ;;
    jja)
        cdo --reduce_dim -remapbil,r180x90 -yearmean -monmean -selseason,JJA -selyear,1981/2016 -selname,sst ${data} ${out}-JJA.nc
        ;;
    *) # Default
        echo "No method was selected"
        exit
        ;;
esac

