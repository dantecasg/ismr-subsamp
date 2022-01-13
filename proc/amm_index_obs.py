"""
This script calculates the Atlantic Meriodional Mode from SST and wind data sets.
Some references:
- Description of the method:
https://climatedataguide.ucar.edu/climate-data/meridional-modes-and-their-indices
https://psl.noaa.gov/data/timeseries/monthly/AMM/
http://research.jisao.washington.edu/data/cti/
https://journals.ametsoc.org/view/journals/clim/17/21/jcli4953.1.xml
https://www.aos.wisc.edu/~dvimont/MModes/AMM.html
- Packages:
https://github.com/nicrie/xmca
https://docs.juliahub.com/Diagonalizations/vx8JA/0.1.11/mca/#MCA-1

It basically relies on MCA, but a pre-procesing of the data is needed.

# Data
- ERSST (instead of NOAAoist or HadISST) and NCEP (instead of ERA5).
- Data dimension: [time, lat, lon]

Author: Dante T. Castro Garro
Date: 2021-11-29
"""

# --------------------------------------------------------------------------- #
# PACKAGES
# --------------------------------------------------------------------------- #

from xmca.xarray import xMCA
from sklearn.linear_model import LinearRegression
import xarray as xr
import numpy as np
import pandas as pd

# --------------------------------------------------------------------------- #
# FUNCTIONS
# --------------------------------------------------------------------------- #

def medmov2(x):
    n = np.size(x)
    res = np.full([n], np.nan)
    res[1:n-1] = (x[0:n-2] + x[1:n-1] + x[2:n]) / 3
    return res

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

# --------------------------------------------------------------------------- #
# PROCESS
# --------------------------------------------------------------------------- #

datapath = "../data/"

# --------------------------------------------------------------------------- #
# Data

# Load data
data_sst = xr.load_dataset(datapath+"sst/noaa-ersstv5_sst_1854-2021-mon_2p5.nc")
data_uwd = xr.load_dataset(datapath+"wind/ncep-ncar_uwind_1948-2021-mon_10m.nc")
data_vwd = xr.load_dataset(datapath+"wind/ncep-ncar_vwind_1948-2021-mon_10m.nc")

# Re-ordering coordinates
data_sst = data_sst.reindex(lat=list(reversed(data_sst.lat)))
data_uwd = data_uwd.reindex(lat=list(reversed(data_uwd.lat)))
data_vwd = data_vwd.reindex(lat=list(reversed(data_vwd.lat)))

data_sst = data_sst.assign_coords(lon=(((data_sst.lon + 180) % 360) - 180))
data_uwd = data_uwd.assign_coords(lon=(((data_uwd.lon + 180) % 360) - 180))
data_vwd = data_vwd.assign_coords(lon=(((data_vwd.lon + 180) % 360) - 180))

data_sst = data_sst.reindex(lon=np.sort(data_sst.lon))
data_uwd = data_uwd.reindex(lon=np.sort(data_uwd.lon))
data_vwd = data_vwd.reindex(lon=np.sort(data_vwd.lon))

# Selecting time period: 1981 - 2016 (period of the study)
# 1950 - 2005 was the original time proposed by literature
data_sst = data_sst.sel(time=slice("1980-12-01", "2017-01-31"))
data_uwd = data_uwd.sel(time=slice("1980-12-01", "2017-01-31"))
data_vwd = data_vwd.sel(time=slice("1980-12-01", "2017-01-31"))

# Selecting region
lon = data_sst.lon.values
lat = data_sst.lat.values
lon_sel = (lon >= -75) & (lon <= 15)
lat_sel = (lat >= -21) & (lat <= 32)

sst = data_sst["sst"][:,lat_sel,lon_sel]
uwd = data_uwd["uwnd"][:,lat_sel,lon_sel]
vwd = data_vwd["vwnd"][:,lat_sel,lon_sel]

# Cold Tongue Index region
cti_lon_sel = (lon >= -180) & (lon <= -90)
cti_lat_sel = (lat >= -6)  & (lat <= 6)
cti = data_sst["sst"][:,cti_lat_sel,cti_lon_sel]

# --------------------------------------------------------------------------- #
# Pre-processing

# Dimension size
nt, ny, nx = np.shape(sst)

