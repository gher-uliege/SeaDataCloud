using NCDatasets
using DIVAnd
using PyPlot
using Random
using Printf

datadir = "/data/SeaDataCloud/NorthSea/"
varname = "Temperature"
obsfile = joinpath(datadir, "NorthSea_obs_$(varname).nc")
obsfile_wod = joinpath(datadir, "NorthSea_obs_$(varname)_wod.nc")

if !(isfile(obsfile) && isfile(obsfile_wod))
    @error("File does not exist)")
end

@time obsvalwod, obslonwod, obslatwod, obsdepthwod, obstimewod, obsidwod =
DIVAnd.loadobs(Float64,obsfile_wod,varname);

@time obsval,obslon, obslat, obsdepth, obstime,obsid =
DIVAnd.loadobs(Float64,obsfile,varname);

obslon[obslon.>180.] .-= 360.
#PyPlot.plot(obslonwod, obslatwod, "ko", markersize=0.2)
#PyPlot.plot(obslon, obslat, "bo", markersize=0.2)

@time dupl = DIVAnd.Quadtrees.checkduplicates(
    (obslon,obslat,obsdepth,obstime), obsval,
    (obslonwod,obslatwod, obsdepthwod, obstimewod), obsvalwod,
    (0.01, 0.01, 1.0, 1/(12)), 0.1);

ndata1 = length(obslon);
ndata2 = length(obslonwod);
index = findall(.!isempty.(dupl));
ndupl = length(index);
@info("Number of data in dataset 1 (SDN): $(ndata1)")
@info("Number of data in dataset 2 (WOD): $(ndata2)")

pcdupl = round(ndupl / ndata1 * 100; digits=2);
@info("Number of possible duplicates: $ndupl")
@info("Percentage of duplicates: $pcdupl%")

@info("Creating new datafile")
newpoints = isempty.(dupl);
@info("Number of new points: $(sum(newpoints))")

obslonnew = [obslon; obslonwod[newpoints]];
obslatnew = [obslat; obslatwod[newpoints]];
obsdepthnew = [obsdepth; obsdepthwod[newpoints]];
obstimenew = [obstime; obstimewod[newpoints]];
obsvalnew = [obsval; obsvalwod[newpoints]];
obsidnew = [obsid; obsidwod[newpoints]];

@info("Writing the data and coordinates into an observation file")
DIVAnd.saveobs(joinpath(datadir, "NorthSea_obs_$(varname)_sdn_wod_merged.nc"),
               varname, obsvalnew,
              (obslonnew, obslatnew, obsdepthnew, obstimenew),obsidnew)

"""
Notes:
(0.01, 0.01, 0.5, 1/(24*60)), 0.01) | 62.75 | 252.099566 |
(0.05, 0.05, 0.5, 1/(24*60)), 0.01) | 65.69 | 294.668044 |
(0.05, 0.05, 0.5, 1/(24*60)), 0.0001)| 47.28| 307.658879 |
(0.1, 0.1, 0.5, 1/(24*60)), 0.01)   | 65.73 | 349.933588 |
(0.01, 0.01, 0.1, 1/(24*60)), 0.01) | 50.58 | 261.705550 |
(0.01, 0.01, 0.05, 1/(24*60)), 0.01)| 47.35 | 258.340030 |
(0.01, 0.01, 0.01, 1/(24*60)), 0.02)| 16.98 | 223.809872 |
(0.01, 0.01, 0.01, 1/(24*60)), 0.05)| 17.01 | 231.749957 |
"""
