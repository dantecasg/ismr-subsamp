#!/bin/bash

# -----------------------------------------------------------------------------
# Data for Western Indian Ocean for different datasets.
# This scripts works with:
# - HadISST (observed): /pool/data/ICDC/ocean/hadisst1/DATA/HadISST_sst.nc
# - MPI-OM (assimilation): ../../../data/MR30/asOEffESIP_r1i1p1-MR_mpiom_data_2d_mm_sst_1980_2017.nc
# Author: Dante T. Castro Garro
# -----------------------------------------------------------------------------

## Assimilation
# DATA="../../../data/MR30/asOEffESIP_r1i1p1-MR_mpiom_data_2d_mm_sst_1980_2017.nc"
# FUENTE="MPI_sst_assim"

# Observed
# FUENTE=HadISST

# Ensemble
# DATA="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/hcassimbt_r1-30_i1p1-MR_mpiom_data_2d_sst_1980_2016.nc"
# FUENTE="MPI_sst_mr30"

# Cases
case $1 in
    obsjja)
        DATA=/pool/data/ICDC/ocean/hadisst1/DATA/HadISST_sst.nc
        OUT=../../../data/SST/wio_obs_JJA.nc

        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,JJA -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} ${OUT}
        ;;

    obstri)
        DATA=/pool/data/ICDC/ocean/hadisst1/DATA/HadISST_sst.nc
        OUT=../../../data/SST/wio_obs_tri.nc

        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,JFM -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp2.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,FMA -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp3.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,MAM -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp4.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,AMJ -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp5.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,MJJ -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp6.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,JJA -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp7.nc

        cdo mergetime temp*.nc ${OUT}
        rm *.nc
        ;;

    asmtri)
        DATA=../../../data/MR30/asOEffESIP_r1i1p1-MR_mpiom_data_2d_mm_sst_1980_2017.nc
        OUT=../../../data/SST/wio_asm_tri.nc

        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,JFM -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp2.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,FMA -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp3.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,MAM -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp4.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,AMJ -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp5.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,MJJ -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp6.nc
        cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,JJA -selyear,1981/2016 -sellonlatbox,50,70,-10,10 -selname,sst ${DATA} temp7.nc

        cdo mergetime temp*.nc ${OUT}
        rm *.nc
        ;;

    *) # Default
        echo "Ninguna opcion seleccionada"
        ;;
esac
