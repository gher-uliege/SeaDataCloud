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

include("northsea_metadata.jl")
include("northsea_domain.jl")
include("northsea_plotting.jl")

doplot = false
varname = "Temperature"
datadir = "/data/SeaDataCloud/NorthSea/"
obsfile = joinpath(datadir, "NorthSea_obs_$(varname)_sdn_wod_merged.nc")
filename = "./NorthSea/output/Water_body_$(replace(varname," "=>"_"))_NorthSea.4Danl_annual_merged_coeffderiv.nc"
xmlfilename = "Water_body_$(replace(varname," "=>"_")).4Danl_merged_annual.xml"

# Full period
yearlist = [1955:2014];

# Annual
monthlist = [[1,2,3,4,5,6,7,8,9,10,11,12]];

TS = DIVAnd.TimeSelectorYearListMonthList(yearlist,monthlist);
@show TS;

@info("Reading data from the observation file")
@time obsval,obslon, obslat, obsdepth, obstime,obsid = DIVAnd.loadobs(Float64,obsfile,varname)
@info("Total number of data points: $(length(obsval))");

sel = obslon .> 180;
obslon[sel] = obslon[sel] .- 360.;

if doplot
    figure("NorthSea-Data")
    ax = subplot(1,1,1)
    plot(obslon, obslat, "ko", markersize=.1)
    plot(obslon[sel3], obslat[sel3], "ro", markersize=.1)
    aspect_ratio = 1/cos(mean(latr) * pi/180)
    ax.tick_params.("both",labelsize=6)
    gca().set_aspect(aspect_ratio)
end

checkobs((obslon,obslat,obsdepth,obstime),obsval,obsid)

if doplot
    PyPlot.hist(obsval, 0:1:40);
end

bathname = joinpath(datadir, "gebco_30sec_16.nc")
if !isfile(bathname)
    download("https://dox.ulg.ac.be/index.php/s/U0pqyXhcQrXjEUX/download",bathname)
else
    @info("Bathymetry file already downloaded")
end

@time bx,by,b = load_bath(bathname,true,lonr,latr);

mask = falses(size(b,1),size(b,2),length(depthr))
for k = 1:length(depthr)
    for j = 1:size(b,2)
        for i = 1:size(b,1)
            mask[i,j,k] = b[i,j] >= depthr[k]
        end
    end
end
@show size(mask)

"""
weightfile = "./northsea_weights.jld"
w = load(weightfile);
rdiag = w["rdiag"];
@info length(rdiag);

#@time rdiag=1.0./DIVAnd.weight_RtimesOne((obslon,obslat),(0.03,0.03));
#@show maximum(rdiag),mean(rdiag)
"""

sz = (length(lonr),length(latr),length(depthr));
lenx = fill(100_000.,sz)   # 100 km
leny = fill(100_000.,sz)   # 100 km
lenz = [min(max(30.,depthr[k]/150),300.) for i = 1:sz[1], j = 1:sz[2], k = 1:sz[3]]

len = (lenx, leny, lenz);
epsilon2 = 0.1;
# epsilon2 = epsilon2 * rdiag;

    ncglobalattrib,ncvarattrib = SDNMetadata(metadataT,filename,varname,lonr,latr)

if isfile(filename)
    rm(filename) # delete the previous analysis
    @info "Removing file $filename"
end

figdir = "NorthSea/figures/"
if ~(isdir(figdir))
    mkpath(figdir)
else
    @info("Figure directory already exists")
end


@time dbinfo = diva3d((lonr,latr,depthr,TS),
    (obslon,obslat,obsdepth,obstime), obsval,
    len, epsilon2,
    filename,varname,
    bathname=bathname,
    mask = mask,
    fitcorrlen = false,
    ncvarattrib = ncvarattrib,
    ncglobalattrib = ncglobalattrib,
    MEMTOFIT=100,
    solver=:direct,
    surfextend = true,
    coeff_derivative2 = [0.0, 0.0, 1e-9],
    minfield = -1.0
    );

obsidlist = copy(obsid);
for i in 1:length(obsidlist)
    if occursin("wod_", obsidlist[i])
        obsidlist[i] = replace(obsidlist[i], "wod_"=>"1977-wod_")
    end
end;

DIVAnd.saveobs(filename,(obslon,obslat,obsdepth,obstime),obsidlist);

project = "SeaDataCloud";

cdilist = "CDI-list-export.zip"

if !isfile(cdilist)
   download("http://emodnet-chemistry.maris2.nl/download/export.zip",cdilist)
end

ignore_errors = true

# generate a XML file for Sextant catalog
divadoxml(filename,varname,project,cdilist,xmlfilename,
          ignore_errors = ignore_errors)
