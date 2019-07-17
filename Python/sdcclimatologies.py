import os
import numpy as np
import netCDF4
import datetime
import logging
import cmocean
import calendar
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
import warnings
import matplotlib.cbook
warnings.filterwarnings("ignore",category=matplotlib.cbook.mplDeprecation)


def get_WOA_coords(datafile):
    """
    Extract the coordinates from a WOA netCDF file `datafile`

    `datafile` can be a OPEnDAP URL, for example
    "https://data.nodc.noaa.gov/thredds/dodsC/ncei/woa/temperature/A5B7/0.25/woa18_A5B7_t00_04.nc"

    Returns: 4 arrays containing the coordinates
    """
    with netCDF4.Dataset(datafile, "r") as nc:
        lonWOA = nc.variables["lon"][:]
        latWOA = nc.variables["lat"][:]
        depthWOA = nc.variables["depth"][:]
        timeWOA = nc.variables["time"][:]
        timeWOAunits =  nc.variables["time"].units
        dateWOA = netCDF4.num2date(timeWOA, timeWOAunits)
    return lonWOA, latWOA, depthWOA, dateWOA

def get_SDN_domain(datafile):
    """
    Extract the bounding box from a netCDF file containing a product
    Return lonmin, lonmax, latmin, latmax, depthmin, depthmax, datemin, datemax
    """
    with netCDF4.Dataset(datafile, "r") as nc:
        lonSDN = nc.variables["lon"][:]
        latSDN = nc.variables["lat"][:]
        depthSDN = nc.variables["depth"][:]
        timeSDNvalues = nc.variables["time"][:]
        timeSDNunits = nc.variables["time"].units
        dateSDN = netCDF4.num2date(timeSDNvalues, timeSDNunits)
    lonmin = lonSDN.min()
    latmin = latSDN.min()
    lonmax = lonSDN.max()
    latmax = latSDN.max()
    depthmin = depthSDN.min()
    depthmax = depthSDN.max()
    datemin = dateSDN.min()
    datemax = dateSDN.max()

    return lonmin, lonmax, latmin, latmax, depthmin, depthmax, datemin, datemax

def get_plot_params(varname):
    """
    Get the plotting parameters vmin, vmax and colobar label
    for the variable name
    """
    if varname.lower() == "temperature":
        cb_label = "T ($^{\circ}$C)"
        vmin = 7.5
        vmax = 17.5
        cmap = cmocean.cm.thermal
    elif varname.lower() == "salinity":
        cb_label = "S"
        vmin = 30.
        vmax = 40.
        cmap = cmocean.cm.haline
    else:
        logger.error("Unknown variable")
        cb_label = None
        vmin = None
        vmax = None
        cmap = None

    return cb_label, vmin, vmax, cmap

def get_fig_title(varname, depth, date, product=None):

    if product is not None:
        s1 = " ".join((product, varname.capitalize()))
    else:
        s1 = varname.capitalize()
    if depth is not None:
        s2 = "$-$ {} m".format(int(depth))
    if date is not None:
        s3 = date.strftime("%Y-%m-%d")
    else:
        s3 = ""

    return " ".join((s1, s2, s3))

def make_2Dplot(lon, lat, field, varname="temperature",
                product=None, depth=None, date=None, figname):
    """
    Create a pseudo-color plot of the variable stored in the array `field`
    with the coordinates `lon` and `lat`
    """

    cb_label, vmin, vmax, cmap = get_plot_params(varname)
    title = get_fig_title("Temperature", depth, date, product)

    llon, llat = np.meshgrid(lon, lat)

    plt.figure(figsize=(6, 6))
    m.pcolormesh(llon, llat, field, latlon=True,
                 cmap=cmap, vmin=vmin, vmax=vmax)
    m.drawmeridians(np.arange(np.round(lonmin), lonmax, 3.), labels=[0,1,0,1],
                    linewidth=0.5, zorder=2, fontsize=14)
    m.drawparallels(np.arange(np.round(latmin), latmax, 2.), labels=[1,0,1,0],
                    linewidth=0.5, zorder=2, fontsize=14)
    m.drawcoastlines(linewidth=0.25, zorder=5)
    m.fillcontinents(color=".75", zorder=3)
    cb = plt.colorbar(extend="both")
    cb.set_label(cb_label, rotation=0, ha="left", fontsize=14)
    plt.title(title)
    if figname is not None:
        plt.savefig(figname, dpi=300, bbox_inches="tight")
    # plt.show()
    plt.close()