# Smoothing area (no for the moment)
# for i in range(nt):
    # for j in range(ny):

# Climatology
sst_cli = np.zeros((12,ny,nx))
uwd_cli = np.zeros((12,ny,nx))
vwd_cli = np.zeros((12,ny,nx))
cti_cli = np.zeros((12,np.shape(cti)[1],np.shape(cti)[2]))
n_year = int(nt / 12)
cli_off = 1

for t in range(12):
    tsel = np.linspace(0,n_year-1, n_year) * 12 + cli_off + t
    tsel = tsel.astype(int)
    sst_cli[t,:,:] = np.mean(sst[tsel,:,:], axis=0)
    uwd_cli[t,:,:] = np.mean(uwd[tsel,:,:], axis=0)
    vwd_cli[t,:,:] = np.mean(vwd[tsel,:,:], axis=0)
    cti_cli[t,:,:] = np.mean(cti[tsel,:,:], axis=0)

# Anomalies
sst_ano = sst.copy()
uwd_ano = uwd.copy()
vwd_ano = vwd.copy()
cti_ano = cti.copy()
ti = 11 # Initial month

for t in range(nt):
    ts = ti % 12 # selecting a specific climatology month
    sst_ano[t,:,:] = sst[t,:,:] - sst_cli[ts,:,:]
    uwd_ano[t,:,:] = uwd[t,:,:] - uwd_cli[ts,:,:]
    vwd_ano[t,:,:] = vwd[t,:,:] - vwd_cli[ts,:,:]
    cti_ano[t,:,:] = cti[t,:,:] - cti_cli[ts,:,:]
    ti = ti + 1

# Detrending grids
sst_dtr = detrend(sst_ano)
uwd_dtr = detrend(uwd_ano)
vwd_dtr = detrend(vwd_ano)

# 3 Month running mean
sst_mmv = sst_dtr.copy()
uwd_mmv = uwd_dtr.copy()
vwd_mmv = vwd_dtr.copy()

for i in range(ny):
    for j in range(nx):
        sst_mmv[:,i,j] = medmov2(sst_dtr[:,i,j].values)
        uwd_mmv[:,i,j] = medmov2(uwd_dtr[:,i,j].values)
        vwd_mmv[:,i,j] = medmov2(vwd_dtr[:,i,j].values)

# Taking out the Cold Tongue Index
cti_ts = np.mean(cti_ano, axis=(1,2)).values.reshape(-1,1)
sst_cti = sst_mmv.copy()
for i in range(ny):
    for j in range(nx):
        if np.isnan(sst_mmv[1,i,j]):
            continue
        lm = LinearRegression();
        lm.fit(cti_ts[1:nt-1], sst_mmv[1:nt-1,i,j].values.reshape(-1,1));
        prd = lm.predict(cti_ts).reshape(nt)
        sst_cti[:,i,j] = sst_mmv[:,i,j] - prd

# Final dataset
sst_fin = sst_cti[2:nt-2,:,:]
uwd_fin = uwd_mmv[2:nt-2,:,:]
vwd_fin = vwd_mmv[2:nt-2,:,:]

# Append winds
wnd_dat = np.concatenate((uwd_fin, vwd_fin), axis=1)
lat_new = sst_fin["lat"].values
lat_ext = np.linspace(np.min(lat_new), np.max(lat_new), np.size(lat_new)*2)
wnd_fin = xr.DataArray(
    data = wnd_dat,
    dims = ["time", "lat", "lon"],
    coords = dict(
        lon = sst_fin["lon"].values,
        lat = lat_ext,
        time = sst_fin["time"].values
    )
)

# --------------------------------------------------------------------------- #
# Calculate MCA

mca = xMCA(sst_fin, wnd_fin)
mca.solve(complexify = False)
eig = mca.singular_values()
pcs = mca.pcs()
eof = mca.eofs()

sst_mca = pcs["left"][:,0].values
sst_mca_nor = (sst_mca - np.mean(sst_mca)) / np.std(sst_mca)

# Exporting data
df = pd.DataFrame({
    "time" : sst_fin["time"].values,
    "amm"  : sst_mca_nor,
})
df.to_csv(r'../data/index/amm-obs_1981-2016-mon.csv', index = False)

