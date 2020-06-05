using NCDatasets
using PhysOcean
using DataStructures
using DIVAnd
using PyPlot
using Dates
using Statistics
using Random
using Printf
using Compat

datadir = "/data/SeaDataCloud/NorthSea/"
varname = "Salinity"
obsfile1 = joinpath(datadir, "NorthSea_obs.nc")
obsfile2 = joinpath(datadir, "NorthSea_obs_wod.nc")

varname = "sea_water_salinity"

@time obsval1, obslon1, obslat1, obsdepth1, obstime1, obsid1 = DIVAnd.loadobs(Float64,"northsea_obs_01.nc",varname);
@time obsval2, obslon2, obslat2, obsdepth2, obstime2, obsid2 = DIVAnd.loadobs(Float64,"northsea_obs_02.nc",varname);


ndata1 = length(obslon1);
ndata2 = length(obslon2);
@info("Number of data in dataset 1: $(ndata1)")
@info("Number of data in dataset 2: $(ndata2)")

Δlon = [0.001, 0.005, 0.01, 0.05, 0.1, 1.];
Δdepth = [0.001, 0.005, 0.01, 0.05, 0.1, ];

duplicate_percent = Array{Float64}(undef, length(Δlon), length(Δdepth))

for (i, dx) in enumerate(Δlon)
    for (j, dz) in enumerate(Δdepth)
        @time dupl = DIVAnd.Quadtrees.checkduplicates(
            (obslon1,obslat1,obsdepth1,obstime1), obsval1,
            (obslon2,obslat2,obsdepth2,obstime2), obsval2,
            (dx, dx, dz,1/(24.)),0.01);

            index = findall(.!isempty.(dupl));
            ndupl = length(index);
            pcdupl = round(ndupl / (ndata1) * 100; digits=2);
            @info("Number of possible duplicates: $ndupl")
            @info("Percentage of duplicates: $pcdupl%")

            duplicate_percent[i, j] = pcdupl;
    end
end
