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

logger = logging.getLogger("SDC-climatologies")
logger.setLevel(logging.INFO)
logging.info("Starting")

def get_WOA_period(num):
    """
    Return the name of the period from its number
    1 = January
    ...
    12 = December
    13 = winter
    ...
    16 = fall)
    0 = annual
    """
    if num == 0:
        WOAperiod = "annual"
    elif num <= 12:
        WOAperiod = calendar.month_name[num]
    elif num == 13:
        WOAperiod = "winter"
    elif num == 14:
        WOAperiod = "sprint"
    elif num == 15:
        WOAperiod = "summer"
    elif num == 16:
        WOAperiod = "fall"
    else:
        logger.error("Undefined period number, should be between 0 and 16")
        WOAperiod = None
    return WOAperiod

def get_WOA_url(varname, period):
    """
    Create the OPEnDAP URL based on the variable name and the period considered

    `varname` is either temperature or salinity
    `period` is an integer defined as follows:
    from 1 to 12 for months
    from 13 to 16 from seasons (winter, spring, summer, fall)
    0 for annual

    Examples:
    * annual temperature
    https://data.nodc.noaa.gov/thredds/dodsC/ncei/woa/temperature/decav/0.25/woa18_decav_t01_04.nc
    * March temperature
    https://data.nodc.noaa.gov/thredds/dodsC/ncei/woa/temperature/decav/0.25/woa18_decav_t03_04.nc
    * Winter temperature
    https://data.nodc.noaa.gov/thredds/dodsC/ncei/woa/temperature/decav/0.25/woa18_decav_t13_04.nc
    """
    baseurl = "https://data.nodc.noaa.gov/thredds/dodsC/ncei/woa/"
    vname = varname.lower()[0]
    woaURL = "".join((baseurl, varname, "/decav/0.25/woa18_decav_", vname, str(period).zfill(2), "_04.nc"))
    return woaURL


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
    return lonWOA, latWOA, depthWOA, timeWOA, timeWOAunits

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

def read_climato_sdc(filename, varname):
    """
    Read the climatology from the netCDF file `filename`.
    """
    if varname.lower() == "temperature":
        std_name = "sea_water_temperature"
    elif varname.lower() == "salinity":
        std_name = "sea_water_salinity"

    with netCDF4.Dataset(filename, "r") as nc:
        lon = nc.variables["lon"][:]
        lat = nc.variables["lat"][:]
        depth = nc.variables["depth"][:]
        ttime = nc.variables["time"][:]
        timeunits = nc.variables["time"].units
        dates = netCDF4.num2date(ttime, timeunits)
        try:
            field = nc.get_variables_by_attributes(standard_name=std_name)[0][:]
        except :
            field = nc.get_variables_by_attributes(long_name=varname.capitalize())[0][:]

    return lon, lat, depth, dates, field

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
        vmin = 32.
        vmax = 36.
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
    else:
        s2 = ""
    if date is not None:
        s3 = date.strftime("%Y-%m-%d")
    else:
        s3 = ""

    return " ".join((s1, s2, s3))

def make_2Dplot(m, lon, lat, field, varname="temperature",
                product=None, depth=None, date=None, figname=None,
                vmin=None, vmax=None, figtitle=None):
    """
    Create a pseudo-color plot of the variable stored in the array `field`
    with the coordinates `lon` and `lat`, using the projection `m`.

    The figure is exported if figname is defined
    """

    if vmin is None and vmax is None:
        cb_label, vmin, vmax, cmap = get_plot_params(varname)
    else:
        cb_label, _, _, cmap = get_plot_params(varname)

    if figtitle is None:
        figtitle = get_fig_title(varname.capitalize(), depth, date, product)

    llon, llat = np.meshgrid(lon, lat)

    # plt.figure(figsize=(6, 6))
    m.pcolormesh(llon, llat, field, latlon=True,
                 cmap=cmap, vmin=vmin, vmax=vmax)
    m.drawmeridians(np.arange(np.round(lon.min()), lon.max(), 3.), labels=[0,1,0,1],
                    linewidth=0.5, zorder=2, fontsize=12)
    m.drawparallels(np.arange(np.round(lat.min()), lat.max(), 2.), labels=[1,0,1,0],
                    linewidth=0.5, zorder=2, fontsize=12)
    m.drawcoastlines(linewidth=0.25, zorder=5)
    m.fillcontinents(color=".75", zorder=3)
    cb = plt.colorbar(extend="both")
    cb.set_label(cb_label, rotation=0, ha="left", fontsize=14)
    plt.title(figtitle)
    if figname is not None:
        plt.savefig(figname, dpi=300, bbox_inches="tight")
    # plt.show()
    #plt.close()


def make_2D_subplot(m, lon, lat, field, varname="temperature",
                product=None, depth=None, period=None, figname=None,
                vmin=None, vmax=None, nsubplot=1):
    """
    Create a pseudo-color plot of the variable stored in the array `field`
    with the coordinates `lon` and `lat`, using the projection `m`.

    The figure is exported if figname is defined
    """

    if vmin is None and vmax is None:
        cb_label, vmin, vmax, cmap = get_plot_params(varname)
    else:
        cb_label, _, _, cmap = get_plot_params(varname)

    llon, llat = np.meshgrid(lon, lat)

    m.pcolormesh(llon, llat, field, latlon=True,
                 cmap=cmap, vmin=vmin, vmax=vmax)

    if (nsubplot % 3) == 1:
        m.drawparallels(np.arange(np.round(lat.min()), lat.max(), 3.), labels=[1,0,1,0],
                        linewidth=0.5, zorder=2, fontsize=12)
    else:
        m.drawparallels(np.arange(np.round(lat.min()), lat.max(), 3.),
                        linewidth=0.5, zorder=2, fontsize=12)


    if nsubplot >= 10:
        m.drawmeridians(np.arange(np.round(lon.min()), lon.max(), 4.), labels=[0,1,0,1],
                        linewidth=0.5, zorder=2, fontsize=12)
    else:
        m.drawmeridians(np.arange(np.round(lon.min()), lon.max(), 4.),
                        linewidth=0.5, zorder=2, fontsize=12)

    m.drawcoastlines(linewidth=0.25, zorder=5)
    m.fillcontinents(color=".75", zorder=3)
    #cb = plt.colorbar(extend="both")
    #cb.set_label(cb_label, rotation=0, ha="left", fontsize=14)
    plt.title(period)


def get_season_date(dd):
    """
    Get the season from a datetime object
    """
    month = dd.month
    if month == 11:
        season = "fall"
    elif month == 2:
        season = "winter"
    elif month == 5:
        season = "spring"
    elif month == 8:
        season = "summer"
    else:
        logger.error("Month for decadal product should be either 2, 5, 8 or 11")
    return season
