#!/bin/bash

# -----------------------------------------------------------------------------
# Webster Yang Index.
# JJA of u and v wind from observed (ERA-Interim), assimilated and ensemble 
# model (MPI ECHAM).
#
# This scripts works with:
# - ERA Interim: /pool/data/ICDC/reanalyses/era_interim/DATA/erai_sfc_6hourly_data/uwind/
# - MPI ECHAM: /work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_uv_1980_2017.nc
# - MPI ECHAM MR30: /work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/echam_uwind_mm_hcassimbt_r1-30_r1i1p1-MR_1980_2017.nc
# 
# IMPORTANT: remember to activate conda environment for ncks:
# - conda activate py39
# This is done to avoid 5-dimension problem with cdo for ensemble data
# Check: https://code.mpimet.mpg.de/boards/1/topics/7434
#
# Author: Dante T. Castro Garro
# -----------------------------------------------------------------------------

# General parameters
RUTA="../../../data/wind/"

# Cases
case $1 in
    erai) # Observed
        DATA="/pool/data/ICDC/reanalyses/era_interim/DATA/erai_sfc_6hourly_data/uwind/"

        for mem in {1981..2016} 
        do
            echo $mem
            cdo -yearmean -monmean -daymean -selseason,JJA ${DATA}ERAIN_SFC00_6H_10U_165_${mem}.nc ${RUTA}pre_erain_sfc_${mem}.nc
        done

        cdo mergetime ${RUTA}pre_erain_sfc_*.nc ${RUTA}erain_sfc_uwind_1981-2016.nc
        rm ${RUTA}pre*.nc
        ;;

    era5) # ERA5 observed
        DATA=${RUTA}era5_uwind_1981-2016_lev-200-850.nc
        OUT=${RUTA}era5_uwind_1981-2016_lev-200-850_trimon.nc
        out1=${RUTA}era5_uwind_1981-2016-mon_lev-200.nc
        out2=${RUTA}era5_uwind_1981-2016-mon_lev-850.nc
        
        # cdo --reduce_dim -fldmean -yearmean -selseason,DJF ${DATA} temp1.nc
        # cdo --reduce_dim -fldmean -yearmean -selseason,JFM ${DATA} temp2.nc
        # cdo --reduce_dim -fldmean -yearmean -selseason,FMA ${DATA} temp3.nc
        # cdo --reduce_dim -fldmean -yearmean -selseason,MAM ${DATA} temp4.nc
        # cdo --reduce_dim -fldmean -yearmean -selseason,AMJ ${DATA} temp5.nc
        # cdo --reduce_dim -fldmean -yearmean -selseason,MJJ ${DATA} temp6.nc
        # cdo --reduce_dim -fldmean -yearmean -selseason,JJA ${DATA} temp7.nc
        
        # cdo mergetime temp*.nc ${OUT}
        # rm *.nc
        
        # cdo -chname,u,uwind ${DATA} temp.nc
        # ncks -O -d level,1 -F temp.nc temp_1.nc
        # ncks -O -d level,2 -F temp.nc temp_2.nc
        cdo --reduce_dim -sellevel,200 -chname,u,uwind ${DATA} ${out1}
        cdo --reduce_dim -sellevel,850 -chname,u,uwind ${DATA} ${out2}
        # rm temp*
        ;;

    asm) # Assimilation
        DATA="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_uv_1980_2017.nc"
        OUT=${RUTA}echam6-asm_uwind_wyi_tri_1981-2016.nc
        # OUT=${RUTA}echam6-asm_uwind_wyi_JJA_1981-2016.nc
        # cdo --reduce_dim -fldmean -yearmean -monmean -sellonlatbox,40,100,0,20 -selseason,JJA -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} ${OUT}

        # cdo --reduce_dim -fldmean -yearmean -selseason,DJF ${DATA} temp1.nc
        cdo --reduce_dim -fldmean -yearmean -sellonlatbox,40,100,0,20 -selseason,JFM -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} temp2.nc
        cdo --reduce_dim -fldmean -yearmean -sellonlatbox,40,100,0,20 -selseason,FMA -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} temp3.nc
        cdo --reduce_dim -fldmean -yearmean -sellonlatbox,40,100,0,20 -selseason,MAM -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} temp4.nc
        cdo --reduce_dim -fldmean -yearmean -sellonlatbox,40,100,0,20 -selseason,AMJ -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} temp5.nc
        cdo --reduce_dim -fldmean -yearmean -sellonlatbox,40,100,0,20 -selseason,MJJ -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} temp6.nc
        cdo --reduce_dim -fldmean -yearmean -sellonlatbox,40,100,0,20 -selseason,JJA -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${DATA} temp7.nc

        cdo mergetime temp*.nc ${OUT}
        rm *.nc
        ;;

    asmmon)
        data="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_assimilation/dante/asOEffESIP_r1i1p1-MR_echam6_echam_uv_1980_2017.nc"
        out1=${RUTA}echam6-asm_uwind_1981-2016-mon_lev-200.nc
        out2=${RUTA}echam6-asm_uwind_1981-2016-mon_lev-850.nc
        
        cdo --reduce_dim -remapbil,r180x90 -monmean -selyear,1981/2016 -chname,var131,uwind -selname,var131 ${data} temp.nc
        ncks -O -d plev,1 -F temp.nc ${out1}
        ncks -O -d plev,2 -F temp.nc ${out2}
        # ncwa -a plev temp_1.nc ${out1}
        # ncwa -a plev temp_2.nc ${out2}
        rm temp*
        ;;

    ens) # Ensemble
        DATA="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/echam_uwind_mm_hcassimbt_r1-30_r1i1p1-MR_1980_2017.nc"
        OUT1=${RUTA}echam6-mem_uwind_1981-2016-mon_lev-850_crop.nc
        OUT2=${RUTA}echam6-mem_uwind_1981-2016-mon_lev-200_crop.nc
        
        ncks -O -d lev,1 -F ${DATA} temp_lev1.nc
        ncks -O -d lev,2 -F ${DATA} temp_lev2.nc
        ncwa -a lev temp_lev1.nc temp_1.nc
        ncwa -a lev temp_lev2.nc temp_2.nc
        # cdo --reduce_dim -fldmean -yearmean -monmean -sellonlatbox,40,100,0,20, -selseason,JJA -selyear,1981/2016 -chname,var131,uwind -selname,var131 temp_1.nc ${OUT1}
        # cdo --reduce_dim -fldmean -yearmean -monmean -sellonlatbox,40,100,0,20, -selseason,JJA -selyear,1981/2016 -chname,var131,uwind -selname,var131 temp_2.nc ${OUT2}
        cdo --reduce_dim -sellonlatbox,40,100,0,20 -remapbil,r180x90 -monmean -selyear,1981/2016 -chname,var131,uwind -selname,var131 temp_1.nc ${OUT1}
        cdo --reduce_dim -sellonlatbox,40,100,0,20 -remapbil,r180x90 -monmean -selyear,1981/2016 -chname,var131,uwind -selname,var131 temp_2.nc ${OUT2}
        rm temp*
        ;;

    *) # Default
        echo "Ninguna opcion seleccionada"
        ;;
esac
