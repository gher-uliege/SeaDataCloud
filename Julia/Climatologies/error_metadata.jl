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

depthr = Float64.([0.,5., 10., 15., 20., 25., 30.]);

varname = "Salinity"
yearlist = [1955:2014];
monthlist = [[1,2,3,4,5,6,7,8,9,10,11,12]];

TS = DIVAnd.TimeSelectorYearListMonthList(yearlist,monthlist);
@show TS;

varname = "Salinity"
datadir = "/data/"
mkpath(datadir)
obsfile = joinpath(datadir, "NorthSea_obs_salinity.nc")

if !isfile(obsfile)
    @info("Downloading observation file")
    download("https://dox.ulg.ac.be/index.php/s/lCXjtpwHnR1ZUEw/download", obsfile)
else
    @info("Observation file already there");
end

@info("Reading data from the observation file")
@time obsval,obslon, obslat, obsdepth, obstime,obsid = DIVAnd.loadobs(Float64,obsfile,varname)
@info("Total number of data points: $(length(obsval))");

sel = obslon .> 180;
obslon[sel] = obslon[sel] .- 360.;

checkobs((obslon,obslat,obsdepth,obstime),obsval,obsid)

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

filename = "Water_body_$(replace(varname," "=>"_"))_NorthSea.4Danl_test.nc"

metadata = OrderedDict(
    # Name of the project (SeaDataCloud, SeaDataNet, EMODNET-chemistry, ...)
    "project" => "SeaDataCloud",

    # URN code for the institution EDMO registry,
    # e.g. SDN:EDMO::1579
    "institution_urn" => "SDN:EDMO::3330",

    # Production group
    "production" => "DIVA group",

    # Name and emails from authors
    "Author_e-mail" => ["Serge Scory <sscory@naturalsciences.be>"],

    # Source of the observation
    "source" => "Observational data from SeaDataNet",

    # Additional comment
    "comment" => "Only one dataset considered (SeaDataCloud V1 discrete data)",

    # SeaDataNet Vocabulary P35 URN
    # http://seadatanet.maris2.nl/v_bodc_vocab_v2/search.asp?lib=p35
    # example: SDN:P35::WATERTEMP
    "parameter_keyword_urn" => "SDN:P35::EPC00001",

    # List of SeaDataNet Parameter Discovery Vocabulary P02 URNs
    # http://seadatanet.maris2.nl/v_bodc_vocab_v2/search.asp?lib=p02
    # example: ["SDN:P02::TEMP"]
    "search_keywords_urn" => ["SDN:P02::PSAL"],

    # List of SeaDataNet Vocabulary C19 area URNs
    # SeaVoX salt and fresh water body gazetteer (C19)
    # http://seadatanet.maris2.nl/v_bodc_vocab_v2/search.asp?lib=C19
    # example: ["SDN:C19::3_1"]
    "area_keywords_urn" => ["SDN:C19::1_2", "SDN:C19::1_7"],

    "product_version" => "1.0",

    "product_code" => "something-to-decide",

    # bathymetry source acknowledgement
    # see, e.g.
    # * EMODnet Bathymetry Consortium (2016): EMODnet Digital Bathymetry (DTM).
    # http://doi.org/10.12770/c7b53704-999d-4721-b1a3-04ec60c87238
    #
    # taken from
    # http://www.emodnet-bathymetry.eu/data-products/acknowledgement-in-publications
    #
    # * The GEBCO Digital Atlas published by the British Oceanographic Data Centre on behalf of IOC and IHO, 2003
    #
    # taken from
    # https://www.bodc.ac.uk/projects/data_management/international/gebco/gebco_digital_atlas/copyright_and_attribution/

    "bathymetry_source" => "The GEBCO Digital Atlas published by the British Oceanographic Data Centre on behalf of IOC and IHO, 2003",

    # NetCDF CF standard name
    # http://cfconventions.org/Data/cf-standard-names/current/build/cf-standard-name-table.html
    # example "standard_name" = "sea_water_temperature",
    "netcdf_standard_name" => "sea_water_salinity",

    "netcdf_long_name" => "sea water salinity",

    "netcdf_units" => "1e-3",

    # Abstract for the product
    "abstract" => "...",

    # This option provides a place to acknowledge various types of support for the
    # project that produced the data
    "acknowledgement" => "...",

    "documentation" => "http://dx.doi.org/doi_of_doc",

    # Digital Object Identifier of the data product
    "doi" => "...");

ncglobalattrib,ncvarattrib = SDNMetadata(metadata,filename,varname,lonr,latr)

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
    ncvarattrib = ncvarattrib,
    ncglobalattrib = ncglobalattrib,
    MEMTOFIT=100,
    solver=:direct,
    surfextend = true
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

# File name based on the variable (but all spaces are replaced by underscores)
xmlfilename = "Water_body_$(replace(varname," "=>"_")).4Danl.xml"

# generate a XML file for Sextant catalog
divadoxml(filename,varname,project,cdilist,xmlfilename,
          ignore_errors = ignore_errors)
