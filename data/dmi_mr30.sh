# -----------------------------------------------------------------------------
# Calculating DMI for each one of the members.
# Author: Dante T. Castro Garro
# Date: 2021-08-15
# -----------------------------------------------------------------------------

ARCH="/work/uo1075/u241265/post_defense/monsson_subsampling/MR30_hindcast/dante/hcassimbt_r1-30_i1p1-MR_mpiom_data_2d_sst_1980_2016.nc"
OUT="../../../data/DMI/dmi_mr30_JJA.nc"

cdo --reduce_dim -chname,sst,west -fldmean -yearmean -selseason,JJA -selyear,1981/2016 -sellonlatbox,50,70,-10,10 ${ARCH} dmi_west.nc
cdo --reduce_dim -chname,sst,east -fldmean -yearmean -selseason,JJA -selyear,1981/2016 -sellonlatbox,90,110,-10,0 ${ARCH} dmi_east.nc
cdo -merge dmi_west.nc dmi_east.nc ${OUT}

rm dmi_west.nc dmi_east.nc
