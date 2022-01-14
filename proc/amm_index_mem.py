"""
This script calculates the AMM index for each one of the ensemble members from
the MPI-ESM. The way it is done is by projecting (don't know how but I guess
with a linear regression?) the first EOF AMM from the assimilated data since
there is not enough data for each ensemble to calculate the full time series of
AMM.

Author: Dante T. Castro Garro
Date: 2021-12-02
"""

# ============================================================================ #
# PACKAGES
# ============================================================================ #

from sklearn.linear_model import LinearRegression
import xarray as xr
import numpy as np
import pandas as pd

# ============================================================================ #
# FUNCTIONS
# ============================================================================ #

def detrend(x):
    nt, ny, nx = x.shape
    dtr = x.copy()
    tindex = np.linspace(0,nt-1,nt).reshape(-1,1)
    for i in range(ny):
        for j in range(nx):
            if np.isnan(x[0,i,j]):
                continue
            lm = LinearRegression();
            lm.fit(tindex, x[:,i,j].values.reshape(-1,1))
            trd = lm.predict(tindex).reshape(nt)
            dtr[:,i,j] = x[:,i,j] - trd
    return dtr

# ============================================================================ #
# PROCESS
# ============================================================================ #

# General parameters
datapath = "../data/"

# Load data
amm_eof = xr.load_dataset(datapath + "index/amm-asm_eof.nc")["left eofs"]
sst_fil = xr.load_dataset(datapath + "sst/mpi-om-ens_sst_1981-2016-mon.nc")

# Selection of area
sst_fil = sst_fil.assign_coords( lon = (((sst_fil.lon + 180) % 360) - 180) )
sst_fil = sst_fil.reindex(lon = np.sort(sst_fil.lon))
sst = sst_fil["sst"].sel(lon = slice(-75, 15), lat = slice(-21, 32)) - 273.15

# CTI data
cti = sst_fil["sst"].sel(lon = slice(-180, -90), lat = slice(-6, 6))

# Dimensions of the data
nt, ne, ny, nx = np.shape(sst)
cny, cnx = np.shape(cti)[2:4]
nm = 5 # only 5 months in the data

# Climatology
sst_cli = np.zeros((nm,ne,ny,nx)) 
cti_cli = np.zeros((nm,ne,cny,cnx)) 
n_year = int(nt / nm)
cli_off = 0

for t in range(nm):
    tsel = np.linspace(0, n_year-1, n_year) * nm + cli_off + t
    tsel = tsel.astype(int)
    sst_cli[t,:,:,:] = np.mean(sst[tsel,:,:,:], axis = 0)
    cti_cli[t,:,:,:] = np.mean(cti[tsel,:,:,:], axis = 0)

# Anomalies
sst_ano = sst.copy()
cti_ano = cti.copy()
ti = 0

for t in range(nt):
    ts = ti % nm
    sst_ano[t,:,:,:] = sst[t,:,:,:] - sst_cli[ts,:,:,:]
    cti_ano[t,:,:,:] = cti[t,:,:,:] - cti_cli[ts,:,:,:]
    ti = ti + 1

# Detrending
sst_dtr = sst_ano.copy()
for e in range(ne):
    sst_dtr[:,e,:,:] = detrend(sst_ano[:,e,:,:])

# Removing CTI effect
cti_ts = np.mean(cti_ano, axis = (2,3))
sst_cti = sst_dtr.copy()

for e in range(ne):
    cti_ts_sel = cti_ts[:,e].values.reshape(-1,1)
    sst_cti_sel = sst_cti[:,e,:,:]
    for i in range(ny):
        for j in range(nx):
            if np.isnan(sst_cti_sel[1,i,j]):
                continue
            lm = LinearRegression();
            lm.fit(cti_ts_sel, sst_cti_sel[:,i,j].values.reshape(-1,1));
            prd = lm.predict(cti_ts_sel).reshape(nt)
            sst_cti[:,e,i,j] = sst_cti_sel[:,i,j] - prd

# Projecting the AMM EOF and create the index time series?
# sst_prj = sst_cti.copy()
amm_ens = np.zeros((nt, ne))
for e in range(ne):
    for t in range(nt):
        # sst_prj[t,e,:,:] = sst_cti[t,e,:,:] * amm_eof.values
        sst_prj = sst_cti[t,e,:,:] * amm_eof
        amm_ens[t,e] = np.nansum(sst_prj) / np.nansum(amm_eof)

# Exporting data
df = pd.DataFrame({
    "time" : np.repeat(sst_fil["time"].values, ne),
    "ens"  : np.tile(range(30), nt),
    "amm"  : np.concatenate(amm_ens)
    # "amm"  : amm_ens.reshape(nt*ne,1)
})
df.to_csv(r'../data/index/amm-mem_1981-2016-mon.csv', index = False)
