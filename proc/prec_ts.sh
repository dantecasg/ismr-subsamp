#!/bin/bash

# -----------------------------------------------------------------------------
# Time series products for precipitation only for India land territory
# Period: 1981 - 2016 
# Season: Monthly climatology
# Region: India masking
# Source of data:
# - Observed: GPCP
# - Assimilation: MPI-ECHAM6-MR30
# - Ensemble: MPI-ECHAM6-MR30
#
# Date: 2021-09-13
# Author: Dante T. Castro Garro
# -----------------------------------------------------------------------------

# General parameters
ruta="../data"
area="20,120,-20,50"

# Selecting type of dataset
case $1 in
    obs) # Observed data
        data=${ruta}"/prec/GPCP__V2_3__PRECIP__2.5x2.5_sel.nc"
        mask=${ruta}"/mask/india_mask_GPCP.nc"
        outpre=${ruta}"/prec/gpcp-obs_pre"
        ;;

    asm) # Assimilated data
        data="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_precip_dm_1980_2017.nc"
        mask=${ruta}"/mask/india_mask_MR30.nc"
        outpre=${ruta}"/prec/mpi-echam-asm_pre"
        ;;

    ens)
        data="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/echam_tprec_mm_hcassimbt_r1-30_r1i1p1-MR_1980_2017.nc"
        mask=${ruta}"/mask/india_mask_MR30.nc"
        outpre=${ruta}"/prec/mpi-echam-ens_pre"
        ;;

    *) # Default
        echo "No dataset was selected"
        exit
        ;;
esac

# Selecting type of methodology
case $2 in
    month) # Monthly climatology as time series
        out=${outpre}"_cli-mon_ts.nc"
        cdo -ymonmean -selyear,1981/2010 ${data} "pre.nc"
        ;;

    jjas) # JJAS time series
        out=${outpre}"_1981-2016-JJAS_ts.nc"
        cdo -yearmean -selseason,JJAS -selyear,1981/2016 ${data} "pre.nc"
        ;;

    *) # Default
        echo "No method was selected"
        exit
        ;;
esac

cdo -merge pre.nc ${mask} "mask.nc"
cdo --reduce_dim -fldmean -setctomiss,0 -chname,pp,precip -selname,pp -expr,'pp=precip*mask_array' "mask.nc" ${out}
rm "pre.nc" "mask.nc"

