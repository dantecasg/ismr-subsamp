#!/bin/bash

# -----------------------------------------------------------------------------
# Spatial precipitation
# Period: 1981 - 2016 
# Season: JJAS
# Region: 20°E - 120°E | 20°S - 50°N
# Source of data:
# - Observed: GPCP
# - Assimilation: MPI-ECHAM6-MR
# - Ensemble: MPI-ESM6-MR30
#
# Date: 2021-09-11
# Author: Dante T. Castro Garro
# -----------------------------------------------------------------------------

# General parameters
ruta=../../../data
area="20,120,-20,50"

# Cases
case $1 in
    obscli) # Observed mean and standard deviation for JJAS
        data=${ruta}/GPCP/GPCP__V2_3__PRECIP__2.5x2.5_sel.nc
        out=${ruta}/prec/gpcp_pre_cli-JJAS.nc

        cdo -chname,precip,mean -timmean -yearmean -selseason,JJAS -selyear,1981/2010 ${data} GPCP_JJAS-mean.nc
        cdo -chname,precip,std  -timstd  -yearmean -selseason,JJAS -selyear,1981/2010 ${data} GPCP_JJAS-std.nc
        cdo --reduce_dim -merge GPCP_JJAS-mean.nc GPCP_JJAS-std.nc ${out}
        rm GPCP_JJAS-mean.nc GPCP_JJAS-std.nc
        ;;

    asmcli) # Assimilated mean and standard deviation for JJAS
        data=${ruta}/MR30/asOEffESIP_r1i1p1-MR_echam6_echam_precip_1980_2017.nc
        out=${ruta}/prec/mpi-echam-asm_pre_cli-JJAS.nc

        cdo -chname,precip,mean -timmean -yearmean -selyear,1981/2010 ${data} mr30_ass_JJAS-mean.nc
        cdo -chname,precip,std  -timstd  -yearmean -selyear,1981/2010 ${data} mr30_ass_JJAS-std.nc
        cdo --reduce_dim -remapbil,r180x90 -merge mr30_ass_JJAS-mean.nc mr30_ass_JJAS-std.nc ${out}
        rm mr30_ass_JJAS-mean.nc mr30_ass_JJAS-std.nc
        ;;

    sptjjas)
        data=${ruta}/GPCP/GPCP__V2_3__PRECIP__2.5x2.5_sel.nc
        out=${ruta}/prec/gpcp_pre_1981-2016-JJAS.nc

        cdo -yearmean -monmean -selseason,JJAS -selyear,1981/2016 -selname,precip ${data} ${out}
        ;;

    sptjjasasm)
        data=${ruta}/MR30/asOEffESIP_r1i1p1-MR_echam6_echam_precip_1980_2017.nc
        out=${ruta}/prec/mpi-echam-asm_pre_1981-2016-JJAS_2p5.nc

        cdo -remapbil,r180x90 -yearmean -monmean -selseason,JJAS -selyear,1981/2016 -selname,precip ${data} ${out}
        ;;

    ens) # Ensemble 1981-2016 JJAS spatial data
        data=/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/echam_tprec_mm_hcassimbt_r1-30_r1i1p1-MR_1980_2017.nc
        rmp=${ruta}/GPCP/GPCP__V2_3__PRECIP__2.5x2.5_sel.nc
        out=${ruta}/prec/mpi-echam-hnd_pre_1981-2016-JJAS_2p5.nc

        cdo -remapbil,r180x90 -chname,tprec,pre -yearmean -selseason,JJAS -selyear,1981/2016 ${data} temp.nc
        cdo -remapbil,${rmp} temp.nc ${out}

        rm temp.nc
        ;;

    *) # Default
        echo "Nothing was selected"
        ;;
esac

