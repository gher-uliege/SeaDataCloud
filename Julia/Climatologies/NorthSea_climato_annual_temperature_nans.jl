using NCDatasets
using PhysOcean
using DataStructures
using DIVAnd
using PyPlot
using Dates
using Statistics
using Random
using JLD
using Printf

dx, dy = 0.25, 0.25 # Resolution to modify
lonr = -4.0:dx:10.
latr = 48.5:dy:62.
timerange = [Date(1900,1,1),Date(2017,12,31)]; # Used when extracting the obs

depthr = Float64.([0.,5., 10., 15., 20., 25., 30., 35, 40., 45, 50., 55, 60, 65., 70,
    75, 80, 85, 90, 95, 100, 125, 150, 175, 200, 225, 250,
    275, 300, 325, 350, 375, 400, 425, 450, 475, 500, 550, 600, 650, 700]);

depthr = Float64.([0.,5., 10., 15., 20., 25., 30., 35, 40., 45, 50.]);
varname = "Temperature"

yearlist = [1955:2014];
monthlist = [[1,2,3,4,5,6,7,8,9,10,11,12]];
TS = DIVAnd.TimeSelectorYearListMonthList(yearlist,monthlist);
@show TS;

datadir = "./data/"
if !isdir(datadir)
    mkpath(datadir)
end
obsfile = joinpath(datadir, "NorthSea_obs_temperature.nc")

if !isfile(obsfile)
    @info("Downloading observation file")
    download("https://dox.ulg.ac.be/index.php/s/AnxhGgHidu2wrZn/download", obsfile)
else
    @info("Observation file already there");
end

@info("Reading data from the observation file")
@time obsval,obslon, obslat, obsdepth, obstime, obsid = DIVAnd.loadobs(Float64,obsfile,varname)
@info("Total number of data points: $(length(obsval))");

sel = obslon .> 180;
obslon[sel] = obslon[sel] .- 360.;

bathname3 = joinpath(datadir, "gebco_30sec_16.nc")
if !isfile(bathname3)
    download("https://dox.ulg.ac.be/index.php/s/U0pqyXhcQrXjEUX/download",bathname3)
else
    @info("Bathymetry file already downloaded")
end

@time bx3,by3,b3 = load_bath(bathname3,true,lonr,latr);

mask3 = falses(size(b3,1),size(b3,2),length(depthr))
for k = 1:length(depthr)
    for j = 1:size(b3,2)
        for i = 1:size(b3,1)
            mask3[i,j,k] = b3[i,j] >= depthr[k]
        end
    end
end
@show size(mask3)

sz = (length(lonr),length(latr),length(depthr));
lenx = fill(100_000.,sz)   # 100 km
leny = fill(100_000.,sz)   # 100 km
lenz = [min(max(30.,depthr[k]/150),300.) for i = 1:sz[1], j = 1:sz[2], k = 1:sz[3]]

len = (lenx, leny, lenz);
epsilon2 = 0.1;
# epsilon2 = epsilon2 * rdiag;

filename = "Water_body_$(replace(varname," "=>"_"))_NorthSea.4Danl_annual_temperature_testnans.nc"

if isfile(filename)
    rm(filename) # delete the previous analysis
    @info "Removing file $filename"
end

@time dbinfo = diva3d((lonr,latr,depthr,TS),
    (obslon,obslat,obsdepth,obstime), obsval,
    len, epsilon2,
    filename,varname,
    bathname=bathname3,
    mask = mask3,
    fitcorrlen = false,
    niter_e = 2,
    MEMTOFIT=100,
    solver=:direct,
    surfextend = true
    );

nnans = sum(isnan.(dbinfo[:residuals]));
@info("Number of nans: $(nnans)")
